import '../models/activity.dart';
import '../models/track_point.dart';

/// Filter criteria for querying activities
class ActivityFilter {
  const ActivityFilter({
    this.startDate,
    this.endDate,
    this.minDistance,
    this.maxDistance,
    this.searchText,
    this.hasPhotos,
    this.privacyLevels,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final double? minDistance; // in meters
  final double? maxDistance; // in meters
  final String? searchText;
  final bool? hasPhotos;
  final List<int>? privacyLevels; // PrivacyLevel values
}

/// Sort options for activity queries
enum ActivitySortBy {
  startTimeDesc,
  startTimeAsc,
  distanceDesc,
  distanceAsc,
  durationDesc,
  durationAsc,
}

/// Repository interface for managing activities and track points
abstract class ActivityRepository {
  /// Create a new activity
  Future<Activity> createActivity(Activity activity);

  /// Update an existing activity
  Future<Activity> updateActivity(Activity activity);

  /// Get activity by ID
  Future<Activity?> getActivity(String activityId);

  /// Get the currently active (in-progress) activity
  Future<Activity?> getActiveActivity();

  /// Get activities with pagination and filtering
  Future<List<Activity>> getActivities({
    int page = 0,
    int pageSize = 20,
    ActivityFilter? filter,
    ActivitySortBy sortBy = ActivitySortBy.startTimeDesc,
  });

  /// Get total count of activities matching filter
  Future<int> getActivityCount({ActivityFilter? filter});

  /// Delete an activity and all associated data
  Future<void> deleteActivity(String activityId);

  /// Watch activity changes (stream)
  Stream<Activity?> watchActivity(String activityId);

  /// Watch all activities changes (stream)
  Stream<List<Activity>> watchActivities({
    ActivityFilter? filter,
    ActivitySortBy sortBy = ActivitySortBy.startTimeDesc,
  });

  /// Add track point to an activity
  Future<void> addTrackPoint(String activityId, TrackPoint trackPoint);

  /// Add multiple track points to an activity (batch operation)
  Future<void> addTrackPoints(String activityId, List<TrackPoint> trackPoints);

  /// Get track points for an activity
  Future<List<TrackPoint>> getTrackPoints(String activityId);

  /// Get track points within a time range
  Future<List<TrackPoint>> getTrackPointsInRange(
    String activityId,
    DateTime startTime,
    DateTime endTime,
  );

  /// Delete track points for an activity
  Future<void> deleteTrackPoints(String activityId);

  /// Search activities by text (title, notes)
  Future<List<Activity>> searchActivities(
    String query, {
    int limit = 50,
  });

  /// Get activities that need synchronization
  Future<List<Activity>> getActivitiesNeedingSync();

  /// Mark activity as synced
  Future<void> markActivitySynced(String activityId);

  /// Mark activity as sync failed
  Future<void> markActivitySyncFailed(String activityId, String error);

  /// Get activity statistics (total distance, count, etc.)
  Future<ActivityStats> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Activity statistics summary
class ActivityStats {
  const ActivityStats({
    required this.totalActivities,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalElevationGain,
    required this.averageDistance,
    required this.averageDuration,
  });

  final int totalActivities;
  final double totalDistance; // in meters
  final Duration totalDuration;
  final double totalElevationGain; // in meters
  final double averageDistance; // in meters
  final Duration averageDuration;
}