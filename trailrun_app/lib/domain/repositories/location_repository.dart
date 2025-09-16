import '../models/track_point.dart';
import '../value_objects/coordinates.dart';

/// Location accuracy levels for GPS tracking
enum LocationAccuracy {
  /// Lowest accuracy, best battery life
  low,
  
  /// Balanced accuracy and battery usage
  balanced,
  
  /// High accuracy, more battery usage
  high,
  
  /// Best possible accuracy, highest battery usage
  best,
}

/// Location permission status
enum LocationPermissionStatus {
  /// Permission not requested yet
  notRequested,
  
  /// Permission denied by user
  denied,
  
  /// Permission denied permanently (don't ask again)
  deniedForever,
  
  /// Permission granted for foreground use only
  whileInUse,
  
  /// Permission granted for background use (always)
  always,
}

/// Current location tracking state
enum LocationTrackingState {
  /// Location tracking is stopped
  stopped,
  
  /// Location tracking is starting up
  starting,
  
  /// Location tracking is active
  active,
  
  /// Location tracking is paused
  paused,
  
  /// Location tracking encountered an error
  error,
}

/// Location quality indicator
class LocationQuality {
  const LocationQuality({
    required this.accuracy,
    required this.signalStrength,
    required this.satelliteCount,
    required this.isGpsEnabled,
  });

  /// GPS accuracy in meters (lower is better)
  final double accuracy;
  
  /// Signal strength (0.0 to 1.0, higher is better)
  final double signalStrength;
  
  /// Number of GPS satellites in use
  final int satelliteCount;
  
  /// Whether GPS is enabled on device
  final bool isGpsEnabled;

  /// Overall quality score (0.0 to 1.0, higher is better)
  double get qualityScore {
    if (!isGpsEnabled) return 0.0;
    
    final double accuracyScore = accuracy <= 5 ? 1.0 : 
                                accuracy <= 10 ? 0.8 :
                                accuracy <= 20 ? 0.6 :
                                accuracy <= 50 ? 0.4 : 0.2;
    
    final double satelliteScore = satelliteCount >= 8 ? 1.0 :
                                 satelliteCount >= 6 ? 0.8 :
                                 satelliteCount >= 4 ? 0.6 : 0.4;
    
    return (accuracyScore + signalStrength + satelliteScore) / 3.0;
  }
}

/// Repository interface for location services
abstract class LocationRepository {
  /// Get current location permission status
  Future<LocationPermissionStatus> getPermissionStatus();

  /// Request location permissions
  Future<LocationPermissionStatus> requestPermission();

  /// Request background location permission (if supported)
  Future<LocationPermissionStatus> requestBackgroundPermission();

  /// Check if location services are enabled on device
  Future<bool> isLocationServiceEnabled();

  /// Get current location (one-time)
  Future<Coordinates?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    Duration timeout = const Duration(seconds: 10),
  });

  /// Start continuous location tracking
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int intervalSeconds = 2,
    double distanceFilter = 0, // minimum distance in meters between updates
  });

  /// Stop location tracking
  Future<void> stopLocationTracking();

  /// Pause location tracking (keep GPS active but don't record)
  Future<void> pauseLocationTracking();

  /// Resume location tracking
  Future<void> resumeLocationTracking();

  /// Get current tracking state
  LocationTrackingState get trackingState;

  /// Stream of location updates
  Stream<TrackPoint> get locationStream;

  /// Stream of location quality updates
  Stream<LocationQuality> get locationQualityStream;

  /// Stream of tracking state changes
  Stream<LocationTrackingState> get trackingStateStream;

  /// Get last known location
  Future<Coordinates?> getLastKnownLocation();

  /// Check if background location is supported
  bool get supportsBackgroundLocation;

  /// Check if high accuracy mode is available
  Future<bool> isHighAccuracyAvailable();

  /// Get estimated battery usage per hour for given accuracy
  Future<double> getEstimatedBatteryUsage(LocationAccuracy accuracy);

  /// Configure location filtering parameters
  Future<void> configureFiltering({
    double maxAccuracy = 50.0, // reject points with accuracy worse than this
    double maxSpeed = 50.0, // reject points with impossible speed (m/s)
    bool enableKalmanFilter = true,
    bool enableOutlierDetection = true,
  });

  /// Get location tracking statistics
  Future<LocationTrackingStats> getTrackingStats();

  /// Reset location tracking statistics
  Future<void> resetTrackingStats();
}

/// Location tracking statistics
class LocationTrackingStats {
  const LocationTrackingStats({
    required this.totalPoints,
    required this.filteredPoints,
    required this.averageAccuracy,
    required this.trackingDuration,
    required this.batteryUsagePercent,
  });

  final int totalPoints;
  final int filteredPoints;
  final double averageAccuracy;
  final Duration trackingDuration;
  final double batteryUsagePercent;

  /// Percentage of points that were filtered out
  double get filterRate => totalPoints > 0 ? filteredPoints / totalPoints : 0.0;
}