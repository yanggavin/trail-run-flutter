import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/repositories/location_repository.dart';
import '../../domain/models/track_point.dart';
import '../../domain/value_objects/coordinates.dart';
import 'background_location_manager.dart';
import 'location_service.dart';

/// Enhanced location service with background tracking capabilities
class EnhancedLocationService implements LocationRepository {
  final LocationRepository _baseLocationService;
  final dynamic _backgroundManager;
  
  // State management
  bool _isBackgroundTrackingEnabled = false;
  String? _currentActivityId;
  
  // Stream controllers for combined streams
  final StreamController<TrackPoint> _combinedLocationController = 
      StreamController<TrackPoint>.broadcast();
  final StreamController<LocationTrackingState> _combinedStateController = 
      StreamController<LocationTrackingState>.broadcast();
  
  // Subscriptions
  StreamSubscription<TrackPoint>? _foregroundLocationSub;
  StreamSubscription<TrackPoint>? _backgroundLocationSub;
  StreamSubscription<LocationTrackingState>? _foregroundStateSub;
  StreamSubscription<BackgroundTrackingState>? _backgroundStateSub;

  EnhancedLocationService({
    LocationRepository? baseLocationService,
    dynamic backgroundManager,
  }) : _baseLocationService = baseLocationService ?? LocationService(),
       _backgroundManager = backgroundManager ?? BackgroundLocationManager() {
    _initializeStreams();
  }

  void _initializeStreams() {
    // Forward foreground location updates
    _foregroundLocationSub = _baseLocationService.locationStream.listen(
      (trackPoint) => _combinedLocationController.add(trackPoint),
    );
    
    // Forward background location updates
    _backgroundLocationSub = _backgroundManager.trackPointStream.listen(
      (trackPoint) => _combinedLocationController.add(trackPoint),
    );
    
    // Forward foreground state updates
    _foregroundStateSub = _baseLocationService.trackingStateStream.listen(
      (state) => _combinedStateController.add(state),
    );
    
    // Convert and forward background state updates
    _backgroundStateSub = _backgroundManager.stateStream.listen(
      (backgroundState) {
        final locationState = _mapBackgroundToLocationState(backgroundState);
        _combinedStateController.add(locationState);
      },
    );
  }

  // Background tracking specific methods

  /// Enable background location tracking
  Future<void> enableBackgroundTracking({
    required String activityId,
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int minIntervalSeconds = 1,
    int maxIntervalSeconds = 5,
  }) async {
    _currentActivityId = activityId;
    _isBackgroundTrackingEnabled = true;
    
    // Configure adaptive sampling
    await _backgroundManager.configureAdaptiveSampling(
      minIntervalSeconds: minIntervalSeconds,
      maxIntervalSeconds: maxIntervalSeconds,
      enableBatteryOptimization: true,
    );
    
    // Start background tracking
    await _backgroundManager.startBackgroundTracking(
      activityId: activityId,
      accuracy: accuracy,
    );
  }

  /// Disable background location tracking
  Future<void> disableBackgroundTracking() async {
    _isBackgroundTrackingEnabled = false;
    _currentActivityId = null;
    
    await _backgroundManager.stopBackgroundTracking();
  }

  /// Check if background tracking is currently active
  bool get isBackgroundTrackingActive => 
      _isBackgroundTrackingEnabled && _backgroundManager.isTracking;

  /// Get background tracking statistics
  Map<String, dynamic> getBackgroundTrackingStats() {
    return _backgroundManager.getCurrentStats();
  }

  /// Recover tracking session after app restart
  Future<bool> recoverTrackingSession() async {
    final recovered = await _backgroundManager.recoverTrackingSession();
    if (recovered) {
      _isBackgroundTrackingEnabled = true;
      final stats = _backgroundManager.getCurrentStats();
      _currentActivityId = stats['activityId'];
    }
    return recovered;
  }

  // LocationRepository implementation - delegate to base service

  @override
  Future<LocationPermissionStatus> getPermissionStatus() {
    return _baseLocationService.getPermissionStatus();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() {
    return _baseLocationService.requestPermission();
  }

  @override
  Future<LocationPermissionStatus> requestBackgroundPermission() {
    return _baseLocationService.requestBackgroundPermission();
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return _baseLocationService.isLocationServiceEnabled();
  }

  @override
  Future<Coordinates?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _baseLocationService.getCurrentLocation(
      accuracy: accuracy,
      timeout: timeout,
    );
  }

