import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// Data Access Object for SyncQueue operations
@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<TrailRunDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Get all pending sync operations ordered by priority and creation time
  Future<List<SyncQueueEntity>> getPendingSyncOperations() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final allOperations = await (select(syncQueueTable)
      ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ]))
      .get();
    
    // Filter out operations that have exceeded max retries
    return allOperations.where((op) => op.retryCount < op.maxRetries).toList();
  }

  /// Get sync operations by entity type
  Future<List<SyncQueueEntity>> getSyncOperationsByType(String entityType) {
    return (select(syncQueueTable)
      ..where((t) => t.entityType.equals(entityType))
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ]))
      .get();
  }

  /// Get sync operation by entity ID and operation type
  Future<SyncQueueEntity?> getSyncOperationByEntity({
    required String entityType,
    required String entityId,
    required String operation,
  }) {
    return (select(syncQueueTable)
      ..where((t) => t.entityType.equals(entityType) & 
                     t.entityId.equals(entityId) & 
                     t.operation.equals(operation)))
      .getSingleOrNull();
  }

  /// Get sync operation by ID
  Future<SyncQueueEntity?> getSyncOperationById(String id) {
    return (select(syncQueueTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get failed sync operations (exceeded max retries)
  Future<List<SyncQueueEntity>> getFailedSyncOperations() {
    return (select(syncQueueTable)
      ..where((t) => t.retryCount.isBiggerOrEqualValue(3)) // Use hardcoded value for now
      ..orderBy([(t) => OrderingTerm.desc(t.lastAttemptAt)]))
      .get();
  }

  /// Get sync operations count
  Future<int> getSyncOperationsCount() async {
    final query = selectOnly(syncQueueTable)..addColumns([syncQueueTable.id.count()]);
    final result = await query.getSingle();
    return result.read(syncQueueTable.id.count()) ?? 0;
  }

  /// Get pending sync operations count
  Future<int> getPendingSyncOperationsCount() async {
    final pendingOps = await getPendingSyncOperations();
    return pendingOps.length;
  }

  /// Create new sync operation
  Future<int> createSyncOperation(SyncQueueEntity syncOperation) {
    return into(syncQueueTable).insert(syncOperation);
  }

  /// Create multiple sync operations in batch
  Future<void> createSyncOperationsBatch(List<SyncQueueEntity> syncOperations) {
    return batch((batch) {
      batch.insertAll(syncQueueTable, syncOperations);
    });
  }

  /// Update sync operation retry information
  Future<int> updateSyncOperationRetry({
    required String id,
    required int retryCount,
    required DateTime nextAttemptAt,
    String? lastError,
  }) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id)))
      .write(SyncQueueTableCompanion(
        retryCount: Value(retryCount),
        lastAttemptAt: Value(DateTime.now().millisecondsSinceEpoch),
        nextAttemptAt: Value(nextAttemptAt.millisecondsSinceEpoch),
        lastError: Value(lastError),
      ));
  }

  /// Update sync operation payload
  Future<int> updateSyncOperationPayload(String id, String payload) {
    return (update(syncQueueTable)..where((t) => t.id.equals(id)))
      .write(SyncQueueTableCompanion(
        payload: Value(payload),
      ));
  }

  /// Delete sync operation by ID
  Future<int> deleteSyncOperation(String id) {
    return (delete(syncQueueTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete sync operations for specific entity
  Future<int> deleteSyncOperationsForEntity({
    required String entityType,
    required String entityId,
  }) {
    return (delete(syncQueueTable)
      ..where((t) => t.entityType.equals(entityType) & 
                     t.entityId.equals(entityId)))
      .go();
  }

  /// Delete completed sync operations (successfully synced)
  Future<int> deleteCompletedSyncOperations() {
    // This would typically be called after successful sync
    // For now, we'll delete operations that have been attempted recently
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
    return (delete(syncQueueTable)
      ..where((t) => t.lastAttemptAt.isNotNull() & 
                     t.lastAttemptAt.isSmallerThanValue(cutoffTime) &
                     t.lastError.isNull()))
      .go();
  }

  /// Delete failed sync operations older than specified date
  Future<int> deleteFailedSyncOperationsOlderThan(DateTime cutoffDate) {
    final cutoffMillis = cutoffDate.millisecondsSinceEpoch;
    return (delete(syncQueueTable)
      ..where((t) => t.retryCount.isBiggerOrEqualValue(3) &
                     t.createdAt.isSmallerThanValue(cutoffMillis)))
      .go();
  }

  /// Delete all sync operations (for testing/reset)
  Future<int> deleteAllSyncOperations() {
    return delete(syncQueueTable).go();
  }

  /// Watch pending sync operations
  Stream<List<SyncQueueEntity>> watchPendingSyncOperations() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (select(syncQueueTable)
      ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
      ..orderBy([
        (t) => OrderingTerm.desc(t.priority),
        (t) => OrderingTerm.asc(t.createdAt),
      ]))
      .watch()
      .map((operations) => operations.where((op) => op.retryCount < op.maxRetries).toList());
  }

  /// Watch sync operations count
  Stream<int> watchSyncOperationsCount() {
    final query = selectOnly(syncQueueTable)..addColumns([syncQueueTable.id.count()]);
    return query.watchSingle().map((row) => row.read(syncQueueTable.id.count()) ?? 0);
  }

  /// Create sync operation for entity creation
  SyncQueueEntity createEntitySyncOperation({
    required String id,
    required String entityType,
    required String entityId,
    required String payload,
    int priority = 0,
    int maxRetries = 3,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncQueueEntity(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: 'create',
      payload: payload,
      priority: priority,
      retryCount: 0,
      maxRetries: maxRetries,
      createdAt: now,
      lastAttemptAt: null,
      nextAttemptAt: now,
      lastError: null,
    );
  }

  /// Create sync operation for entity update
  SyncQueueEntity updateEntitySyncOperation({
    required String id,
    required String entityType,
    required String entityId,
    required String payload,
    int priority = 0,
    int maxRetries = 3,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncQueueEntity(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: 'update',
      payload: payload,
      priority: priority,
      retryCount: 0,
      maxRetries: maxRetries,
      createdAt: now,
      lastAttemptAt: null,
      nextAttemptAt: now,
      lastError: null,
    );
  }

  /// Create sync operation for entity deletion
  SyncQueueEntity deleteEntitySyncOperation({
    required String id,
    required String entityType,
    required String entityId,
    int priority = 0,
    int maxRetries = 3,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncQueueEntity(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: 'delete',
      payload: '{}', // Empty payload for delete operations
      priority: priority,
      retryCount: 0,
      maxRetries: maxRetries,
      createdAt: now,
      lastAttemptAt: null,
      nextAttemptAt: now,
      lastError: null,
    );
  }
}