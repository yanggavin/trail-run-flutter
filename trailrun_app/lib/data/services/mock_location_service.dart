import 'dart:async';
import 'dart:math' as math;

import '../../domain/enums/location_source.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';

/// Mock location service for testing and development
class MockLocationService implements LocationRepository {
  MockLocationService({
    this.simulateMovement = true,
    this.baseLatitude = 45.0,
    this.baseLongitude = -122.0,
    this.baseElevation = 100.0,
  });

  final bool simulateMovement;
  final double baseLatitude;
  final double baseLongitude;
  final double baseElevation;

  // Stream controllers
  final StreamController<TrackPoint> _locationController = StreamController<TrackPoint>.broadcast();
  final StreamController<LocationQuality> _qualityController = StreamController<LocationQuality>.broadcast();
  final StreamController<LocationTrackingState> _stateController = StreamController<LocationTrackingState>.broadcast();

  // State
  LocationTrackingState _trackingState = LocationTrackingState.stopped;
  Timer? _simulationTimer;
  String _currentActivityId = '';
  int _sequenceCounter = 0;
  DateTime? _trackingStartTime;
  
  // Simulation state
  double _currentLat = 0;
  double _currentLon = 0;
  double _currentElevation = 0;
  double _direction = 0; // Direction in radians
  final math.Random _random = math.Random();

  // Statistics
  int _totalPoints = 0;
  int _filteredPoints = 0;
  final List<double> _accuracyHistory = [];

  @override
  Future<LocationPermissionStatus> getPermissionStatus() async {
    // Simulate permission granted for testing
    return LocationPermissionStatus.whileInUse;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    // Simulate successful permission request
    return LocationPermissionStatus.whileInUse;
  }

  @override
  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    // Simulate background permission granted
    return LocationPermissionStatus.always;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  @override
  Future<Coordinates?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return Coordinates(
      latitude: baseLatitude + (_random.nextDouble() - 0.5) * 0.001,
      longitude: baseLongitude + (_random.nextDouble() - 0.5) * 0.001,
      elevation: baseElevation + (_random.nextDouble() - 0.5) * 10,
    );
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

    _updateState(LocationTrackingState.starting);
    
    // Initialize simulation position
    _currentLat = baseLatitude;
    _currentLon = baseLongitude;
    _currentElevation = baseElevation;
    _direction = _random.nextDouble() * 2 * math.pi;
    
    _trackingStartTime = DateTime.now();
    _sequenceCounter = 0;
    _totalPoints = 0;
    _filteredPoints = 0;
    _accuracyHistory.clear();

