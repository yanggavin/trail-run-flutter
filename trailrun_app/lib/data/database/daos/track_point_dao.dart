import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/track_points_table.dart';
import '../../../domain/models/track_point.dart';
import '../../../domain/enums/location_source.dart';
import '../../../domain/value_objects/coordinates.dart';
import '../../../domain/value_objects/timestamp.dart';

part 'track_point_dao.g.dart';

/// Data Access Object for TrackPoint operations
@DriftAccessor(tables: [TrackPointsTable])
class TrackPointDao extends DatabaseAccessor<TrailRunDatabase> with _$TrackPointDaoMixin {
  TrackPointDao(super.db);

  /// Get all track points for an activity ordered by sequence
  Future<List<TrackPointEntity>> getTrackPointsForActivity(String activityId) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .get();
  }

  /// Get track points for activity with pagination
  Future<List<TrackPointEntity>> getTrackPointsPaginated({
    required String activityId,
    required int limit,
    required int offset,
  }) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)])
      ..limit(limit, offset: offset))
      .get();
  }

  /// Get track point by ID
  Future<TrackPointEntity?> getTrackPointById(String id) {
    return (select(trackPointsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get track points within time range for an activity
  Future<List<TrackPointEntity>> getTrackPointsInTimeRange({
    required String activityId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final startMillis = startTime.millisecondsSinceEpoch;
    final endMillis = endTime.millisecondsSinceEpoch;
    
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.timestamp.isBetweenValues(startMillis, endMillis))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .get();
  }

  /// Get latest track point for an activity
  Future<TrackPointEntity?> getLatestTrackPoint(String activityId) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.desc(t.sequence)])
      ..limit(1))
      .getSingleOrNull();
  }

  /// Get track points count for an activity
  Future<int> getTrackPointsCount(String activityId) async {
    final query = selectOnly(trackPointsTable)
      ..addColumns([trackPointsTable.id.count()])
      ..where(trackPointsTable.activityId.equals(activityId));
    final result = await query.getSingle();
    return result.read(trackPointsTable.id.count()) ?? 0;
  }

  /// Get track points with accuracy better than threshold
  Future<List<TrackPointEntity>> getAccurateTrackPoints({
    required String activityId,
    required double maxAccuracyMeters,
  }) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.accuracy.isSmallerOrEqualValue(maxAccuracyMeters))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .get();
  }

  /// Create new track point
  Future<int> createTrackPoint(TrackPointEntity trackPoint) {
    return into(trackPointsTable).insert(trackPoint);
  }

  /// Create multiple track points in batch
  Future<void> createTrackPointsBatch(List<TrackPointEntity> trackPoints) {
    return batch((batch) {
      batch.insertAll(trackPointsTable, trackPoints);
    });
  }

  /// Update existing track point
  Future<bool> updateTrackPoint(TrackPointEntity trackPoint) {
    return update(trackPointsTable).replace(trackPoint);
  }

  /// Delete track point by ID
  Future<int> deleteTrackPoint(String id) {
    return (delete(trackPointsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all track points for an activity
  Future<int> deleteTrackPointsForActivity(String activityId) {
    return (delete(trackPointsTable)..where((t) => t.activityId.equals(activityId))).go();
  }

  /// Delete track points older than specified date
  Future<int> deleteTrackPointsOlderThan(DateTime cutoffDate) {
    final cutoffMillis = cutoffDate.millisecondsSinceEpoch;
    return (delete(trackPointsTable)..where((t) => t.timestamp.isSmallerThanValue(cutoffMillis))).go();
  }

  /// Watch track points for an activity
  Stream<List<TrackPointEntity>> watchTrackPointsForActivity(String activityId) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
      .watch();
  }

  /// Watch latest track point for an activity
  Stream<TrackPointEntity?> watchLatestTrackPoint(String activityId) {
    return (select(trackPointsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.desc(t.sequence)])
      ..limit(1))
      .watchSingleOrNull();
  }

  /// Convert domain TrackPoint to database entity
  TrackPointEntity toEntity(TrackPoint trackPoint) {
    return TrackPointEntity(
      id: trackPoint.id,
      activityId: trackPoint.activityId,
      timestamp: trackPoint.timestamp.millisecondsSinceEpoch,
      latitude: trackPoint.coordinates.latitude,
      longitude: trackPoint.coordinates.longitude,
      elevation: trackPoint.coordinates.elevation,
      accuracy: trackPoint.accuracy,
      source: trackPoint.source.index,
      sequence: trackPoint.sequence,
    );
  }

  /// Convert database entity to domain TrackPoint
  TrackPoint fromEntity(TrackPointEntity entity) {
    return TrackPoint(
      id: entity.id,
      activityId: entity.activityId,
      timestamp: Timestamp.fromMilliseconds(entity.timestamp),
      coordinates: Coordinates(
        latitude: entity.latitude,
        longitude: entity.longitude,
        elevation: entity.elevation,
      ),
      accuracy: entity.accuracy,
      source: LocationSource.values[entity.source],
      sequence: entity.sequence,
    );
  }
}