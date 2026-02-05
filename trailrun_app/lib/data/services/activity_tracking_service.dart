import 'dart:async';
import 'dart:math' as math;

import '../../domain/models/activity.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/enums/privacy_level.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/value_objects/measurement_units.dart';
import '../../domain/value_objects/timestamp.dart';
import '../../domain/value_objects/coordinates.dart';
import 'location_service.dart';

/// Activity tracking state
enum ActivityTrackingState {
  stopped,
  starting,
  active,
  paused,
  autoPaused,
  stopping,
  error,
}

/// Auto-pause configuration
class AutoPauseConfig {
  const AutoPauseConfig({
    this.enabled = true,
    this.speedThreshold = 0.5, // m/s (about 1.8 km/h)
    this.timeThreshold = const Duration(seconds: 10),
    this.resumeSpeedThreshold = 1.0, // m/s (about 3.6 km/h)
  });

  final bool enabled;
  final double speedThreshold; // Speed below which to trigger auto-pause (m/s)
  final Duration timeThreshold; // Time to wait before auto-pausing
  final double resumeSpeedThreshold; // Speed above which to resume (m/s)
}

/// Real-time activity statistics
class ActivityStatistics {
  const ActivityStatistics({
    required this.distance,
    required this.duration,
    required this.movingDuration,
    required this.currentPace,
    required this.averagePace,
    required this.elevationGain,
    required this.elevationLoss,
    required this.currentSpeed,
    required this.maxSpeed,
    required this.trackPointCount,
    required this.photoCount,
  });

  final Distance distance;
  final Duration duration; // Total elapsed time
  final Duration movingDuration; // Time spent moving (excluding pauses)
  final Pace? currentPace;
  final Pace? averagePace;
  final Elevation elevationGain;
  final Elevation elevationLoss;
  final Speed currentSpeed;
  final Speed maxSpeed;
  final int trackPointCount;
  final int photoCount;
}

/// Activity tracking service that manages the complete lifecycle
class ActivityTrackingService {
  ActivityTrackingService({
    required ActivityRepository activityRepository,
    required LocationRepository locationRepository,
    AutoPauseConfig? autoPauseConfig,
  }) : _activityRepository = activityRepository,
       _locationRepository = locationRepository,
       _autoPauseConfig = autoPauseConfig ?? const AutoPauseConfig();

  final ActivityRepository _activityRepository;
  final LocationRepository _locationRepository;
  AutoPauseConfig _autoPauseConfig;

  // Stream controllers
  final StreamController<ActivityTrackingState> _stateController = 
      StreamController<ActivityTrackingState>.broadcast();
  final StreamController<ActivityStatistics> _statisticsController = 
      StreamController<ActivityStatistics>.broadcast();
  final StreamController<Activity> _activityController = 
      StreamController<Activity>.broadcast();

  // State variables
  ActivityTrackingState _state = ActivityTrackingState.stopped;
  Activity? _currentActivity;
  StreamSubscription<TrackPoint>? _locationSubscription;
  StreamSubscription<LocationTrackingState>? _locationStateSubscription;
  
  // Statistics tracking
  final List<TrackPoint> _trackPoints = [];
  int _photoCount = 0;
  DateTime? _startTime;
  DateTime? _lastMoveTime;
  DateTime? _pauseStartTime;
  Duration _totalPausedDuration = Duration.zero;
  
  // Auto-pause state
  Timer? _autoPauseTimer;
  bool _isAutoPaused = false;
  final List<double> _recentSpeeds = [];
  
  // Real-time statistics
  Distance _currentDistance = Distance.meters(0);
  Elevation _currentElevationGain = Elevation.meters(0);
  Elevation _currentElevationLoss = Elevation.meters(0);
  Speed _currentSpeed = Speed.metersPerSecond(0);
  Speed _maxSpeed = Speed.metersPerSecond(0);
  TrackPoint? _lastTrackPoint;

  // Getters
  ActivityTrackingState get state => _state;
  Activity? get currentActivity => _currentActivity;
  bool get isTracking => _state == ActivityTrackingState.active || _state == ActivityTrackingState.autoPaused;
  bool get isAutoPaused => _isAutoPaused;
  bool get isAutoPauseEnabled => _autoPauseConfig.enabled;

  // Streams
  Stream<ActivityTrackingState> get stateStream => _stateController.stream;
  Stream<ActivityStatistics> get statisticsStream => _statisticsController.stream;
  Stream<Activity> get activityStream => _activityController.stream;