    // Start simulation timer
    _simulationTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      if (_trackingState == LocationTrackingState.active) {
        _generateLocationUpdate();
      }
    });

    _updateState(LocationTrackingState.active);
  }

  @override
  Future<void> stopLocationTracking() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _trackingStartTime = null;
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
    return Coordinates(
      latitude: _currentLat,
      longitude: _currentLon,
      elevation: _currentElevation,
    );
  }

  @override
  bool get supportsBackgroundLocation => true;

  @override
  Future<bool> isHighAccuracyAvailable() async => true;

  @override
  Future<double> getEstimatedBatteryUsage(LocationAccuracy accuracy) async {
    switch (accuracy) {
      case LocationAccuracy.low:
        return 2.0;
      case LocationAccuracy.balanced:
        return 4.0;
      case LocationAccuracy.high:
        return 6.0;
      case LocationAccuracy.best:
        return 8.0;
    }
  }

  @override
  Future<void> configureFiltering({
    double maxAccuracy = 50.0,
    double maxSpeed = 50.0,
    bool enableKalmanFilter = true,
    bool enableOutlierDetection = true,
  }) async {
    // Configuration accepted
  }

  @override
  Future<LocationTrackingStats> getTrackingStats() async {
    final duration = _trackingStartTime != null 
        ? DateTime.now().difference(_trackingStartTime!)
        : Duration.zero;
    
    final averageAccuracy = _accuracyHistory.isNotEmpty
        ? _accuracyHistory.reduce((a, b) => a + b) / _accuracyHistory.length
        : 0.0;

    final batteryUsage = duration.inMinutes * 0.05; // Lower usage for mock

    return LocationTrackingStats(
      totalPoints: _totalPoints,
      filteredPoints: _filteredPoints,
      averageAccuracy: averageAccuracy,
      trackingDuration: duration,
      batteryUsagePercent: batteryUsage,
    );
  }

  @override
  Future<void> resetTrackingStats() async {
    _totalPoints = 0;
    _filteredPoints = 0;
    _accuracyHistory.clear();
    _trackingStartTime = DateTime.now();
  }

  // Private methods

  void _generateLocationUpdate() {
    if (!simulateMovement) {
      // Static location with small random variations
      _currentLat = baseLatitude + (_random.nextDouble() - 0.5) * 0.0001;
      _currentLon = baseLongitude + (_random.nextDouble() - 0.5) * 0.0001;
      _currentElevation = baseElevation + (_random.nextDouble() - 0.5) * 2;
    } else {
      // Simulate walking/running movement
      final speed = 1.5 + _random.nextDouble() * 2.0; // 1.5-3.5 m/s (walking to jogging)
      final timeStep = 2.0; // 2 seconds
      final distance = speed * timeStep; // meters
      
      // Add some randomness to direction
      _direction += (_random.nextDouble() - 0.5) * 0.2;
      
      // Convert distance to lat/lon changes (rough approximation)
      final latChange = (distance * math.cos(_direction)) / 111320; // meters to degrees lat
      final lonChange = (distance * math.sin(_direction)) / (111320 * math.cos(_currentLat * math.pi / 180)); // meters to degrees lon
      
      _currentLat += latChange;
      _currentLon += lonChange;
      
      // Simulate elevation changes
      _currentElevation += (_random.nextDouble() - 0.5) * 5;
    }

    _totalPoints++;

    // Simulate GPS accuracy variations
    final accuracy = 3.0 + _random.nextDouble() * 7.0; // 3-10 meters
    _accuracyHistory.add(accuracy);
    
    if (_accuracyHistory.length > 100) {
      _accuracyHistory.removeAt(0);
    }

    // Create track point
    final trackPoint = TrackPoint(
      id: '', // Will be generated by repository
      activityId: _currentActivityId,
      timestamp: Timestamp.now(),
      coordinates: Coordinates(
        latitude: _currentLat,
        longitude: _currentLon,
        elevation: _currentElevation,
      ),
      accuracy: accuracy,
      source: LocationSource.gps,
      sequence: _sequenceCounter++,
    );

    // Emit location update
    _locationController.add(trackPoint);

    // Emit quality update
    final quality = LocationQuality(
      accuracy: accuracy,
      signalStrength: 0.7 + _random.nextDouble() * 0.3, // 0.7-1.0
      satelliteCount: 6 + _random.nextInt(5), // 6-10 satellites
      isGpsEnabled: true,
    );
    _qualityController.add(quality);
  }

  void _updateState(LocationTrackingState newState) {
    if (_trackingState != newState) {
      _trackingState = newState;
      _stateController.add(_trackingState);
    }
  }

  /// Manually emit a location update (for testing)
  void emitLocationUpdate(TrackPoint trackPoint) {
    _locationController.add(trackPoint);
    
    // Also emit quality update
    final quality = LocationQuality(
      accuracy: trackPoint.accuracy,
      signalStrength: 0.8,
      satelliteCount: 8,
      isGpsEnabled: true,
    );
    _qualityController.add(quality);
  }

  /// Set the current activity ID for tracking
  void setCurrentActivityId(String activityId) {
    _currentActivityId = activityId;
  }

  void dispose() {
    _simulationTimer?.cancel();
    _locationController.close();
    _qualityController.close();
    _stateController.close();
  }
}