import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import '../../../lib/data/database/database.dart';
import '../../../lib/data/repositories/activity_repository_impl.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/models/track_point.dart';
import '../../../lib/domain/enums/privacy_level.dart';
import '../../../lib/domain/enums/sync_state.dart';
import '../../../lib/domain/enums/location_source.dart';
import '../../../lib/domain/value_objects/measurement_units.dart';
import '../../../lib/domain/value_objects/timestamp.dart';
import '../../../lib/domain/value_objects/coordinates.dart';

void main() {
  group('ActivityRepositoryImpl', () {
    late TrailRunDatabase database;
    late ActivityRepositoryImpl repository;

    setUp(() async {
      database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
      repository = ActivityRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    group('Activity CRUD Operations', () {
      test('should create and retrieve activity', () async {
        // Arrange
        final activity = Activity(
          id: 'test_activity_1',
          startTime: Timestamp(DateTime.now()),
          title: 'Test Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        // Act
        final createdActivity = await repository.createActivity(activity);
        final retrievedActivity = await repository.getActivity(activity.id);

        // Assert
        expect(createdActivity.id, equals(activity.id));
        expect(retrievedActivity, isNotNull);
        expect(retrievedActivity!.id, equals(activity.id));
        expect(retrievedActivity.title, equals('Test Run'));
        expect(retrievedActivity.privacy, equals(PrivacyLevel.private));
      });

      test('should update existing activity', () async {
        // Arrange
        final activity = Activity(
          id: 'test_activity_2',
          startTime: Timestamp(DateTime.now()),
          title: 'Original Title',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(activity);

        // Act
        final updatedActivity = activity.copyWith(
          title: 'Updated Title',
          endTime: Timestamp(DateTime.now().add(const Duration(hours: 1))),
          distance: Distance.meters(5000),
          syncState: SyncState.pending,
        );

        await repository.updateActivity(updatedActivity);
        final retrievedActivity = await repository.getActivity(activity.id);

        // Assert
        expect(retrievedActivity!.title, equals('Updated Title'));
        expect(retrievedActivity.endTime, isNotNull);
        expect(retrievedActivity.distance.meters, equals(5000));
        expect(retrievedActivity.syncState, equals(SyncState.pending));
      });

      test('should delete activity and associated data', () async {
        // Arrange
        final activity = Activity(
          id: 'test_activity_3',
          startTime: Timestamp(DateTime.now()),
          title: 'To Delete',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(activity);

        // Add some track points
        final trackPoint = TrackPoint(
          id: 'tp_1',
          activityId: activity.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        await repository.addTrackPoint(activity.id, trackPoint);

        // Act
        await repository.deleteActivity(activity.id);

        // Assert
        final retrievedActivity = await repository.getActivity(activity.id);
        expect(retrievedActivity, isNull);

        final trackPoints = await repository.getTrackPoints(activity.id);
        expect(trackPoints, isEmpty);
      });
    });

    group('Active Activity Management', () {
      test('should get active activity', () async {
        // Arrange
        final completedActivity = Activity(
          id: 'completed_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(hours: 2))),
          endTime: Timestamp(DateTime.now().subtract(const Duration(hours: 1))),
          title: 'Completed Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        final activeActivity = Activity(
          id: 'active_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(minutes: 30))),
          title: 'Active Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(completedActivity);
        await repository.createActivity(activeActivity);

        // Act
        final retrievedActiveActivity = await repository.getActiveActivity();

        // Assert
        expect(retrievedActiveActivity, isNotNull);
        expect(retrievedActiveActivity!.id, equals('active_activity'));
        expect(retrievedActiveActivity.isInProgress, isTrue);
      });

      test('should return null when no active activity', () async {
        // Arrange
        final completedActivity = Activity(
          id: 'completed_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(hours: 2))),
          endTime: Timestamp(DateTime.now().subtract(const Duration(hours: 1))),
          title: 'Completed Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(completedActivity);

        // Act
        final activeActivity = await repository.getActiveActivity();

        // Assert
        expect(activeActivity, isNull);
      });
    });

    group('Track Point Management', () {
      late Activity testActivity;

      setUp(() async {
        testActivity = Activity(
          id: 'track_point_test_activity',
          startTime: Timestamp(DateTime.now()),
          title: 'Track Point Test',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );
        await repository.createActivity(testActivity);
      });

      test('should add single track point', () async {
        // Arrange
        final trackPoint = TrackPoint(
          id: 'tp_single',
          activityId: testActivity.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        // Act
        await repository.addTrackPoint(testActivity.id, trackPoint);

        // Assert
        final trackPoints = await repository.getTrackPoints(testActivity.id);
        expect(trackPoints, hasLength(1));
        expect(trackPoints.first.id, equals('tp_single'));
        expect(trackPoints.first.coordinates.latitude, equals(37.7749));
      });

      test('should add multiple track points in batch', () async {
        // Arrange
        final trackPoints = List.generate(10, (index) => TrackPoint(
          id: 'tp_batch_$index',
          activityId: testActivity.id,
          timestamp: Timestamp(DateTime.now().add(Duration(seconds: index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.001),
            longitude: -122.4194 + (index * 0.001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        // Act
        await repository.addTrackPoints(testActivity.id, trackPoints);

        // Assert
        final retrievedPoints = await repository.getTrackPoints(testActivity.id);
        expect(retrievedPoints, hasLength(10));
        expect(retrievedPoints.first.sequence, equals(0));
        expect(retrievedPoints.last.sequence, equals(9));
      });

      test('should update activity statistics when adding track points', () async {
        // Arrange
        final trackPoints = [
          TrackPoint(
            id: 'tp_stats_1',
            activityId: testActivity.id,
            timestamp: Timestamp(DateTime.now()),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 0,
          ),
          TrackPoint(
            id: 'tp_stats_2',
            activityId: testActivity.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 60))),
            coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4294, elevation: 120),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          ),
        ];

        // Act
        await repository.addTrackPoints(testActivity.id, trackPoints);

        // Assert
        final updatedActivity = await repository.getActivity(testActivity.id);
        expect(updatedActivity!.distance.meters, greaterThan(0));
        expect(updatedActivity.elevationGain.meters, equals(20));
      });

      test('should get track points in time range', () async {
        // Arrange
        final baseTime = DateTime.now();
        final trackPoints = List.generate(5, (index) => TrackPoint(
          id: 'tp_range_$index',
          activityId: testActivity.id,
          timestamp: Timestamp(baseTime.add(Duration(minutes: index * 10))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.001),
            longitude: -122.4194 + (index * 0.001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        await repository.addTrackPoints(testActivity.id, trackPoints);

        // Act
        final rangePoints = await repository.getTrackPointsInRange(
          testActivity.id,
          baseTime.add(const Duration(minutes: 15)),
          baseTime.add(const Duration(minutes: 35)),
        );

        // Assert
        expect(rangePoints, hasLength(2)); // Points at 20 and 30 minutes
        expect(rangePoints.first.sequence, equals(2));
        expect(rangePoints.last.sequence, equals(3));
      });
    });

    group('Activity Statistics', () {
      test('should calculate activity statistics', () async {
        // Arrange
        final activities = List.generate(3, (index) => Activity(
          id: 'stats_activity_$index',
          startTime: Timestamp(DateTime.now().subtract(Duration(days: index))),
          endTime: Timestamp(DateTime.now().subtract(Duration(days: index)).add(const Duration(hours: 1))),
          title: 'Stats Test $index',
          distance: Distance.meters(5000 + (index * 1000)),
          elevationGain: Elevation.meters(100 + (index * 50)),
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        ));

        for (final activity in activities) {
          await repository.createActivity(activity);
        }

        // Act
        final stats = await repository.getActivityStats();

        // Assert
        expect(stats.totalActivities, equals(3));
        expect(stats.totalDistance, equals(18000)); // 5000 + 6000 + 7000
        expect(stats.totalElevationGain, equals(450)); // 100 + 150 + 200
        expect(stats.averageDistance, equals(6000));
        expect(stats.totalDuration, equals(const Duration(hours: 3)));
      });

      test('should calculate statistics for date range', () async {
        // Arrange
        final oldActivity = Activity(
          id: 'old_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(days: 10))),
          endTime: Timestamp(DateTime.now().subtract(const Duration(days: 10)).add(const Duration(hours: 1))),
          title: 'Old Run',
          distance: Distance.meters(3000),
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        final recentActivity = Activity(
          id: 'recent_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(days: 1))),
          endTime: Timestamp(DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 1))),
          title: 'Recent Run',
          distance: Distance.meters(5000),
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(oldActivity);
        await repository.createActivity(recentActivity);

        // Act
        final stats = await repository.getActivityStats(
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          endDate: DateTime.now(),
        );

        // Assert
        expect(stats.totalActivities, equals(1));
        expect(stats.totalDistance, equals(5000));
      });
    });

    group('Sync Management', () {
      test('should get activities needing sync', () async {
        // Arrange
        final activities = [
          Activity(
            id: 'synced_activity',
            startTime: Timestamp(DateTime.now()),
            title: 'Synced',
            privacy: PrivacyLevel.private,
            syncState: SyncState.synced,
          ),
          Activity(
            id: 'pending_activity',
            startTime: Timestamp(DateTime.now()),
            title: 'Pending',
            privacy: PrivacyLevel.private,
            syncState: SyncState.pending,
          ),
          Activity(
            id: 'failed_activity',
            startTime: Timestamp(DateTime.now()),
            title: 'Failed',
            privacy: PrivacyLevel.private,
            syncState: SyncState.failed,
          ),
        ];

        for (final activity in activities) {
          await repository.createActivity(activity);
        }

        // Act
        final needingSync = await repository.getActivitiesNeedingSync();

        // Assert
        expect(needingSync, hasLength(2));
        expect(needingSync.map((a) => a.id), containsAll(['pending_activity', 'failed_activity']));
      });

      test('should mark activity as synced', () async {
        // Arrange
        final activity = Activity(
          id: 'to_sync_activity',
          startTime: Timestamp(DateTime.now()),
          title: 'To Sync',
          privacy: PrivacyLevel.private,
          syncState: SyncState.pending,
        );

        await repository.createActivity(activity);

        // Act
        await repository.markActivitySynced(activity.id);

        // Assert
        final updatedActivity = await repository.getActivity(activity.id);
        expect(updatedActivity!.syncState, equals(SyncState.synced));
      });

      test('should mark activity sync as failed', () async {
        // Arrange
        final activity = Activity(
          id: 'sync_fail_activity',
          startTime: Timestamp(DateTime.now()),
          title: 'Sync Fail',
          privacy: PrivacyLevel.private,
          syncState: SyncState.pending,
        );

        await repository.createActivity(activity);

        // Act
        await repository.markActivitySyncFailed(activity.id, 'Network error');

        // Assert
        final updatedActivity = await repository.getActivity(activity.id);
        expect(updatedActivity!.syncState, equals(SyncState.failed));
      });
    });

    group('Search and Filtering', () {
      setUp(() async {
        final activities = [
          Activity(
            id: 'search_activity_1',
            startTime: Timestamp(DateTime.now()),
            title: 'Morning Trail Run',
            notes: 'Beautiful sunrise',
            privacy: PrivacyLevel.private,
            syncState: SyncState.local,
          ),
          Activity(
            id: 'search_activity_2',
            startTime: Timestamp(DateTime.now()),
            title: 'Evening Jog',
            notes: 'Quick workout',
            privacy: PrivacyLevel.private,
            syncState: SyncState.local,
          ),
          Activity(
            id: 'search_activity_3',
            startTime: Timestamp(DateTime.now()),
            title: 'Long Distance Run',
            notes: 'Marathon training',
            privacy: PrivacyLevel.private,
            syncState: SyncState.local,
          ),
        ];

        for (final activity in activities) {
          await repository.createActivity(activity);
        }
      });

      test('should search activities by title', () async {
        // Act
        final results = await repository.searchActivities('Trail');

        // Assert
        expect(results, hasLength(1));
        expect(results.first.title, equals('Morning Trail Run'));
      });

      test('should search activities by notes', () async {
        // Act
        final results = await repository.searchActivities('training');

        // Assert
        expect(results, hasLength(1));
        expect(results.first.title, equals('Long Distance Run'));
      });

      test('should limit search results', () async {
        // Act
        final results = await repository.searchActivities('Run', limit: 1);

        // Assert
        expect(results, hasLength(1));
      });
    });
  });
}