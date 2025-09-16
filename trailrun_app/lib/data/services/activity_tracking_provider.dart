import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../database/database_provider.dart';
import '../repositories/activity_repository_impl.dart';
import 'activity_tracking_service.dart';
import 'location_service_provider.dart';

/// Provider for activity tracking service with dependency injection
class ActivityTrackingProvider {
  static ActivityTrackingService? _instance;
  static ActivityRepository? _activityRepository;
  static LocationRepository? _locationRepository;

  /// Get singleton instance of activity tracking service
  static ActivityTrackingService getInstance() {
    _instance ??= ActivityTrackingService(
      activityRepository: getActivityRepository(),
      locationRepository: getLocationRepository(),
      autoPauseConfig: const AutoPauseConfig(
        enabled: true,
        speedThreshold: 0.5, // 0.5 m/s (1.8 km/h)
        timeThreshold: Duration(seconds: 10),
        resumeSpeedThreshold: 1.0, // 1.0 m/s (3.6 km/h)
      ),
    );
    return _instance!;
  }

  /// Get activity repository instance
  static ActivityRepository getActivityRepository() {
    _activityRepository ??= ActivityRepositoryImpl(
      database: DatabaseProvider.getInstance(),
    );
    return _activityRepository!;
  }

  /// Get location repository instance
  static LocationRepository getLocationRepository() {
    _locationRepository ??= LocationServiceProvider.getInstance();
    return _locationRepository!;
  }

  /// Reset instances (useful for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
    _activityRepository = null;
    _locationRepository = null;
  }

  /// Configure auto-pause settings
  static void configureAutoPause({
    bool enabled = true,
    double speedThreshold = 0.5,
    Duration timeThreshold = const Duration(seconds: 10),
    double resumeSpeedThreshold = 1.0,
  }) {
    final config = AutoPauseConfig(
      enabled: enabled,
      speedThreshold: speedThreshold,
      timeThreshold: timeThreshold,
      resumeSpeedThreshold: resumeSpeedThreshold,
    );

    // If instance exists, update its configuration
    _instance?.configureAutoPause(config);

    // For new instances, we'd need to store this config
    // For now, we'll recreate the instance with new config
    if (_instance != null) {
      _instance!.dispose();
      _instance = ActivityTrackingService(
        activityRepository: getActivityRepository(),
        locationRepository: getLocationRepository(),
        autoPauseConfig: config,
      );
    }
  }
}