  /// Start a new activity
  Future<Activity> startActivity({
    String? title,
    PrivacyLevel privacy = PrivacyLevel.private,
  }) async {
    if (_state != ActivityTrackingState.stopped) {
      throw StateError('Cannot start activity while in state: $_state');
    }

    _updateState(ActivityTrackingState.starting);

    try {
      // Create new activity
      final activityId = _generateActivityId();
      final now = Timestamp(DateTime.now());
      
      _currentActivity = Activity(
        id: activityId,
        startTime: now,
        title: title ?? 'Trail Run ${_formatDateTime(now.dateTime)}',
        privacy: privacy,
        syncState: SyncState.local,
      );

      // Save to database
      await _activityRepository.createActivity(_currentActivity!);

      // Initialize tracking state
      _initializeTrackingState();

      // Start location tracking
      if (_locationRepository is LocationService) {
        (_locationRepository as LocationService).setCurrentActivityId(activityId);
      }

      await _locationRepository.startLocationTracking(
        accuracy: LocationAccuracy.high,
        intervalSeconds: 2,
      );

      // Subscribe to location updates
      _locationSubscription = _locationRepository.locationStream.listen(
        _handleLocationUpdate,
        onError: _handleLocationError,
      );

      // Subscribe to location state changes
      _locationStateSubscription = _locationRepository.trackingStateStream.listen(
        _handleLocationStateChange,
      );

      _updateState(ActivityTrackingState.active);
      _activityController.add(_currentActivity!);

      return _currentActivity!;
    } catch (e) {
      _updateState(ActivityTrackingState.error);
      rethrow;
    }
  }

  /// Pause the current activity
  Future<void> pauseActivity() async {
    if (_state != ActivityTrackingState.active && _state != ActivityTrackingState.autoPaused) {
      return;
    }

    _pauseStartTime = DateTime.now();
    _isAutoPaused = false;
    _autoPauseTimer?.cancel();
    
    await _locationRepository.pauseLocationTracking();
    _updateState(ActivityTrackingState.paused);
  }

  /// Resume the current activity
  Future<void> resumeActivity() async {
    if (_state != ActivityTrackingState.paused && _state != ActivityTrackingState.autoPaused) {
      return;
    }

    // Add paused duration to total
    if (_pauseStartTime != null) {
      _totalPausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }

    _isAutoPaused = false;
    await _locationRepository.resumeLocationTracking();
    _updateState(ActivityTrackingState.active);
  }

  /// Stop the current activity
  Future<Activity> stopActivity() async {
    if (_currentActivity == null || _state == ActivityTrackingState.stopped) {
      throw StateError('No active activity to stop');
    }

    _updateState(ActivityTrackingState.stopping);

    try {
      // Stop location tracking
      await _locationRepository.stopLocationTracking();
      _locationSubscription?.cancel();
      _locationStateSubscription?.cancel();

      // Calculate final statistics
      final finalStats = _calculateCurrentStatistics();
      
      // Update activity with final data
      final endTime = Timestamp(DateTime.now());
      final updatedActivity = _currentActivity!.copyWith(
        endTime: endTime,
        distance: finalStats.distance,
        elevationGain: finalStats.elevationGain,
        elevationLoss: finalStats.elevationLoss,
        averagePace: finalStats.averagePace,
        trackPoints: List.from(_trackPoints),
        syncState: SyncState.pending,
      );

      // Save final activity
      await _activityRepository.updateActivity(updatedActivity);

      // Clean up state
      _currentActivity = updatedActivity;
      _updateState(ActivityTrackingState.stopped);
      _activityController.add(_currentActivity!);

      return _currentActivity!;
    } catch (e) {
      _updateState(ActivityTrackingState.error);
      rethrow;
    } finally {
      _cleanupTrackingState();
    }
  }

  /// Get current real-time statistics
  ActivityStatistics getCurrentStatistics() {
    return _calculateCurrentStatistics();
  }

  /// Configure auto-pause settings
  void configureAutoPause(AutoPauseConfig config) {
    _autoPauseConfig = config;
    // If disabled, ensure we resume if currently auto-paused
    if (!config.enabled && _state == ActivityTrackingState.autoPaused) {
      _triggerAutoResume();
    }
  }

  /// Toggle auto-pause enabled state
  bool toggleAutoPause() {
    final newEnabled = !_autoPauseConfig.enabled;
    configureAutoPause(AutoPauseConfig(
      enabled: newEnabled,
      speedThreshold: _autoPauseConfig.speedThreshold,
      timeThreshold: _autoPauseConfig.timeThreshold,
      resumeSpeedThreshold: _autoPauseConfig.resumeSpeedThreshold,
    ));
    return newEnabled;
  }

