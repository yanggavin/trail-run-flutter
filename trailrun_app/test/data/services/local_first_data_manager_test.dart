import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/data/services/local_first_data_manager.dart';
import '../../../lib/data/services/sync_service.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/data/database/daos/activity_dao.dart';
import '../../../lib/data/database/daos/photo_dao.dart';
import '../../../lib/data/database/daos/track_point_dao.dart';
import '../../../lib/data/database/daos/split_dao.dart';
import '../../../lib/domain/models/models.dart';
import '../../../lib/domain/enums/enums.dart';

@GenerateMocks([
  TrailRunDatabase,
  ActivityDao,
  PhotoDao,
  TrackPointDao,
  SplitDao,
  SyncService,
])
import 'local_first_data_manager_test.mocks.dart';

void main() {
  group('LocalFirstDataManager', () {
    late LocalFirstDataManager dataManager;
    late MockTrailRunDatabase mockDatabase;
    late MockActivityDao mockActivityDao;
    late MockPhotoDao mockPhotoDao;
    late MockTrackPointDao mockTrackPointDao;
    late MockSplitDao mockSplitDao;
    late MockSyncService mockSyncService;

    setUp(() {
      dataManager = LocalFirstDataManager();
      mockDatabase = MockTrailRunDatabase();
      mockActivityDao = MockActivityDao();
      mockPhotoDao = MockPhotoDao();
      mockTrackPointDao = MockTrackPointDao();
      mockSplitDao = MockSplitDao();
      mockSyncService = MockSyncService();

      // Setup database mocks
      when(mockDatabase.activityDao).thenReturn(mockActivityDao);
      when(mockDatabase.photoDao).thenReturn(mockPhotoDao);
      when(mockDatabase.trackPointDao).thenReturn(mockTrackPointDao);
      when(mockDatabase.splitDao).thenReturn(mockSplitDao);
    });

    group('initialization', () {
      test('should initialize with database and sync service', () async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );

        expect(dataManager.isOfflineCapable, isTrue);
      });

      test('should throw error when not initialized', () async {
        expect(
          () => dataManager.createActivity(createTestActivity()),
          throwsStateError,
        );
      });
    });

    group('activity operations', () {
      setUp(() async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );
      });

      test('should create activity with immediate persistence and sync queuing', () async {
        final activity = createTestActivity();
        
        when(mockActivityDao.insertActivity(any))
            .thenAnswer((_) async => 1);
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
          priority: any,
        )).thenAnswer((_) async {});

        final result = await dataManager.createActivity(activity);

        expect(result.syncState, equals(SyncState.local));
        verify(mockActivityDao.insertActivity(any)).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'activity',
          entityId: activity.id,
          operation: 'create',
          data: any,
          priority: 1,
        )).called(1);
      });

      test('should update activity and queue for sync', () async {
        final activity = createTestActivity().copyWith(syncState: SyncState.synced);
        
        when(mockActivityDao.updateActivity(any))
            .thenAnswer((_) async => 1);
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
        )).thenAnswer((_) async {});

        final result = await dataManager.updateActivity(activity);

        expect(result.syncState, equals(SyncState.pending));
        verify(mockActivityDao.updateActivity(any)).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'activity',
          entityId: activity.id,
          operation: 'update',
          data: any,
        )).called(1);
      });

      test('should delete activity and queue for sync if previously synced', () async {
        final activityEntity = ActivityEntity(
          id: 'test-activity',
          startTime: DateTime.now().millisecondsSinceEpoch,
          endTime: null,
          distanceMeters: 1000.0,
          durationSeconds: 600,
          elevationGainMeters: 50.0,
          averagePaceSecondsPerKm: 360.0,
          title: 'Test Activity',
          notes: null,
          privacyLevel: PrivacyLevel.private.index,
          coverPhotoId: null,
          syncState: SyncState.synced.index,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        when(mockActivityDao.getActivityById('test-activity'))
            .thenAnswer((_) async => activityEntity);
        when(mockActivityDao.deleteActivity('test-activity'))
            .thenAnswer((_) async => 1);
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
        )).thenAnswer((_) async {});

        await dataManager.deleteActivity('test-activity');

        verify(mockActivityDao.deleteActivity('test-activity')).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'activity',
          entityId: 'test-activity',
          operation: 'delete',
          data: {'id': 'test-activity'},
        )).called(1);
      });

      test('should get activity by ID', () async {
        final activityEntity = createTestActivityEntity();
        
        when(mockActivityDao.getActivityById('test-activity'))
            .thenAnswer((_) async => activityEntity);

        final result = await dataManager.getActivity('test-activity');

        expect(result, isNotNull);
        expect(result!.id, equals('test-activity'));
        verify(mockActivityDao.getActivityById('test-activity')).called(1);
      });

      test('should get activities with pagination', () async {
        final activityEntities = [createTestActivityEntity()];
        
        when(mockActivityDao.getActivities(limit: 20, offset: 0))
            .thenAnswer((_) async => activityEntities);

        final result = await dataManager.getActivities();

        expect(result, hasLength(1));
        verify(mockActivityDao.getActivities(limit: 20, offset: 0)).called(1);
      });
    });

    group('photo operations', () {
      setUp(() async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );
      });

      test('should create photo with immediate persistence and sync queuing', () async {
        final photo = createTestPhoto();
        
        when(mockPhotoDao.insertPhoto(any))
            .thenAnswer((_) async => 1);
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
          priority: any,
        )).thenAnswer((_) async {});

        final result = await dataManager.createPhoto(photo);

        expect(result.syncState, equals(SyncState.local));
        verify(mockPhotoDao.insertPhoto(any)).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'photo',
          entityId: photo.id,
          operation: 'create',
          data: any,
          priority: 2,
        )).called(1);
      });
    });

    group('track point operations', () {
      setUp(() async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );
      });

      test('should create track point with immediate persistence and sync queuing', () async {
        final trackPoint = createTestTrackPoint();
        
        when(mockTrackPointDao.insertTrackPoint(any))
            .thenAnswer((_) async => 1);
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
          priority: any,
        )).thenAnswer((_) async {});

        final result = await dataManager.createTrackPoint(trackPoint);

        expect(result.id, equals(trackPoint.id));
        verify(mockTrackPointDao.insertTrackPoint(any)).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'track_point',
          entityId: trackPoint.id,
          operation: 'create',
          data: any,
          priority: 0,
        )).called(1);
      });

      test('should create track points in batch', () async {
        final trackPoints = [createTestTrackPoint(), createTestTrackPoint()];
        
        when(mockTrackPointDao.insertTrackPointsBatch(any))
            .thenAnswer((_) async {});
        when(mockSyncService.queueEntitySync(
          entityType: any,
          entityId: any,
          operation: any,
          data: any,
          priority: any,
        )).thenAnswer((_) async {});

        await dataManager.createTrackPointsBatch(trackPoints);

        verify(mockTrackPointDao.insertTrackPointsBatch(any)).called(1);
        verify(mockSyncService.queueEntitySync(
          entityType: 'track_point',
          entityId: any,
          operation: 'create',
          data: any,
          priority: 0,
        )).called(2);
      });
    });

    group('sync management', () {
      setUp(() async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );
      });

      test('should trigger activity sync', () async {
        when(mockSyncService.syncActivity('test-activity'))
            .thenAnswer((_) async {});

        await dataManager.syncActivity('test-activity');

        verify(mockSyncService.syncActivity('test-activity')).called(1);
      });

      test('should trigger sync all', () async {
        when(mockSyncService.syncAll()).thenAnswer((_) async {});

        await dataManager.syncAll();

        verify(mockSyncService.syncAll()).called(1);
      });

      test('should provide sync status stream', () {
        when(mockSyncService.syncStatusStream)
            .thenAnswer((_) => Stream.value(SyncStatus.idle));

        final stream = dataManager.syncStatusStream;

        expect(stream, isA<Stream<SyncStatus>>());
      });

      test('should resolve conflicts', () async {
        final conflict = SyncConflict(
          id: 'conflict-1',
          entityType: 'activity',
          entityId: 'activity-1',
          operation: 'update',
          localData: {'title': 'Local'},
          serverData: {'title': 'Server'},
          timestamp: DateTime.now(),
        );

        when(mockSyncService.resolveConflict(conflict, preserveLocal: true))
            .thenAnswer((_) async {});

        await dataManager.resolveConflict(conflict);

        verify(mockSyncService.resolveConflict(conflict, preserveLocal: true)).called(1);
      });
    });

    group('offline data statistics', () {
      setUp(() async {
        await dataManager.initialize(
          database: mockDatabase,
          syncService: mockSyncService,
        );
      });

      test('should get offline data statistics', () async {
        when(mockActivityDao.getActivitiesCount()).thenAnswer((_) async => 5);
        when(mockPhotoDao.getPhotosCount()).thenAnswer((_) async => 10);
        when(mockTrackPointDao.getTrackPointsCount()).thenAnswer((_) async => 1000);

        final stats = await dataManager.getOfflineDataStats();

        expect(stats.activityCount, equals(5));
        expect(stats.photoCount, equals(10));
        expect(stats.trackPointCount, equals(1000));
      });
    });
  });
}

