import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geolocator/geolocator.dart' show Position, LocationSettings;
import 'package:permission_handler/permission_handler.dart';

import '../../domain/enums/location_source.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';
import 'gps_signal_processor.dart';

/// Location error types
enum LocationErrorType {
  permissionDenied,
  serviceDisabled,
  timeout,
  accuracyTooLow,
  unknown,
}

/// Location service exception
class LocationServiceException implements Exception {
  const LocationServiceException(this.type, this.message);
  
  final LocationErrorType type;
  final String message;
  
  @override
  String toString() => 'LocationServiceException: $message';
}



/// Core location service implementation
class LocationService implements LocationRepository {
  LocationService({
    GpsProcessingConfig? processingConfig,
  }) {
    _signalProcessor = GpsSignalProcessor(config: processingConfig);
    _initializeService();
  }

  // Stream controllers
  final StreamController<TrackPoint> _locationController = StreamController<TrackPoint>.broadcast();
  final StreamController<LocationQuality> _qualityController = StreamController<LocationQuality>.broadcast();
  final StreamController<LocationTrackingState> _stateController = StreamController<LocationTrackingState>.broadcast();

  // State variables
  LocationTrackingState _trackingState = LocationTrackingState.stopped;
  StreamSubscription<Position>? _positionSubscription;
  LocationSettings? _currentSettings;
  String _currentActivityId = '';
  int _sequenceCounter = 0;
  
  // GPS signal processor
  late GpsSignalProcessor _signalProcessor;
  
  // Gap detection for interpolation
  TrackPoint? _lastEmittedPoint;
  Timer? _gapDetectionTimer;
  
  // Statistics
  DateTime? _trackingStartTime;

  void _initializeService() {
    _stateController.add(_trackingState);
  }