  /// Handle crash recovery - restore in-progress activity
  Future<Activity?> recoverInProgressActivity() async {
    try {
      final activeActivity = await _activityRepository.getActiveActivity();
      if (activeActivity == null) return null;

      // Restore tracking state
      _currentActivity = activeActivity;
      _initializeTrackingState();
      
      // Load existing track points
      _trackPoints.clear();
      _trackPoints.addAll(activeActivity.trackPoints);
      
      // Recalculate statistics from existing points
      if (_trackPoints.isNotEmpty) {
        _recalculateStatisticsFromTrackPoints();
      }

      _updateState(ActivityTrackingState.paused); // Start in paused state for safety
      _activityController.add(_currentActivity!);

      return _currentActivity;
    } catch (e) {
      return null;
    }
  }

  // Private methods

  void _initializeTrackingState() {
    _trackPoints.clear();
    _photoCount = 0;
    _startTime = DateTime.now();
    _lastMoveTime = _startTime;
    _pauseStartTime = null;
    _totalPausedDuration = Duration.zero;
    _isAutoPaused = false;
    _autoPauseTimer?.cancel();
    _recentSpeeds.clear();
    
    // Reset statistics
    _currentDistance = Distance.meters(0);
    _currentElevationGain = Elevation.meters(0);
    _currentElevationLoss = Elevation.meters(0);
    _currentSpeed = Speed.metersPerSecond(0);
    _maxSpeed = Speed.metersPerSecond(0);
    _lastTrackPoint = null;
  }

  void _cleanupTrackingState() {
    _locationSubscription?.cancel();
    _locationStateSubscription?.cancel();
    _autoPauseTimer?.cancel();
    _locationSubscription = null;
    _locationStateSubscription = null;
    _autoPauseTimer = null;
  }

  void _handleLocationUpdate(TrackPoint trackPoint) {
    if (_state != ActivityTrackingState.active && _state != ActivityTrackingState.autoPaused) {
      return;
    }

    // Add track point to activity
    final pointWithId = trackPoint.copyWith(id: _generateTrackPointId());
    _trackPoints.add(pointWithId);

    // Save to database asynchronously
    _activityRepository.addTrackPoint(_currentActivity!.id, pointWithId);

    // Update real-time statistics
    _updateStatisticsFromNewPoint(pointWithId);

    // Handle auto-pause logic
    _handleAutoPauseLogic(pointWithId);

    // Emit updated statistics
    final stats = _calculateCurrentStatistics();
    _statisticsController.add(stats);
  }

  /// Notify tracking service that a photo was captured during the activity
  void notifyPhotoCaptured() {
    _photoCount += 1;
    _statisticsController.add(_calculateCurrentStatistics());
  }

  void _handleLocationError(dynamic error) {
    _updateState(ActivityTrackingState.error);
  }

  void _handleLocationStateChange(LocationTrackingState locationState) {
    // Handle location service state changes
    switch (locationState) {
      case LocationTrackingState.error:
        _updateState(ActivityTrackingState.error);
        break;
      case LocationTrackingState.stopped:
        if (_state == ActivityTrackingState.active || _state == ActivityTrackingState.paused) {
          // Location service stopped unexpectedly
          _updateState(ActivityTrackingState.error);
        }
        break;
      default:
        // Other states are handled by our own state management
        break;
    }
  }

  void _updateStatisticsFromNewPoint(TrackPoint newPoint) {
    if (_lastTrackPoint == null) {
      _lastTrackPoint = newPoint;
      return;
    }

    final lastPoint = _lastTrackPoint!;
    
    // Calculate distance
    final distance = _calculateDistance(
      lastPoint.coordinates.latitude,
      lastPoint.coordinates.longitude,
      newPoint.coordinates.latitude,
      newPoint.coordinates.longitude,
    );
    _currentDistance = Distance.meters(_currentDistance.meters + distance);

    // Calculate elevation changes
    if (lastPoint.coordinates.elevation != null && newPoint.coordinates.elevation != null) {
      final elevationDiff = newPoint.coordinates.elevation! - lastPoint.coordinates.elevation!;
      if (elevationDiff > 0) {
        _currentElevationGain = Elevation.meters(_currentElevationGain.meters + elevationDiff);
      } else {
        _currentElevationLoss = Elevation.meters(_currentElevationLoss.meters + elevationDiff.abs());
      }
    }

    // Calculate current speed
    final timeDiff = newPoint.timestamp.difference(lastPoint.timestamp);
    if (timeDiff.inSeconds > 0) {
      final speed = distance / timeDiff.inSeconds;
      _currentSpeed = Speed.metersPerSecond(speed);
      
      if (speed > _maxSpeed.metersPerSecond) {
        _maxSpeed = Speed.metersPerSecond(speed);
      }
    }

    _lastTrackPoint = newPoint;
  }

