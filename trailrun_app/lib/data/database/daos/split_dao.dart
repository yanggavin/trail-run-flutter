import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/splits_table.dart';
import '../../../domain/models/split.dart';
import '../../../domain/value_objects/measurement_units.dart';
import '../../../domain/value_objects/timestamp.dart';

part 'split_dao.g.dart';

/// Data Access Object for Split operations
@DriftAccessor(tables: [SplitsTable])
class SplitDao extends DatabaseAccessor<TrailRunDatabase> with _$SplitDaoMixin {
  SplitDao(super.db);

  /// Get all splits for an activity ordered by split number
  Future<List<SplitEntity>> getSplitsForActivity(String activityId) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.splitNumber)]))
      .get();
  }

  /// Get split by ID
  Future<SplitEntity?> getSplitById(String id) {
    return (select(splitsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get specific split by activity and split number
  Future<SplitEntity?> getSplitByNumber({
    required String activityId,
    required int splitNumber,
  }) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.splitNumber.equals(splitNumber)))
      .getSingleOrNull();
  }

  /// Get splits count for an activity
  Future<int> getSplitsCount(String activityId) async {
    final query = selectOnly(splitsTable)
      ..addColumns([splitsTable.id.count()])
      ..where(splitsTable.activityId.equals(activityId));
    final result = await query.getSingle();
    return result.read(splitsTable.id.count()) ?? 0;
  }

  /// Get fastest split for an activity
  Future<SplitEntity?> getFastestSplit(String activityId) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.paceSecondsPerKm)])
      ..limit(1))
      .getSingleOrNull();
  }

  /// Get slowest split for an activity
  Future<SplitEntity?> getSlowestSplit(String activityId) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.desc(t.paceSecondsPerKm)])
      ..limit(1))
      .getSingleOrNull();
  }

  /// Get splits with significant elevation change
  Future<List<SplitEntity>> getSplitsWithElevationChange({
    required String activityId,
    double minElevationChangeMeters = 10.0,
  }) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     (t.elevationGainMeters.isBiggerThanValue(minElevationChangeMeters) |
                      t.elevationLossMeters.isBiggerThanValue(minElevationChangeMeters)))
      ..orderBy([(t) => OrderingTerm.asc(t.splitNumber)]))
      .get();
  }

  /// Get splits within pace range
  Future<List<SplitEntity>> getSplitsInPaceRange({
    required String activityId,
    required double minPaceSecondsPerKm,
    required double maxPaceSecondsPerKm,
  }) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.paceSecondsPerKm.isBetweenValues(minPaceSecondsPerKm, maxPaceSecondsPerKm))
      ..orderBy([(t) => OrderingTerm.asc(t.splitNumber)]))
      .get();
  }

  /// Create new split
  Future<int> createSplit(SplitEntity split) {
    return into(splitsTable).insert(split);
  }

  /// Create multiple splits in batch
  Future<void> createSplitsBatch(List<SplitEntity> splits) {
    return batch((batch) {
      batch.insertAll(splitsTable, splits);
    });
  }

  /// Update existing split
  Future<bool> updateSplit(SplitEntity split) {
    return update(splitsTable).replace(split);
  }

  /// Delete split by ID
  Future<int> deleteSplit(String id) {
    return (delete(splitsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all splits for an activity
  Future<int> deleteSplitsForActivity(String activityId) {
    return (delete(splitsTable)..where((t) => t.activityId.equals(activityId))).go();
  }

  /// Delete splits older than specified date
  Future<int> deleteSplitsOlderThan(DateTime cutoffDate) {
    final cutoffMillis = cutoffDate.millisecondsSinceEpoch;
    return (delete(splitsTable)..where((t) => t.startTime.isSmallerThanValue(cutoffMillis))).go();
  }

  /// Watch splits for an activity
  Stream<List<SplitEntity>> watchSplitsForActivity(String activityId) {
    return (select(splitsTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.splitNumber)]))
      .watch();
  }

  /// Watch split by ID
  Stream<SplitEntity?> watchSplitById(String id) {
    return (select(splitsTable)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Convert domain Split to database entity
  SplitEntity toEntity(Split split) {
    return SplitEntity(
      id: split.id,
      activityId: split.activityId,
      splitNumber: split.splitNumber,
      startTime: split.startTime.millisecondsSinceEpoch,
      endTime: split.endTime.millisecondsSinceEpoch,
      distanceMeters: split.distance.meters,
      paceSecondsPerKm: split.pace.secondsPerKilometer,
      elevationGainMeters: split.elevationGain.meters,
      elevationLossMeters: split.elevationLoss.meters,
    );
  }

  /// Convert database entity to domain Split
  Split fromEntity(SplitEntity entity) {
    return Split(
      id: entity.id,
      activityId: entity.activityId,
      splitNumber: entity.splitNumber,
      startTime: Timestamp.fromMilliseconds(entity.startTime),
      endTime: Timestamp.fromMilliseconds(entity.endTime),
      distance: Distance.meters(entity.distanceMeters),
      pace: Pace.secondsPerKilometer(entity.paceSecondsPerKm),
      elevationGain: Elevation.meters(entity.elevationGainMeters),
      elevationLoss: Elevation.meters(entity.elevationLossMeters),
    );
  }
}