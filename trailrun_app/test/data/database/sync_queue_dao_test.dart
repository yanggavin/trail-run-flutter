import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:trailrun_app/data/database/database.dart';
import 'package:trailrun_app/data/database/daos/sync_queue_dao.dart';

void main() {
  late TrailRunDatabase database;
  late SyncQueueDao syncQueueDao;

  setUp(() {
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
    syncQueueDao = database.syncQueueDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncQueueDao', () {
    test('should create and retrieve sync operation', () async {
      // Arrange
      final syncOperation = SyncQueueEntity(
        id: 'sync-op-1',
        entityType: 'activity',
        entityId: 'activity-1',
        operation: 'create',
        payload: '{"id": "activity-1", "title": "Test Activity"}',
        priority: 1,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastAttemptAt: null,
        nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
        lastError: null,
      );

      // Act
      await syncQueueDao.createSyncOperation(syncOperation);
      final retrieved = await syncQueueDao.getSyncOperationById('sync-op-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('sync-op-1'));
      expect(retrieved.entityType, equals('activity'));
      expect(retrieved.entityId, equals('activity-1'));
      expect(retrieved.operation, equals('create'));
      expect(retrieved.priority, equals(1));
      expect(retrieved.retryCount, equals(0));
      expect(retrieved.maxRetries, equals(3));
    });

    test('should get pending sync operations ordered by priority and creation time', () async {
      // Arrange
      final now = DateTime.now();
      final syncOperations = [
        SyncQueueEntity(
          id: 'sync-op-low-priority',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now.millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'sync-op-high-priority',
          entityType: 'photo',
          entityId: 'photo-1',
          operation: 'update',
          payload: '{}',
          priority: 2,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'sync-op-medium-priority',
          entityType: 'activity',
          entityId: 'activity-2',
          operation: 'update',
          payload: '{}',
          priority: 1,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: null,
        ),
      ];

      for (final syncOp in syncOperations) {
        await syncQueueDao.createSyncOperation(syncOp);
      }

      // Act
      final pending = await syncQueueDao.getPendingSyncOperations();

      // Assert
      expect(pending.length, equals(3));
      expect(pending[0].id, equals('sync-op-high-priority')); // Highest priority first
      expect(pending[1].id, equals('sync-op-medium-priority')); // Medium priority
      expect(pending[2].id, equals('sync-op-low-priority')); // Lowest priority last
    });

    test('should not return operations that exceeded max retries', () async {
      // Arrange
      final now = DateTime.now();
      final syncOperations = [
        SyncQueueEntity(
          id: 'sync-op-pending',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 1,
          maxRetries: 3,
          createdAt: now.millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'sync-op-failed',
          entityType: 'photo',
          entityId: 'photo-1',
          operation: 'update',
          payload: '{}',
          priority: 0,
          retryCount: 3,
          maxRetries: 3,
          createdAt: now.millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: 'Network error',
        ),
      ];

      for (final syncOp in syncOperations) {
        await syncQueueDao.createSyncOperation(syncOp);
      }

      // Act
      final pending = await syncQueueDao.getPendingSyncOperations();
      final failed = await syncQueueDao.getFailedSyncOperations();

      // Assert
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('sync-op-pending'));
      expect(failed.length, equals(1));
      expect(failed.first.id, equals('sync-op-failed'));
    });

    test('should get sync operations by entity type', () async {
      // Arrange
      final syncOperations = [
        SyncQueueEntity(
          id: 'activity-sync-op',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'photo-sync-op',
          entityType: 'photo',
          entityId: 'photo-1',
          operation: 'update',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        ),
      ];

      for (final syncOp in syncOperations) {
        await syncQueueDao.createSyncOperation(syncOp);
      }

      // Act
      final activityOps = await syncQueueDao.getSyncOperationsByType('activity');
      final photoOps = await syncQueueDao.getSyncOperationsByType('photo');

      // Assert
      expect(activityOps.length, equals(1));
      expect(activityOps.first.id, equals('activity-sync-op'));
      expect(photoOps.length, equals(1));
      expect(photoOps.first.id, equals('photo-sync-op'));
    });

    test('should get sync operation by entity', () async {
      // Arrange
      final syncOperation = SyncQueueEntity(
        id: 'specific-sync-op',
        entityType: 'activity',
        entityId: 'activity-1',
        operation: 'update',
        payload: '{}',
        priority: 0,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastAttemptAt: null,
        nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
        lastError: null,
      );

      await syncQueueDao.createSyncOperation(syncOperation);

      // Act
      final retrieved = await syncQueueDao.getSyncOperationByEntity(
        entityType: 'activity',
        entityId: 'activity-1',
        operation: 'update',
      );

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('specific-sync-op'));
    });

    test('should update sync operation retry information', () async {
      // Arrange
      final syncOperation = SyncQueueEntity(
        id: 'retry-sync-op',
        entityType: 'activity',
        entityId: 'activity-1',
        operation: 'create',
        payload: '{}',
        priority: 0,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastAttemptAt: null,
        nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
        lastError: null,
      );

      await syncQueueDao.createSyncOperation(syncOperation);

      // Act
      final nextAttempt = DateTime.now().add(const Duration(minutes: 5));
      await syncQueueDao.updateSyncOperationRetry(
        id: 'retry-sync-op',
        retryCount: 1,
        nextAttemptAt: nextAttempt,
        lastError: 'Connection timeout',
      );

      // Assert
      final retrieved = await syncQueueDao.getSyncOperationById('retry-sync-op');
      expect(retrieved!.retryCount, equals(1));
      expect(retrieved.lastError, equals('Connection timeout'));
      expect(retrieved.lastAttemptAt, isNotNull);
    });

    test('should create sync operations in batch', () async {
      // Arrange
      final syncOperations = List.generate(5, (index) => SyncQueueEntity(
        id: 'batch-sync-op-$index',
        entityType: 'activity',
        entityId: 'activity-$index',
        operation: 'create',
        payload: '{}',
        priority: 0,
        retryCount: 0,
        maxRetries: 3,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastAttemptAt: null,
        nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
        lastError: null,
      ));

      // Act
      await syncQueueDao.createSyncOperationsBatch(syncOperations);

      // Assert
      final count = await syncQueueDao.getSyncOperationsCount();
      expect(count, equals(5));
    });

    test('should delete sync operations for entity', () async {
      // Arrange
      final syncOperations = [
        SyncQueueEntity(
          id: 'delete-sync-op-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'keep-sync-op-1',
          entityType: 'activity',
          entityId: 'activity-2',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        ),
      ];

      for (final syncOp in syncOperations) {
        await syncQueueDao.createSyncOperation(syncOp);
      }

      // Act
      await syncQueueDao.deleteSyncOperationsForEntity(
        entityType: 'activity',
        entityId: 'activity-1',
      );

      // Assert
      final remaining = await syncQueueDao.getSyncOperationsByType('activity');
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('keep-sync-op-1'));
    });

    test('should create entity sync operations with helper methods', () async {
      // Act
      final createOp = syncQueueDao.createEntitySyncOperation(
        id: 'create-helper-op',
        entityType: 'activity',
        entityId: 'activity-1',
        payload: '{"title": "New Activity"}',
        priority: 1,
      );

      final updateOp = syncQueueDao.updateEntitySyncOperation(
        id: 'update-helper-op',
        entityType: 'activity',
        entityId: 'activity-1',
        payload: '{"title": "Updated Activity"}',
        priority: 2,
      );

      final deleteOp = syncQueueDao.deleteEntitySyncOperation(
        id: 'delete-helper-op',
        entityType: 'activity',
        entityId: 'activity-1',
        priority: 3,
      );

      await syncQueueDao.createSyncOperation(createOp);
      await syncQueueDao.createSyncOperation(updateOp);
      await syncQueueDao.createSyncOperation(deleteOp);

      // Assert
      final createRetrieved = await syncQueueDao.getSyncOperationById('create-helper-op');
      expect(createRetrieved!.operation, equals('create'));
      expect(createRetrieved.priority, equals(1));

      final updateRetrieved = await syncQueueDao.getSyncOperationById('update-helper-op');
      expect(updateRetrieved!.operation, equals('update'));
      expect(updateRetrieved.priority, equals(2));

      final deleteRetrieved = await syncQueueDao.getSyncOperationById('delete-helper-op');
      expect(deleteRetrieved!.operation, equals('delete'));
      expect(deleteRetrieved.priority, equals(3));
      expect(deleteRetrieved.payload, equals('{}'));
    });

    test('should get pending sync operations count', () async {
      // Arrange
      final now = DateTime.now();
      final syncOperations = [
        SyncQueueEntity(
          id: 'pending-op-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{}',
          priority: 0,
          retryCount: 0,
          maxRetries: 3,
          createdAt: now.millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: null,
        ),
        SyncQueueEntity(
          id: 'failed-op-1',
          entityType: 'photo',
          entityId: 'photo-1',
          operation: 'update',
          payload: '{}',
          priority: 0,
          retryCount: 3,
          maxRetries: 3,
          createdAt: now.millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: now.millisecondsSinceEpoch,
          lastError: 'Failed',
        ),
      ];

      for (final syncOp in syncOperations) {
        await syncQueueDao.createSyncOperation(syncOp);
      }

      // Act
      final pendingCount = await syncQueueDao.getPendingSyncOperationsCount();
      final totalCount = await syncQueueDao.getSyncOperationsCount();

      // Assert
      expect(pendingCount, equals(1));
      expect(totalCount, equals(2));
    });
  });
}