  void _handleAutoPauseLogic(TrackPoint trackPoint) {
    if (!_autoPauseConfig.enabled) return;

    final speed = _currentSpeed.metersPerSecond;
    
    // Add to recent speeds for smoothing
    _recentSpeeds.add(speed);
    if (_recentSpeeds.length > 5) {
      _recentSpeeds.removeAt(0);
    }

    // Calculate average recent speed
    final avgRecentSpeed = _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;

    if (_state == ActivityTrackingState.active) {
      // Check if we should auto-pause
      if (avgRecentSpeed < _autoPauseConfig.speedThreshold) {
        _autoPauseTimer ??= Timer(_autoPauseConfig.timeThreshold, () {
          if (_state == ActivityTrackingState.active) {
            _triggerAutoPause();
          }
        });
      } else {
        // Cancel auto-pause timer if speed picks up
        _autoPauseTimer?.cancel();
        _autoPauseTimer = null;
        _lastMoveTime = DateTime.now();
      }
    } else if (_state == ActivityTrackingState.autoPaused) {
      // Check if we should auto-resume
      if (avgRecentSpeed > _autoPauseConfig.resumeSpeedThreshold) {
        _triggerAutoResume();
      }
    }
  }

  void _triggerAutoPause() {
    if (_state != ActivityTrackingState.active) return;

    _pauseStartTime = DateTime.now();
    _isAutoPaused = true;
    _autoPauseTimer = null;
    _updateState(ActivityTrackingState.autoPaused);
  }

  void _triggerAutoResume() {
    if (_state != ActivityTrackingState.autoPaused) return;

    // Add paused duration to total
    if (_pauseStartTime != null) {
      _totalPausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }

    _isAutoPaused = false;
    _lastMoveTime = DateTime.now();
    _updateState(ActivityTrackingState.active);
  }

  ActivityStatistics _calculateCurrentStatistics() {
    final now = DateTime.now();
    final totalDuration = _startTime != null ? now.difference(_startTime!) : Duration.zero;
    final movingDuration = totalDuration - _totalPausedDuration;

    // Calculate current pace
    Pace? currentPace;
    if (_currentSpeed.metersPerSecond > 0) {
      final paceSecondsPerKm = 1000 / _currentSpeed.metersPerSecond;
      currentPace = Pace.secondsPerKilometer(paceSecondsPerKm);
    }

    // Calculate average pace
    Pace? averagePace;
    if (_currentDistance.meters > 0 && movingDuration.inSeconds > 0) {
      final distanceKm = _currentDistance.kilometers;
      final paceSecondsPerKm = movingDuration.inSeconds / distanceKm;
      averagePace = Pace.secondsPerKilometer(paceSecondsPerKm);
    }

    return ActivityStatistics(
      distance: _currentDistance,
      duration: totalDuration,
      movingDuration: movingDuration,
      currentPace: currentPace,
      averagePace: averagePace,
      elevationGain: _currentElevationGain,
      elevationLoss: _currentElevationLoss,
      currentSpeed: _currentSpeed,
      maxSpeed: _maxSpeed,
      trackPointCount: _trackPoints.length,
      photoCount: _photoCount,
    );
  }

  void _recalculateStatisticsFromTrackPoints() {
    if (_trackPoints.isEmpty) return;

    _currentDistance = Distance.meters(0);
    _currentElevationGain = Elevation.meters(0);
    _currentElevationLoss = Elevation.meters(0);
    _maxSpeed = Speed.metersPerSecond(0);

    final sortedPoints = List<TrackPoint>.from(_trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    for (int i = 1; i < sortedPoints.length; i++) {
      final prev = sortedPoints[i - 1];
      final curr = sortedPoints[i];

      // Distance
      final distance = _calculateDistance(
        prev.coordinates.latitude,
        prev.coordinates.longitude,
        curr.coordinates.latitude,
        curr.coordinates.longitude,
      );
      _currentDistance = Distance.meters(_currentDistance.meters + distance);

      // Elevation
      if (prev.coordinates.elevation != null && curr.coordinates.elevation != null) {
        final elevationDiff = curr.coordinates.elevation! - prev.coordinates.elevation!;
        if (elevationDiff > 0) {
          _currentElevationGain = Elevation.meters(_currentElevationGain.meters + elevationDiff);
        } else {
          _currentElevationLoss = Elevation.meters(_currentElevationLoss.meters + elevationDiff.abs());
        }
      }

      // Speed
      final timeDiff = curr.timestamp.difference(prev.timestamp);
      if (timeDiff.inSeconds > 0) {
        final speed = distance / timeDiff.inSeconds;
        if (speed > _maxSpeed.metersPerSecond) {
          _maxSpeed = Speed.metersPerSecond(speed);
        }
      }
    }

    _lastTrackPoint = sortedPoints.last;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _updateState(ActivityTrackingState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  String _generateActivityId() {
    return 'activity_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  String _generateTrackPointId() {
    return 'tp_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationStateSubscription?.cancel();
    _autoPauseTimer?.cancel();
    _stateController.close();
    _statisticsController.close();
    _activityController.close();
  }
}