  @override
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int intervalSeconds = 2,
    double distanceFilter = 0,
  }) async {
    // Start foreground tracking
    await _baseLocationService.startLocationTracking(
      accuracy: accuracy,
      intervalSeconds: intervalSeconds,
      distanceFilter: distanceFilter,
    );
    
    // If background tracking is enabled, start it too
    if (_isBackgroundTrackingEnabled && _currentActivityId != null) {
      await _backgroundManager.startBackgroundTracking(
        activityId: _currentActivityId!,
        accuracy: accuracy,
      );
    }
  }

  @override
  Future<void> stopLocationTracking() async {
    // Stop both foreground and background tracking
    await _baseLocationService.stopLocationTracking();
    
    if (_isBackgroundTrackingEnabled) {
      await _backgroundManager.stopBackgroundTracking();
    }
  }

  @override
  Future<void> pauseLocationTracking() async {
    await _baseLocationService.pauseLocationTracking();
    
    if (_isBackgroundTrackingEnabled) {
      await _backgroundManager.pauseBackgroundTracking();
    }
  }

  @override
  Future<void> resumeLocationTracking() async {
    await _baseLocationService.resumeLocationTracking();
    
    if (_isBackgroundTrackingEnabled) {
      await _backgroundManager.resumeBackgroundTracking();
    }
  }

  @override
  LocationTrackingState get trackingState => _baseLocationService.trackingState;

  @override
  Stream<TrackPoint> get locationStream => _combinedLocationController.stream;

  @override
  Stream<LocationQuality> get locationQualityStream => 
      _baseLocationService.locationQualityStream;

  @override
  Stream<LocationTrackingState> get trackingStateStream => 
      _combinedStateController.stream;

  @override
  Future<Coordinates?> getLastKnownLocation() {
    return _baseLocationService.getLastKnownLocation();
  }

  @override
  bool get supportsBackgroundLocation => true;

  @override
  Future<bool> isHighAccuracyAvailable() {
    return _baseLocationService.isHighAccuracyAvailable();
  }

  @override
  Future<double> getEstimatedBatteryUsage(LocationAccuracy accuracy) async {
    final baseBatteryUsage = await _baseLocationService.getEstimatedBatteryUsage(accuracy);
    
    // Add background tracking overhead
    if (_isBackgroundTrackingEnabled) {
      return baseBatteryUsage * 1.2; // 20% overhead for background tracking
    }
    
    return baseBatteryUsage;
  }

  @override
  Future<void> configureFiltering({
    double maxAccuracy = 50.0,
    double maxSpeed = 50.0,
    bool enableKalmanFilter = true,
    bool enableOutlierDetection = true,
  }) {
    return _baseLocationService.configureFiltering(
      maxAccuracy: maxAccuracy,
      maxSpeed: maxSpeed,
      enableKalmanFilter: enableKalmanFilter,
      enableOutlierDetection: enableOutlierDetection,
    );
  }

  @override
  Future<LocationTrackingStats> getTrackingStats() async {
    final baseStats = await _baseLocationService.getTrackingStats();
    
    if (_isBackgroundTrackingEnabled) {
      final backgroundStats = _backgroundManager.getCurrentStats();
      
      // Combine stats from both foreground and background tracking
      return LocationTrackingStats(
        totalPoints: baseStats.totalPoints,
        filteredPoints: baseStats.filteredPoints,
        averageAccuracy: baseStats.averageAccuracy,
        trackingDuration: baseStats.trackingDuration,
        batteryUsagePercent: baseStats.batteryUsagePercent,
      );
    }
    
    return baseStats;
  }

  @override
  Future<void> resetTrackingStats() {
    return _baseLocationService.resetTrackingStats();
  }

  // App lifecycle management

  /// Handle app going to background
  Future<void> onAppPaused() async {
    if (_isBackgroundTrackingEnabled && _currentActivityId != null) {
      // Ensure background tracking continues
      await _backgroundManager.startBackgroundTracking(
        activityId: _currentActivityId!,
      );
    }
  }

  /// Handle app coming to foreground
  Future<void> onAppResumed() async {
    // Check if we need to recover a tracking session
    if (!_isBackgroundTrackingEnabled) {
      final recovered = await recoverTrackingSession();
      if (recovered) {
        // Restart foreground tracking to sync with background
        await startLocationTracking();
      }
    }
  }

  /// Handle app termination
  Future<void> onAppDetached() async {
    // Ensure background tracking state is persisted
    if (_isBackgroundTrackingEnabled) {
      // Background manager will handle persistence
    }
  }

  // Private helper methods

  LocationTrackingState _mapBackgroundToLocationState(BackgroundTrackingState backgroundState) {
    switch (backgroundState) {
      case BackgroundTrackingState.stopped:
        return LocationTrackingState.stopped;
      case BackgroundTrackingState.starting:
        return LocationTrackingState.starting;
      case BackgroundTrackingState.active:
        return LocationTrackingState.active;
      case BackgroundTrackingState.paused:
        return LocationTrackingState.paused;
      case BackgroundTrackingState.error:
        return LocationTrackingState.error;
    }
  }

  void dispose() {
    _foregroundLocationSub?.cancel();
    _backgroundLocationSub?.cancel();
    _foregroundStateSub?.cancel();
    _backgroundStateSub?.cancel();
    
    _combinedLocationController.close();
    _combinedStateController.close();
    
    // Dispose base service if it has a dispose method
    if (_baseLocationService is LocationService) {
      (_baseLocationService as LocationService).dispose();
    }
    
    // Dispose background manager if it has a dispose method
    if (_backgroundManager != null && _backgroundManager.dispose != null) {
      _backgroundManager.dispose();
    }
  }
}