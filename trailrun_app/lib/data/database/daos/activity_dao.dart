import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/activities_table.dart';
import '../../../domain/models/activity.dart';
import '../../../domain/enums/privacy_level.dart';
import '../../../domain/enums/sync_state.dart';
import '../../../domain/value_objects/measurement_units.dart';
import '../../../domain/value_objects/timestamp.dart';

part 'activity_dao.g.dart';

/// Data Access Object for Activity operations
@DriftAccessor(tables: [ActivitiesTable])
class ActivityDao extends DatabaseAccessor<TrailRunDatabase> with _$ActivityDaoMixin {
  ActivityDao(super.db);

  /// Get all activities ordered by start time (newest first)
  Future<List<ActivityEntity>> getAllActivities() {
    return (select(activitiesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
      .get();
  }

  /// Get activities with pagination
  Future<List<ActivityEntity>> getActivitiesPaginated({
    required int limit,
    required int offset,
  }) {
    return (select(activitiesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
      ..limit(limit, offset: offset))
      .get();
  }

  /// Get activity by ID
  Future<ActivityEntity?> getActivityById(String id) {
    return (select(activitiesTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get currently active (in-progress) activity
  Future<ActivityEntity?> getActiveActivity() {
    return (select(activitiesTable)..where((t) => t.endTime.isNull())).getSingleOrNull();
  }

  /// Get activities by sync state
  Future<List<ActivityEntity>> getActivitiesBySyncState(SyncState syncState) {
    return (select(activitiesTable)..where((t) => t.syncState.equals(syncState.index))).get();
  }

  /// Get activities within date range
  Future<List<ActivityEntity>> getActivitiesInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final startMillis = startDate.millisecondsSinceEpoch;
    final endMillis = endDate.millisecondsSinceEpoch;
    
    return (select(activitiesTable)
      ..where((t) => t.startTime.isBetweenValues(startMillis, endMillis))
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
      .get();
  }

  /// Search activities by title or notes
  Future<List<ActivityEntity>> searchActivities(String query) {
    final searchTerm = '%$query%';
    return (select(activitiesTable)
      ..where((t) => t.title.like(searchTerm) | t.notes.like(searchTerm))
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
      .get();
  }

  /// Get activities count
  Future<int> getActivitiesCount() async {
    final query = selectOnly(activitiesTable)..addColumns([activitiesTable.id.count()]);
    final result = await query.getSingle();
    return result.read(activitiesTable.id.count()) ?? 0;
  }

  /// Create new activity
  Future<int> createActivity(ActivityEntity activity) {
    return into(activitiesTable).insert(activity);
  }

  /// Update existing activity
  Future<bool> updateActivity(ActivityEntity activity) {
    return update(activitiesTable).replace(activity);
  }

  /// Update activity sync state
  Future<int> updateActivitySyncState(String id, SyncState syncState) {
    return (update(activitiesTable)..where((t) => t.id.equals(id)))
      .write(ActivitiesTableCompanion(
        syncState: Value(syncState.index),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }

  /// Delete activity by ID
  Future<int> deleteActivity(String id) {
    return (delete(activitiesTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all activities (for testing/reset)
  Future<int> deleteAllActivities() {
    return delete(activitiesTable).go();
  }

  /// Watch activity changes by ID
  Stream<ActivityEntity?> watchActivityById(String id) {
    return (select(activitiesTable)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Watch all activities
  Stream<List<ActivityEntity>> watchAllActivities() {
    return (select(activitiesTable)
      ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
      .watch();
  }

  /// Watch active activity
  Stream<ActivityEntity?> watchActiveActivity() {
    return (select(activitiesTable)..where((t) => t.endTime.isNull())).watchSingleOrNull();
  }

  /// Convert domain Activity to database entity
  ActivityEntity toEntity(Activity activity) {
    return ActivityEntity(
      id: activity.id,
      startTime: activity.startTime.millisecondsSinceEpoch,
      endTime: activity.endTime?.millisecondsSinceEpoch,
      distanceMeters: activity.distance.meters,
      durationSeconds: activity.duration?.inSeconds ?? 0,
      elevationGainMeters: activity.elevationGain.meters,
      elevationLossMeters: activity.elevationLoss.meters,
      averagePaceSecondsPerKm: activity.averagePace?.secondsPerKilometer,
      title: activity.title,
      notes: activity.notes,
      privacyLevel: activity.privacy.index,
      coverPhotoId: activity.coverPhotoId,
      syncState: activity.syncState.index,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Convert database entity to domain Activity
  Activity fromEntity(ActivityEntity entity) {
    return Activity(
      id: entity.id,
      startTime: Timestamp.fromMilliseconds(entity.startTime),
      endTime: entity.endTime != null ? Timestamp.fromMilliseconds(entity.endTime!) : null,
      distance: Distance.meters(entity.distanceMeters),
      elevationGain: Elevation.meters(entity.elevationGainMeters),
      elevationLoss: Elevation.meters(entity.elevationLossMeters),
      averagePace: entity.averagePaceSecondsPerKm != null 
        ? Pace.secondsPerKilometer(entity.averagePaceSecondsPerKm!) 
        : null,
      title: entity.title,
      notes: entity.notes,
      privacy: PrivacyLevel.values[entity.privacyLevel],
      coverPhotoId: entity.coverPhotoId,
      syncState: SyncState.values[entity.syncState],
    );
  }
}