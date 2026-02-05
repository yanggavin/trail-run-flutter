import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/location_source.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';
import '../database/database_provider.dart';
import '../repositories/activity_repository_impl.dart';

/// Background location tracking state
enum BackgroundTrackingState {
  stopped,
  starting,
  active,
  paused,
  error,
}

/// Manages background location tracking across platforms
class BackgroundLocationManager {
  static const MethodChannel _channel = MethodChannel('com.trailrun.location_service');
  static const String _isolatePortName = 'location_isolate_port';
  
  BackgroundLocationManager({ActivityRepositoryImpl? activityRepository})
      : _activityRepository = activityRepository ??
            ActivityRepositoryImpl(database: DatabaseProvider.getInstance()) {
    _initializeMethodChannel();
    _loadPersistedState();
  }

  // State management
  BackgroundTrackingState _state = BackgroundTrackingState.stopped;
  String? _currentActivityId;
  Timer? _adaptiveSamplingTimer;
  Timer? _persistenceTimer;
  
  // Adaptive sampling configuration
  int _currentIntervalSeconds = 2;
  int _minIntervalSeconds = 1;
  int _maxIntervalSeconds = 5;
  double _lastSpeed = 0.0;
  DateTime? _lastMovementTime;
  
  // Battery optimization
  bool _isLowPowerMode = false;
  double _batteryLevel = 1.0;
  
  // Persistence
  final List<TrackPoint> _pendingTrackPoints = [];
  static const int _maxPendingPoints = 100;
  int _sequenceCounter = 0;
  final math.Random _random = math.Random();
  final ActivityRepositoryImpl _activityRepository;
  
  // Streams
  final StreamController<BackgroundTrackingState> _stateController = 
      StreamController<BackgroundTrackingState>.broadcast();
  final StreamController<TrackPoint> _trackPointController = 
      StreamController<TrackPoint>.broadcast();
  final StreamController<Map<String, dynamic>> _statsController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public API
  
  Stream<BackgroundTrackingState> get stateStream => _stateController.stream;
  Stream<TrackPoint> get trackPointStream => _trackPointController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;
  
  BackgroundTrackingState get currentState => _state;
  bool get isTracking => _state == BackgroundTrackingState.active;
  bool get isPaused => _state == BackgroundTrackingState.paused;

  /// Start background location tracking
  Future<void> startBackgroundTracking({
    required String activityId,
    LocationAccuracy accuracy = LocationAccuracy.balanced,
  }) async {
    if (_state == BackgroundTrackingState.active) return;
    
    if (_currentActivityId != activityId) {
      _sequenceCounter = 0;
    }
    _currentActivityId = activityId;
    _updateState(BackgroundTrackingState.starting);
    
    try {
      if (Platform.isAndroid) {
        await _startAndroidForegroundService();
      } else if (Platform.isIOS) {
        await _startIOSBackgroundTracking();
      }
      
      await _startAdaptiveSampling();
      await _startPersistenceTimer();
      await _persistState();
      
      _updateState(BackgroundTrackingState.active);
    } catch (e) {
      _updateState(BackgroundTrackingState.error);
      rethrow;
    }
  }

  /// Stop background location tracking
  Future<void> stopBackgroundTracking() async {
    _updateState(BackgroundTrackingState.stopped);
    
    _adaptiveSamplingTimer?.cancel();
    _persistenceTimer?.cancel();
    
    if (Platform.isAndroid) {
      await _stopAndroidForegroundService();
    } else if (Platform.isIOS) {
      await _stopIOSBackgroundTracking();
    }
    
    await _flushPendingTrackPoints();
    await _clearPersistedState();
    
    _currentActivityId = null;
    _sequenceCounter = 0;
  }

  /// Pause background location tracking
  Future<void> pauseBackgroundTracking() async {
    if (_state != BackgroundTrackingState.active) return;
    
    _updateState(BackgroundTrackingState.paused);
    
    if (Platform.isAndroid) {
      await _channel.invokeMethod('pauseTracking');
    }
    
    await _persistState();
  }

