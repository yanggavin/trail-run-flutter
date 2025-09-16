import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

import '../../../lib/data/services/sync_service.dart';
import '../../../lib/data/services/network_connectivity_service.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/data/database/daos/sync_queue_dao.dart';

@GenerateMocks([
  NetworkConnectivityService,
  TrailRunDatabase,
  SyncQueueDao,
  Dio,
])
import 'sync_service_test.mocks.dart';

void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockNetworkConnectivityService mockNetworkService;
    late MockTrailRunDatabase mockDatabase;
    late MockSyncQueueDao mockSyncQueueDao;
    late MockDio mockDio;

    setUp(() {
      mockNetworkService = MockNetworkConnectivityService();
      mockDatabase = MockTrailRunDatabase();
      mockSyncQueueDao = MockSyncQueueDao();
      mockDio = MockDio();

      syncService = SyncService();
      
      // Setup default mocks
      when(mockDatabase.syncQueueDao).thenReturn(mockSyncQueueDao);
      when(mockNetworkService.isConnected).thenReturn(true);
      when(mockNetworkService.connectivityStream).thenAnswer(
        (_) => Stream.value(true),
      );
    });

    tearDown(() {
      syncService.dispose();
    });

    group('initialization', () {
      test('should initialize with database and network service', () async {
        await syncService.initialize(database: mockDatabase);
        
        verify(mockDatabase.syncQueueDao).called(1);
      });
    });

    group('sync operations', () {
      setUp(() async {
        await syncService.initialize(database: mockDatabase);
      });

      test('should not sync when network is unavailable', () async {
        when(mockNetworkService.isConnected).thenReturn(false);
        
        await syncService.syncAll();
        
        verifyNever(mockSyncQueueDao.getPendingSyncOperations());
      });

      test('should sync pending operations when network is available', () async {
        final mockOperations = [
          SyncQueueEntity(
            id: 'test-1',
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
          ),
        ];

        when(mockSyncQueueDao.getPendingSyncOperations())
            .thenAnswer((_) async => mockOperations);
        when(mockSyncQueueDao.deleteSyncOperation(any))
            .thenAnswer((_) async => 1);

        await syncService.syncAll();

        verify(mockSyncQueueDao.getPendingSyncOperations()).called(1);
      });

      test('should handle sync failures with exponential backoff', () async {
        final mockOperation = SyncQueueEntity(
          id: 'test-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          payload: '{"id": "activity-1", "title": "Test Activity"}',
          priority: 1,
          retryCount: 1,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        );

        when(mockSyncQueueDao.getPendingSyncOperations())
            .thenAnswer((_) async => [mockOperation]);
        when(mockSyncQueueDao.updateSyncOperationRetry(
          id: any,
          retryCount: any,
          nextAttemptAt: any,
          lastError: any,
        )).thenAnswer((_) async => 1);

        await syncService.syncAll();

        verify(mockSyncQueueDao.updateSyncOperationRetry(
          id: 'test-1',
          retryCount: 2,
          nextAttemptAt: any,
          lastError: any,
        )).called(1);
      });
    });

    group('conflict resolution', () {
      setUp(() async {
        await syncService.initialize(database: mockDatabase);
      });

      test('should handle sync conflicts', () async {
        final conflict = SyncConflict(
          id: 'conflict-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'update',
          localData: {'title': 'Local Title'},
          serverData: {'title': 'Server Title'},
          timestamp: DateTime.now(),
        );

        when(mockSyncQueueDao.deleteSyncOperationsForEntity(
          entityType: any,
          entityId: any,
        )).thenAnswer((_) async => 1);

        await syncService.resolveConflict(conflict);

        verify(mockSyncQueueDao.deleteSyncOperationsForEntity(
          entityType: 'activity',
          entityId: 'activity-1',
        )).called(1);
      });

      test('should preserve local changes when resolving conflicts', () async {
        final conflict = SyncConflict(
          id: 'conflict-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'update',
          localData: {'title': 'Local Title'},
          serverData: {'title': 'Server Title'},
          timestamp: DateTime.now(),
        );

        when(mockSyncQueueDao.createSyncOperation(any))
            .thenAnswer((_) async => 1);
        when(mockSyncQueueDao.deleteSyncOperationsForEntity(
          entityType: any,
          entityId: any,
        )).thenAnswer((_) async => 1);

        await syncService.resolveConflict(conflict, preserveLocal: true);

        verify(mockSyncQueueDao.createSyncOperation(any)).called(1);
      });
    });

    group('queue management', () {
      setUp(() async {
        await syncService.initialize(database: mockDatabase);
      });

      test('should queue entity for sync', () async {
        when(mockSyncQueueDao.createSyncOperation(any))
            .thenAnswer((_) async => 1);

        await syncService.queueEntitySync(
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'create',
          data: {'title': 'Test Activity'},
        );

        verify(mockSyncQueueDao.createSyncOperation(any)).called(1);
      });
    });

    group('status monitoring', () {
      test('should provide sync status stream', () {
        expect(syncService.syncStatusStream, isA<Stream<SyncStatus>>());
      });

      test('should provide conflict stream', () {
        expect(syncService.conflictStream, isA<Stream<SyncConflict>>());
      });

      test('should update sync status during operations', () async {
        await syncService.initialize(database: mockDatabase);
        
        final statusStream = syncService.syncStatusStream;
        expect(statusStream, isA<Stream<SyncStatus>>());
      });
    });
  });
}