import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../lib/data/database/database.dart';
import '../../lib/data/services/sync_service.dart';
import '../../lib/data/services/local_first_data_manager.dart';
import '../../lib/data/services/network_connectivity_service.dart';
import '../../lib/domain/models/models.dart';
import '../../lib/domain/enums/enums.dart';

void main() {
  group('Offline Data Management Integration', () {
    late TrailRunDatabase database;
    late SyncService syncService;
    late LocalFirstDataManager dataManager;
    late String tempDir;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create temporary directory for test database
      tempDir = Directory.systemTemp.createTempSync('trailrun_test_').path;
      
      // Initialize database
      database = TrailRunDatabase.forTesting(path.join(tempDir, 'test.db'));
      
      // Initialize sync service
      syncService = SyncService();
      await syncService.initialize(database: database);
      
      // Initialize data manager
      dataManager = LocalFirstDataManager();
      await dataManager.initialize(
        database: database,
        syncService: syncService,
      );
    });

    tearDown(() async {
      await database.close();
      syncService.dispose();
      
      // Clean up temporary directory
      try {
        Directory(tempDir).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('local-first operations', () {
      test('should create activity with immediate local persistence', () async {
        final activity = createTestActivity();
        
        final result = await dataManager.createActivity(activity);
        
        expect(result.syncState, equals(SyncState.local));
        
        // Verify it's persisted locally
        final retrieved = await dataManager.getActivity(activity.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(activity.id));
        expect(retrieved.title, equals(activity.title));
      });

      test('should update activity and change sync state', () async {
        // Create activity
        final activity = createTestActivity();
        await dataManager.createActivity(activity);
        
        // Simulate it being synced
        final syncedActivity = activity.copyWith(syncState: SyncState.synced);
        await dataManager.updateActivity(syncedActivity);
        
        // Update it again
        final updatedActivity = syncedActivity.copyWith(title: 'Updated Title');
        final result = await dataManager.updateActivity(updatedActivity);
        
        expect(result.syncState, equals(SyncState.pending));
        expect(result.title, equals('Updated Title'));
      });

      test('should handle offline photo creation', () async {
        final photo = createTestPhoto();
        
        final result = await dataManager.createPhoto(photo);
        
        expect(result.syncState, equals(SyncState.local));
        
        // Verify it's persisted locally
        final photos = await dataManager.getPhotosForActivity(photo.activityId);
        expect(photos, hasLength(1));
        expect(photos.first.id, equals(photo.id));
      });

      test('should handle batch track point creation', () async {
        final trackPoints = List.generate(10, (index) => TrackPoint(
          id: 'trackpoint-$index',
          activityId: 'test-activity',
          timestamp: DateTime.now().add(Duration(seconds: index)),
          latitude: 37.7749 + (index * 0.001),
          longitude: -122.4194 + (index * 0.001),
          elevation: 100.0 + index,
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));
        
        await dataManager.createTrackPointsBatch(trackPoints);
        
        // Verify all track points are persisted
        final retrieved = await dataManager.getTrackPointsForActivity('test-activity');
        expect(retrieved, hasLength(10));
      });
    });

    group('sync queue management', () {
      test('should queue operations for sync', () async {
        final activity = createTestActivity();
        await dataManager.createActivity(activity);
        
        // Check sync queue
        final pendingOps = await database.syncQueueDao.getPendingSyncOperations();
        expect(pendingOps, hasLength(1));
        expect(pendingOps.first.entityType, equals('activity'));
        expect(pendingOps.first.operation, equals('create'));
      });

      test('should handle multiple operations on same entity', () async {
        final activity = createTestActivity();
        
        // Create activity
        await dataManager.createActivity(activity);
        
        // Update activity
        final updatedActivity = activity.copyWith(title: 'Updated');
        await dataManager.updateActivity(updatedActivity);
        
        // Check sync queue has both operations
        final pendingOps = await database.syncQueueDao.getPendingSyncOperations();
        expect(pendingOps.length, greaterThanOrEqualTo(2));
      });

      test('should prioritize operations correctly', () async {
        final activity = createTestActivity();
        final photo = createTestPhoto();
        final trackPoint = createTestTrackPoint();
        
        // Create entities with different priorities
        await dataManager.createActivity(activity); // Priority 1
        await dataManager.createPhoto(photo); // Priority 2
        await dataManager.createTrackPoint(trackPoint); // Priority 0
        
        final pendingOps = await database.syncQueueDao.getPendingSyncOperations();
        expect(pendingOps, hasLength(3));
        
        // Should be ordered by priority (desc) then creation time (asc)
        expect(pendingOps.first.priority, greaterThanOrEqualTo(pendingOps.last.priority));
      });
    });

    group('offline data statistics', () {
      test('should provide accurate offline data statistics', () async {
        // Create test data
        final activity1 = createTestActivity();
        final activity2 = createTestActivity().copyWith(id: 'activity-2');
        final photo1 = createTestPhoto();
        final photo2 = createTestPhoto().copyWith(id: 'photo-2');
        final trackPoints = List.generate(5, (i) => createTestTrackPoint().copyWith(id: 'tp-$i'));
        
        await dataManager.createActivity(activity1);
        await dataManager.createActivity(activity2);
        await dataManager.createPhoto(photo1);
        await dataManager.createPhoto(photo2);
        await dataManager.createTrackPointsBatch(trackPoints);
        
        final stats = await dataManager.getOfflineDataStats();
        
        expect(stats.activityCount, equals(2));
        expect(stats.photoCount, equals(2));
        expect(stats.trackPointCount, equals(5));
      });
    });

    group('data consistency', () {
      test('should maintain data consistency during concurrent operations', () async {
        final activity = createTestActivity();
        
        // Simulate concurrent operations
        final futures = <Future>[];
        
        // Create activity
        futures.add(dataManager.createActivity(activity));
        
        // Create photos for the activity
        for (int i = 0; i < 5; i++) {
          final photo = createTestPhoto().copyWith(id: 'photo-$i');
          futures.add(dataManager.createPhoto(photo));
        }
        
        // Create track points for the activity
        final trackPoints = List.generate(10, (i) => createTestTrackPoint().copyWith(id: 'tp-$i'));
        futures.add(dataManager.createTrackPointsBatch(trackPoints));
        
        await Future.wait(futures);
        
        // Verify data consistency
        final retrievedActivity = await dataManager.getActivity(activity.id);
        final photos = await dataManager.getPhotosForActivity(activity.id);
        final trackPointsRetrieved = await dataManager.getTrackPointsForActivity(activity.id);
        
        expect(retrievedActivity, isNotNull);
        expect(photos, hasLength(5));
        expect(trackPointsRetrieved, hasLength(10));
      });
    });

    group('error handling', () {
      test('should handle database errors gracefully', () async {
        // Close database to simulate error
        await database.close();
        
        final activity = createTestActivity();
        
        // Should throw appropriate error
        expect(
          () => dataManager.createActivity(activity),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('stream operations', () {
      test('should provide reactive data streams', () async {
        final activity = createTestActivity();
        
        // Start watching before creating
        final activityStream = dataManager.watchActivity(activity.id);
        final activitiesStream = dataManager.watchActivities();
        
        expect(activityStream, isA<Stream<Activity?>>());
        expect(activitiesStream, isA<Stream<List<Activity>>>());
        
        // Create activity and verify stream updates
        await dataManager.createActivity(activity);
        
        // Note: In a real test, we'd verify stream emissions
        // For now, we just verify the streams are created
      });
    });
  });
}

// Helper functions for creating test data
Activity createTestActivity() {
  return Activity(
    id: 'test-activity-${DateTime.now().millisecondsSinceEpoch}',
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

Photo createTestPhoto() {
  return Photo(
    id: 'test-photo-${DateTime.now().millisecondsSinceEpoch}',
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
    id: 'test-trackpoint-${DateTime.now().millisecondsSinceEpoch}',
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