  /// Resume background location tracking
  Future<void> resumeBackgroundTracking() async {
    if (_state != BackgroundTrackingState.paused) return;
    
    _updateState(BackgroundTrackingState.active);
    
    if (Platform.isAndroid) {
      await _channel.invokeMethod('resumeTracking');
    }
    
    await _persistState();
  }

  /// Configure adaptive sampling parameters
  Future<void> configureAdaptiveSampling({
    int minIntervalSeconds = 1,
    int maxIntervalSeconds = 5,
    bool enableBatteryOptimization = true,
  }) async {
    _minIntervalSeconds = minIntervalSeconds;
    _maxIntervalSeconds = maxIntervalSeconds;
    
    if (enableBatteryOptimization) {
      await _updateBatteryStatus();
    }
  }

  /// Get current tracking statistics
  Map<String, dynamic> getCurrentStats() {
    return {
      'state': _state.toString(),
      'activityId': _currentActivityId,
      'currentInterval': _currentIntervalSeconds,
      'pendingPoints': _pendingTrackPoints.length,
      'batteryLevel': _batteryLevel,
      'isLowPowerMode': _isLowPowerMode,
    };
  }

  /// Recover from app crash or restart
  Future<bool> recoverTrackingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final persistedActivityId = prefs.getString('background_tracking_activity_id');
    final persistedState = prefs.getString('background_tracking_state');
    
    if (persistedActivityId != null && persistedState != null) {
      final state = BackgroundTrackingState.values.firstWhere(
        (s) => s.toString() == persistedState,
        orElse: () => BackgroundTrackingState.stopped,
      );
      
      if (state == BackgroundTrackingState.active || state == BackgroundTrackingState.paused) {
        _currentActivityId = persistedActivityId;
        _updateState(state);
        
        // Restart tracking if it was active
        if (state == BackgroundTrackingState.active) {
          await startBackgroundTracking(activityId: persistedActivityId);
        }
        
        return true;
      }
    }
    
