import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../domain/models/activity.dart';
import '../../domain/models/split.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/value_objects/measurement_units.dart';
import '../../domain/value_objects/timestamp.dart';
import '../database/database.dart';
import '../database/daos/activity_dao.dart';
import '../database/daos/track_point_dao.dart';
import '../database/daos/split_dao.dart';
import '../database/daos/photo_dao.dart';
import '../services/activity_statistics_service.dart';

/// Concrete implementation of ActivityRepository using Drift database
class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl({
    required TrailRunDatabase database,
    ActivityStatisticsService? statisticsService,
  }) : _database = database,
       _activityDao = database.activityDao,
       _trackPointDao = database.trackPointDao,
       _splitDao = database.splitDao,
       _photoDao = database.photoDao,
       _statisticsService = statisticsService ?? ActivityStatisticsService();

  final TrailRunDatabase _database;
  final ActivityDao _activityDao;
  final TrackPointDao _trackPointDao;
  final SplitDao _splitDao;
  final PhotoDao _photoDao;
  final ActivityStatisticsService _statisticsService;

  @override
  Future<Activity> createActivity(Activity activity) async {
    final entity = _activityDao.toEntity(activity);
    await _activityDao.createActivity(entity);
    return activity;
  }

  @override
  Future<Activity> updateActivity(Activity activity) async {
    final entity = _activityDao.toEntity(activity);
    await _activityDao.updateActivity(entity);
    
    // Recalculate statistics if the activity has track points
    await _updateActivityStatistics(activity.id);
    
    return activity;
  }

  @override
  Future<Activity?> getActivity(String activityId) async {
    final entity = await _activityDao.getActivityById(activityId);
    if (entity == null) return null;

    return await _buildCompleteActivity(entity);
  }

  @override
  Future<Activity?> getActiveActivity() async {
    final entity = await _activityDao.getActiveActivity();
    if (entity == null) return null;

    return await _buildCompleteActivity(entity);
  }

  @override
  Future<List<Activity>> getActivities({
    int page = 0,
    int pageSize = 20,
    ActivityFilter? filter,
    ActivitySortBy sortBy = ActivitySortBy.startTimeDesc,
  }) async {
    List<ActivityEntity> entities;
    
    if (filter != null) {
      entities = await _getFilteredActivities(filter, sortBy, page * pageSize, pageSize);
    } else {
      entities = await _getSortedActivities(sortBy, page * pageSize, pageSize);
    }

    final activities = <Activity>[];
    for (final entity in entities) {
      final activity = await _buildCompleteActivity(entity);
      activities.add(activity);
    }

    return activities;
  }

  @override
  Future<int> getActivityCount({ActivityFilter? filter}) async {
    if (filter != null) {
      final entities = await _getFilteredActivities(filter, ActivitySortBy.startTimeDesc, 0, 1000000);
      return entities.length;
    }
    return await _activityDao.getActivitiesCount();
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await _database.transaction(() async {
      // Delete associated data first
      await _trackPointDao.deleteTrackPointsForActivity(activityId);
      await _splitDao.deleteSplitsForActivity(activityId);
      await _photoDao.deletePhotosForActivity(activityId);
      
      // Delete the activity
      await _activityDao.deleteActivity(activityId);
    });
  }

  @override
  Stream<Activity?> watchActivity(String activityId) {
    return _activityDao.watchActivityById(activityId).asyncMap((entity) async {
      if (entity == null) return null;
      return await _buildCompleteActivity(entity);
    });
  }

  @override
  Stream<List<Activity>> watchActivities({
    ActivityFilter? filter,
    ActivitySortBy sortBy = ActivitySortBy.startTimeDesc,
  }) {
    return _activityDao.watchAllActivities().asyncMap((entities) async {
      final activities = <Activity>[];
      for (final entity in entities) {
        final activity = await _buildCompleteActivity(entity);
        activities.add(activity);
      }
      return activities;
    });
  }

  @override
  Future<void> addTrackPoint(String activityId, TrackPoint trackPoint) async {
    final entity = _trackPointDao.toEntity(trackPoint);
    await _trackPointDao.createTrackPoint(entity);
    
    // Update activity statistics
    await _updateActivityStatistics(activityId);
  }

  @override
  Future<void> addTrackPoints(String activityId, List<TrackPoint> trackPoints) async {
    if (trackPoints.isEmpty) return;

    final entities = trackPoints.map((tp) => _trackPointDao.toEntity(tp)).toList();
    await _trackPointDao.createTrackPointsBatch(entities);
    
    // Update activity statistics
    await _updateActivityStatistics(activityId);
  }

  @override
  Future<List<TrackPoint>> getTrackPoints(String activityId) async {
    final entities = await _trackPointDao.getTrackPointsForActivity(activityId);
    return entities.map((e) => _trackPointDao.fromEntity(e)).toList();
  }

  @override
  Future<List<TrackPoint>> getTrackPointsInRange(
    String activityId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final entities = await _trackPointDao.getTrackPointsInTimeRange(
      activityId: activityId,
      startTime: startTime,
      endTime: endTime,
    );
    return entities.map((e) => _trackPointDao.fromEntity(e)).toList();
  }

  @override
  Future<void> deleteTrackPoints(String activityId) async {
    await _trackPointDao.deleteTrackPointsForActivity(activityId);
    
    // Update activity statistics
    await _updateActivityStatistics(activityId);
  }

  @override
  Future<List<Activity>> searchActivities(String query, {int limit = 50}) async {
    final entities = await _activityDao.searchActivities(query);
    final limitedEntities = entities.take(limit).toList();
    
    final activities = <Activity>[];
    for (final entity in limitedEntities) {
      final activity = await _buildCompleteActivity(entity);
      activities.add(activity);
    }

    return activities;
  }

  @override
  Future<List<Activity>> getActivitiesNeedingSync() async {
    final pendingEntities = await _activityDao.getActivitiesBySyncState(SyncState.pending);
    final failedEntities = await _activityDao.getActivitiesBySyncState(SyncState.failed);
    
    final allEntities = [...pendingEntities, ...failedEntities];
    
    final activities = <Activity>[];
    for (final entity in allEntities) {
      final activity = await _buildCompleteActivity(entity);
      activities.add(activity);
    }

    return activities;
  }

  @override
  Future<void> markActivitySynced(String activityId) async {
    await _activityDao.updateActivitySyncState(activityId, SyncState.synced);
  }

  @override
  Future<void> markActivitySyncFailed(String activityId, String error) async {
    await _activityDao.updateActivitySyncState(activityId, SyncState.failed);
  }

  @override
  Future<ActivityStats> getActivityStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<ActivityEntity> entities;
    
    if (startDate != null && endDate != null) {
      entities = await _activityDao.getActivitiesInDateRange(
        startDate: startDate,
        endDate: endDate,
      );
    } else {
      entities = await _activityDao.getAllActivities();
    }

    if (entities.isEmpty) {
      return const ActivityStats(
        totalActivities: 0,
        totalDistance: 0,
        totalDuration: Duration.zero,
        totalElevationGain: 0,
        averageDistance: 0,
        averageDuration: Duration.zero,
      );
    }

    double totalDistance = 0;
    int totalDurationSeconds = 0;
    double totalElevationGain = 0;

    for (final entity in entities) {
      totalDistance += entity.distanceMeters;
      totalDurationSeconds += entity.durationSeconds;
      totalElevationGain += entity.elevationGainMeters;
    }

    return ActivityStats(
      totalActivities: entities.length,
      totalDistance: totalDistance,
      totalDuration: Duration(seconds: totalDurationSeconds),
      totalElevationGain: totalElevationGain,
      averageDistance: totalDistance / entities.length,
      averageDuration: Duration(seconds: totalDurationSeconds ~/ entities.length),
    );
  }

  /// Build complete activity with all related data
  Future<Activity> _buildCompleteActivity(ActivityEntity entity) async {
    final activity = _activityDao.fromEntity(entity);
    
    // Load track points
    final trackPointEntities = await _trackPointDao.getTrackPointsForActivity(entity.id);
    final trackPoints = trackPointEntities.map((e) => _trackPointDao.fromEntity(e)).toList();
    
    // Load splits
    final splitEntities = await _splitDao.getSplitsForActivity(entity.id);
    final splits = splitEntities.map((e) => _splitDao.fromEntity(e)).toList();
    
    // Load photos
    final photoEntities = await _photoDao.getPhotosForActivity(entity.id);
    final photos = photoEntities.map((e) => _photoDao.fromEntity(e)).toList();
    
    return activity.copyWith(
      trackPoints: trackPoints,
      splits: splits,
      photos: photos,
    );
  }

  /// Update activity statistics based on current track points
  Future<void> _updateActivityStatistics(String activityId) async {
    final trackPoints = await getTrackPoints(activityId);
    if (trackPoints.isEmpty) return;

    // Get current activity to calculate duration
    final currentActivityEntity = await _activityDao.getActivityById(activityId);
    if (currentActivityEntity == null) return;

    final currentActivity = _activityDao.fromEntity(currentActivityEntity);
    
    // Use the comprehensive statistics service
    final updatedActivity = _statisticsService.updateActivityWithStats(
      currentActivity.copyWith(trackPoints: trackPoints),
    );

    // Update the database entity
    final updatedEntity = currentActivityEntity.copyWith(
      distanceMeters: updatedActivity.distance.meters,
      elevationGainMeters: updatedActivity.elevationGain.meters,
      elevationLossMeters: updatedActivity.elevationLoss.meters,
      averagePaceSecondsPerKm: Value(updatedActivity.averagePace?.secondsPerKilometer),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _database.transaction(() async {
      // Update activity
      await _activityDao.updateActivity(updatedEntity);
      
      // Update splits
      await _updateActivitySplits(activityId, updatedActivity.splits);
    });
  }

  /// Update splits for an activity
  Future<void> _updateActivitySplits(String activityId, List<Split> splits) async {
    // Delete existing splits
    await _splitDao.deleteSplitsForActivity(activityId);
    
    // Insert new splits
    if (splits.isNotEmpty) {
      final splitEntities = splits.map((split) => _splitDao.toEntity(split)).toList();
      await _splitDao.createSplitsBatch(splitEntities);
    }
  }

  /// Get filtered activities
  Future<List<ActivityEntity>> _getFilteredActivities(
    ActivityFilter filter,
    ActivitySortBy sortBy,
    int offset,
    int limit,
  ) async {
    List<ActivityEntity> entities = await _activityDao.getAllActivities();
    
    // Apply filters
    entities = entities.where((entity) {
      // Date range filter
      if (filter.startDate != null) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(entity.startTime);
        if (startTime.isBefore(filter.startDate!)) return false;
      }
      
      if (filter.endDate != null) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(entity.startTime);
        if (startTime.isAfter(filter.endDate!.add(const Duration(days: 1)))) return false;
      }
      
      // Distance filter
      if (filter.minDistance != null && entity.distanceMeters < filter.minDistance!) {
        return false;
      }
      
      if (filter.maxDistance != null && entity.distanceMeters > filter.maxDistance!) {
        return false;
      }
      
      // Privacy level filter
      if (filter.privacyLevels != null && filter.privacyLevels!.isNotEmpty) {
        if (!filter.privacyLevels!.contains(entity.privacyLevel)) {
          return false;
        }
      }
      
      // Text search filter
      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final searchText = filter.searchText!.toLowerCase();
        final title = entity.title.toLowerCase();
        final notes = entity.notes?.toLowerCase() ?? '';
        
        if (!title.contains(searchText) && !notes.contains(searchText)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Apply photo filter (requires checking related photos)
    if (filter.hasPhotos != null) {
      final filteredEntities = <ActivityEntity>[];
      
      for (final entity in entities) {
        final photos = await _photoDao.getPhotosForActivity(entity.id);
        final hasPhotos = photos.isNotEmpty;
        
        if (filter.hasPhotos == hasPhotos) {
          filteredEntities.add(entity);
        }
      }
      
      entities = filteredEntities;
    }
    
    // Apply sorting
    _sortActivities(entities, sortBy);
    
    // Apply pagination
    final startIndex = math.min(offset, entities.length);
    final endIndex = math.min(offset + limit, entities.length);
    
    return entities.sublist(startIndex, endIndex);
  }

  /// Get sorted activities without filtering
  Future<List<ActivityEntity>> _getSortedActivities(
    ActivitySortBy sortBy,
    int offset,
    int limit,
  ) async {
    final entities = await _activityDao.getActivitiesPaginated(
      limit: limit,
      offset: offset,
    );
    
    _sortActivities(entities, sortBy);
    return entities;
  }

  /// Sort activities in place
  void _sortActivities(List<ActivityEntity> entities, ActivitySortBy sortBy) {
    switch (sortBy) {
      case ActivitySortBy.startTimeDesc:
        entities.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case ActivitySortBy.startTimeAsc:
        entities.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case ActivitySortBy.distanceDesc:
        entities.sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
        break;
      case ActivitySortBy.distanceAsc:
        entities.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        break;
      case ActivitySortBy.durationDesc:
        entities.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
        break;
      case ActivitySortBy.durationAsc:
        entities.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
        break;
    }
  }

}