  @override
  Future<LocationPermissionStatus> getPermissionStatus() async {
    final permission = await geolocator.Geolocator.checkPermission();
    return _mapGeolocatorPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await geolocator.Geolocator.requestPermission();
    return _mapGeolocatorPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    // First ensure we have basic location permission
    final basicPermission = await getPermissionStatus();
    if (basicPermission == LocationPermissionStatus.denied ||
        basicPermission == LocationPermissionStatus.deniedForever) {
      return basicPermission;
    }

    // Request background location permission
    final backgroundStatus = await Permission.locationAlways.request();
    
    switch (backgroundStatus) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.always;
      case PermissionStatus.denied:
        return LocationPermissionStatus.whileInUse;
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.deniedForever;
      default:
        return LocationPermissionStatus.whileInUse;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await geolocator.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<Coordinates?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: _mapLocationAccuracy(accuracy),
        timeLimit: timeout,
      );
      
      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int intervalSeconds = 2,
    double distanceFilter = 0,
  }) async {
    if (_trackingState == LocationTrackingState.active) {
      return;
    }

    // Check permissions
    final permissionStatus = await getPermissionStatus();
    if (permissionStatus == LocationPermissionStatus.denied ||
        permissionStatus == LocationPermissionStatus.deniedForever) {
      _updateState(LocationTrackingState.error);
      throw const LocationServiceException(
        LocationErrorType.permissionDenied,
        'Location permission is required for tracking',
      );
    }

    // Check if location services are enabled
    if (!await isLocationServiceEnabled()) {
      _updateState(LocationTrackingState.error);
      throw const LocationServiceException(
        LocationErrorType.serviceDisabled,
        'Location services are disabled',
      );
    }

    _updateState(LocationTrackingState.starting);

    try {
      _currentSettings = LocationSettings(
        accuracy: _mapLocationAccuracy(accuracy),
        distanceFilter: distanceFilter.round(),
        timeLimit: Duration(seconds: intervalSeconds * 2), // Allow some buffer
      );

      _positionSubscription = geolocator.Geolocator.getPositionStream(
        locationSettings: _currentSettings!,
      ).listen(
        _handleLocationUpdate,
        onError: _handleLocationError,
      );

      _trackingStartTime = DateTime.now();
      _sequenceCounter = 0;
      _signalProcessor.resetStats();
      _signalProcessor.resetState();
      _lastEmittedPoint = null;
      
      _updateState(LocationTrackingState.active);
    } catch (e) {
      _updateState(LocationTrackingState.error);
      throw LocationServiceException(
        LocationErrorType.unknown,
        'Failed to start location tracking: $e',
      );
    }
  }

  @override
  Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentSettings = null;
    _trackingStartTime = null;
    _lastEmittedPoint = null;
    _gapDetectionTimer?.cancel();
    _gapDetectionTimer = null;
    _updateState(LocationTrackingState.stopped);
  }

  @override
  Future<void> pauseLocationTracking() async {
    if (_trackingState == LocationTrackingState.active) {
      _updateState(LocationTrackingState.paused);
    }
  }

  @override
  Future<void> resumeLocationTracking() async {
    if (_trackingState == LocationTrackingState.paused) {
      _updateState(LocationTrackingState.active);
    }
  }

  @override
  LocationTrackingState get trackingState => _trackingState;

  @override
  Stream<TrackPoint> get locationStream => _locationController.stream;

  @override
  Stream<LocationQuality> get locationQualityStream => _qualityController.stream;

  @override
  Stream<LocationTrackingState> get trackingStateStream => _stateController.stream;

  @override
  Future<Coordinates?> getLastKnownLocation() async {
    try {
      final position = await geolocator.Geolocator.getLastKnownPosition();
      if (position == null) return null;
      
      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool get supportsBackgroundLocation => true;

  @override
  Future<bool> isHighAccuracyAvailable() async {
    // Check if GPS is available
    return await isLocationServiceEnabled();
  }

  @override
  Future<double> getEstimatedBatteryUsage(LocationAccuracy accuracy) async {
    // Estimated battery usage per hour based on accuracy level
    switch (accuracy) {
      case LocationAccuracy.low:
        return 2.0; // 2% per hour
      case LocationAccuracy.balanced:
        return 4.0; // 4% per hour
      case LocationAccuracy.high:
        return 6.0; // 6% per hour
      case LocationAccuracy.best:
        return 8.0; // 8% per hour
    }
  }

  @override
  Future<void> configureFiltering({
    double maxAccuracy = 50.0,
    double maxSpeed = 50.0,
    bool enableKalmanFilter = true,
    bool enableOutlierDetection = true,
  }) async {
    // Create new processor with updated configuration
    final config = GpsProcessingConfig(
      maxAccuracy: maxAccuracy,
      maxSpeed: maxSpeed,
      enableKalmanFilter: enableKalmanFilter,
      enableOutlierDetection: enableOutlierDetection,
    );
    
    // Reset state when reconfiguring
    final oldStats = _signalProcessor.getStats();
    _signalProcessor = GpsSignalProcessor(config: config);
    
    // If we had previous stats, we might want to preserve some of them
    // For now, we'll start fresh with new configuration
  }

  @override
  Future<LocationTrackingStats> getTrackingStats() async {
    final duration = _trackingStartTime != null 
        ? DateTime.now().difference(_trackingStartTime!)
        : Duration.zero;
    
    final processingStats = _signalProcessor.getStats();
    
    // Rough battery usage estimation
    final batteryUsage = duration.inMinutes * 0.1; // ~6% per hour

    return LocationTrackingStats(
      totalPoints: processingStats.totalProcessed,
      filteredPoints: processingStats.filteredOut,
      averageAccuracy: processingStats.averageConfidence * 50, // Convert confidence to accuracy estimate
      trackingDuration: duration,
      batteryUsagePercent: batteryUsage,
    );
  }

  @override
  Future<void> resetTrackingStats() async {
    _signalProcessor.resetStats();
    _trackingStartTime = DateTime.now();
  }

  /// Set the current activity ID for tracking
  void setCurrentActivityId(String activityId) {
    _currentActivityId = activityId;
  }

  // Private helper methods

  void _handleLocationUpdate(Position position) {
    if (_trackingState != LocationTrackingState.active) {
      return; // Ignore updates when paused
    }

    // Create raw track point
    final rawPoint = TrackPoint(
      id: '', // Will be set by repository
      activityId: _currentActivityId,
      timestamp: Timestamp(DateTime.fromMillisecondsSinceEpoch(
        position.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      )),
      coordinates: Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        elevation: position.altitude,
      ),
      accuracy: position.accuracy,
      source: LocationSource.gps,
      sequence: _sequenceCounter,
    );

    // Process through signal processing pipeline
    final result = _signalProcessor.processPoint(rawPoint);
    
    if (result.isAccepted && result.point != null) {
      // Check for gaps and interpolate if needed
      _handleGapDetection(result.point!);
      
      // Emit the processed point
      _emitLocationPoint(result.point!);
      _emitLocationQuality(result.point!, result.confidence);
      
      _lastEmittedPoint = result.point!;
      _sequenceCounter++;
      
      // Reset gap detection timer
      _resetGapDetectionTimer();
    }
  }

  void _handleLocationError(dynamic error) {
    _updateState(LocationTrackingState.error);
  }

  void _handleGapDetection(TrackPoint currentPoint) {
    if (_lastEmittedPoint == null) return;
    
    final gapDuration = currentPoint.timestamp.difference(_lastEmittedPoint!.timestamp);
    
    // If there's a significant gap, try to interpolate
    if (gapDuration.inSeconds > 10) {
      final interpolatedPoints = _signalProcessor.interpolateGap(
        _lastEmittedPoint!,
        currentPoint,
      );
      
      // Emit interpolated points
      for (final interpolatedPoint in interpolatedPoints) {
        final pointWithSequence = interpolatedPoint.copyWith(
          sequence: _sequenceCounter++,
        );
        _emitLocationPoint(pointWithSequence);
        
        // Create confidence for interpolated point
        final interpolatedConfidence = GpsConfidence(
          accuracy: 0.5,
          speed: 0.7,
          consistency: 0.6,
          temporal: 0.8,
          overall: 0.6,
        );
        _emitLocationQuality(pointWithSequence, interpolatedConfidence);
      }
    }
  }

  void _resetGapDetectionTimer() {
    _gapDetectionTimer?.cancel();
    _gapDetectionTimer = Timer(const Duration(seconds: 30), () {
      // Gap detected - this could trigger additional processing if needed
    });
  }



  void _emitLocationPoint(TrackPoint point) {
    _locationController.add(point);
  }

  void _emitLocationQuality(TrackPoint point, GpsConfidence confidence) {
    final quality = LocationQuality(
      accuracy: point.accuracy,
      signalStrength: confidence.overall,
      satelliteCount: _estimateSatelliteCount(point.accuracy),
      isGpsEnabled: true,
    );
    _qualityController.add(quality);
  }

  double _calculateSignalStrength(double accuracy) {
    // Convert accuracy to signal strength (0.0 to 1.0)
    if (accuracy <= 5) return 1.0;
    if (accuracy <= 10) return 0.8;
    if (accuracy <= 20) return 0.6;
    if (accuracy <= 50) return 0.4;
    return 0.2;
  }

  int _estimateSatelliteCount(double accuracy) {
    // Estimate satellite count based on accuracy
    if (accuracy <= 5) return 8;
    if (accuracy <= 10) return 6;
    if (accuracy <= 20) return 4;
    return 3;
  }

  void _updateState(LocationTrackingState newState) {
    if (_trackingState != newState) {
      _trackingState = newState;
      _stateController.add(_trackingState);
    }
  }

  LocationPermissionStatus _mapGeolocatorPermission(geolocator.LocationPermission permission) {
    switch (permission) {
      case geolocator.LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case geolocator.LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case geolocator.LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case geolocator.LocationPermission.always:
        return LocationPermissionStatus.always;
      case geolocator.LocationPermission.unableToDetermine:
        return LocationPermissionStatus.notRequested;
    }
  }

  geolocator.LocationAccuracy _mapLocationAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.low:
        return geolocator.LocationAccuracy.low;
      case LocationAccuracy.balanced:
        return geolocator.LocationAccuracy.medium;
      case LocationAccuracy.high:
        return geolocator.LocationAccuracy.high;
      case LocationAccuracy.best:
        return geolocator.LocationAccuracy.best;
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
    _qualityController.close();
    _stateController.close();
  }
}