    return false;
  }

  // Private methods

  void _initializeMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onLocationUpdate':
          _handleLocationUpdate(call.arguments);
          break;
        case 'onTrackingStateChanged':
          _handleTrackingStateChanged(call.arguments);
          break;
        case 'onBatteryStatusChanged':
          _handleBatteryStatusChanged(call.arguments);
          break;
      }
    });
  }

  Future<void> _startAndroidForegroundService() async {
    await _channel.invokeMethod('startForegroundService', {
      'activityId': _currentActivityId,
    });
  }

  Future<void> _stopAndroidForegroundService() async {
    await _channel.invokeMethod('stopForegroundService');
  }

  Future<void> _startIOSBackgroundTracking() async {
    await _channel.invokeMethod('startBackgroundLocationUpdates', {
      'activityId': _currentActivityId,
    });
  }

  Future<void> _stopIOSBackgroundTracking() async {
    await _channel.invokeMethod('stopBackgroundLocationUpdates');
  }

  Future<void> _startAdaptiveSampling() async {
    _adaptiveSamplingTimer = Timer.periodic(
      Duration(seconds: 1),
      (_) => _updateAdaptiveSampling(),
    );
  }

  Future<void> _updateAdaptiveSampling() async {
    await _updateBatteryStatus();
    
    // Adjust interval based on movement and battery
    int newInterval = _calculateOptimalInterval();
    
    if (newInterval != _currentIntervalSeconds) {
      _currentIntervalSeconds = newInterval;
      
      await _channel.invokeMethod('updateSamplingInterval', {
        'intervalSeconds': _currentIntervalSeconds,
      });
    }
  }

  int _calculateOptimalInterval() {
    int interval = _minIntervalSeconds;
    
    // Increase interval if moving slowly or stationary
    if (_lastSpeed < 1.0) { // Less than 1 m/s (walking pace)
      interval = (_minIntervalSeconds + 1).clamp(_minIntervalSeconds, _maxIntervalSeconds);
    }
    
    // Increase interval in low power mode
    if (_isLowPowerMode || _batteryLevel < 0.2) {
      interval = _maxIntervalSeconds;
    }
    
    // Decrease interval if moving fast
    if (_lastSpeed > 3.0) { // Faster than 3 m/s (running pace)
      interval = _minIntervalSeconds;
    }
    
    return interval;
  }

  Future<void> _updateBatteryStatus() async {
    try {
      final batteryInfo = await _channel.invokeMethod('getBatteryInfo');
      _batteryLevel = (batteryInfo['level'] as num).toDouble();
      _isLowPowerMode = batteryInfo['isLowPowerMode'] as bool? ?? false;
    } catch (e) {
      // Fallback values if battery info is not available
      _batteryLevel = 1.0;
      _isLowPowerMode = false;
    }
  }

  Future<void> _startPersistenceTimer() async {
    _persistenceTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _persistPendingTrackPoints(),
    );
  }

  void _handleLocationUpdate(Map<String, dynamic> data) {
    if (_state != BackgroundTrackingState.active) return;
    
    final int incomingSequence = (data['sequence'] as int?) ?? _sequenceCounter;
    if (incomingSequence >= _sequenceCounter) {
      _sequenceCounter = incomingSequence + 1;
    }

    final trackPoint = TrackPoint(
      id: _generateTrackPointId(),
      activityId: _currentActivityId!,
      timestamp: Timestamp(DateTime.fromMillisecondsSinceEpoch(data['timestamp'])),
      coordinates: Coordinates(
        latitude: data['latitude'],
        longitude: data['longitude'],
        elevation: data['elevation'],
      ),
      accuracy: data['accuracy'],
      source: LocationSource.gps,
      sequence: incomingSequence,
    );
    
    _pendingTrackPoints.add(trackPoint);
    _trackPointController.add(trackPoint);
    
    // Update speed for adaptive sampling
    if (data['speed'] != null) {
      _lastSpeed = data['speed'];
      _lastMovementTime = DateTime.now();
    }
    
    // Flush if we have too many pending points
    if (_pendingTrackPoints.length >= _maxPendingPoints) {
      _persistPendingTrackPoints();
    }
    
    // Emit stats update
    _statsController.add(getCurrentStats());
  }

  void _handleTrackingStateChanged(Map<String, dynamic> data) {
    final stateString = data['state'] as String;
    final newState = BackgroundTrackingState.values.firstWhere(
      (s) => s.toString().split('.').last == stateString,
      orElse: () => BackgroundTrackingState.error,
    );
    
    _updateState(newState);
  }

  void _handleBatteryStatusChanged(Map<String, dynamic> data) {
    _batteryLevel = (data['level'] as num).toDouble();
    _isLowPowerMode = data['isLowPowerMode'] as bool? ?? false;
  }

  Future<void> _persistPendingTrackPoints() async {
    if (_pendingTrackPoints.isEmpty) return;
    
    final pointsToSave = List<TrackPoint>.from(_pendingTrackPoints);
    _pendingTrackPoints.clear();
    
    if (_currentActivityId == null || _currentActivityId!.isEmpty) {
      return;
    }

    try {
      await _activityRepository.addTrackPoints(_currentActivityId!, pointsToSave);
      await _persistState();
    } catch (_) {
      // If persistence fails, re-queue points to avoid data loss
      _pendingTrackPoints.insertAll(0, pointsToSave);
    }
  }

  Future<void> _flushPendingTrackPoints() async {
    await _persistPendingTrackPoints();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentActivityId != null && _currentActivityId!.isNotEmpty) {
      await prefs.setString('background_tracking_activity_id', _currentActivityId!);
    } else {
      await prefs.remove('background_tracking_activity_id');
    }
    await prefs.setString('background_tracking_state', _state.toString());
    await prefs.setInt('background_tracking_interval', _currentIntervalSeconds);
    await prefs.setInt('background_tracking_sequence', _sequenceCounter);
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIntervalSeconds = prefs.getInt('background_tracking_interval') ?? 2;
    _sequenceCounter = prefs.getInt('background_tracking_sequence') ?? 0;
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('background_tracking_activity_id');
    await prefs.remove('background_tracking_state');
    await prefs.remove('background_tracking_interval');
    await prefs.remove('background_tracking_sequence');
  }

  void _updateState(BackgroundTrackingState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  String _generateTrackPointId() {
    return 'tp_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  void dispose() {
    _adaptiveSamplingTimer?.cancel();
    _persistenceTimer?.cancel();
    _stateController.close();
    _trackPointController.close();
    _statsController.close();
  }
}