// Helper functions for creating test data
Activity createTestActivity() {
  return Activity(
    id: 'test-activity',
    startTime: DateTime.now(),
    endTime: null,
    distanceMeters: 1000.0,
    duration: const Duration(minutes: 10),
    elevationGainMeters: 50.0,
    averagePaceSecondsPerKm: 360.0,
    title: 'Test Activity',
    notes: null,
    privacy: PrivacyLevel.private,
    coverPhotoId: null,
    syncState: SyncState.local,
    trackPoints: const [],
    photos: const [],
    splits: const [],
  );
}

ActivityEntity createTestActivityEntity() {
  return ActivityEntity(
    id: 'test-activity',
    startTime: DateTime.now().millisecondsSinceEpoch,
    endTime: null,
    distanceMeters: 1000.0,
    durationSeconds: 600,
    elevationGainMeters: 50.0,
    averagePaceSecondsPerKm: 360.0,
    title: 'Test Activity',
    notes: null,
    privacyLevel: PrivacyLevel.private.index,
    coverPhotoId: null,
    syncState: SyncState.local.index,
    createdAt: DateTime.now().millisecondsSinceEpoch,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
}

Photo createTestPhoto() {
  return Photo(
    id: 'test-photo',
    activityId: 'test-activity',
    timestamp: DateTime.now(),
    latitude: 37.7749,
    longitude: -122.4194,
    filePath: '/path/to/photo.jpg',
    thumbnailPath: '/path/to/thumbnail.jpg',
    hasExifData: true,
    curationScore: 0.8,
    syncState: SyncState.local,
  );
}

TrackPoint createTestTrackPoint() {
  return TrackPoint(
    id: 'test-trackpoint',
    activityId: 'test-activity',
    timestamp: DateTime.now(),
    latitude: 37.7749,
    longitude: -122.4194,
    elevation: 100.0,
    accuracy: 5.0,
    source: LocationSource.gps,
    sequence: 1,
  );
}