import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:trailrun_app/data/database/database.dart';
import 'package:trailrun_app/data/database/daos/activity_dao.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';

void main() {
  late TrailRunDatabase database;
  late ActivityDao activityDao;

  setUp(() {
    // Create in-memory database for testing
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
    activityDao = database.activityDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('ActivityDao', () {
    test('should create and retrieve activity', () async {
      // Arrange
      final activity = Activity(
        id: 'test-activity-1',
        startTime: Timestamp.now(),
        title: 'Morning Run',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(100),
        elevationLoss: Elevation.meters(80),
        averagePace: Pace.minutesPerKilometer(5.5),
        notes: 'Great run in the park',
        privacy: PrivacyLevel.private,
        syncState: SyncState.local,
      );

      final entity = activityDao.toEntity(activity);

      // Act
      await activityDao.createActivity(entity);
      final retrieved = await activityDao.getActivityById('test-activity-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-activity-1'));
      expect(retrieved.title, equals('Morning Run'));
      expect(retrieved.distanceMeters, equals(5000.0));
      expect(retrieved.elevationGainMeters, equals(100.0));
      expect(retrieved.elevationLossMeters, equals(80.0));
      expect(retrieved.notes, equals('Great run in the park'));
      expect(retrieved.privacyLevel, equals(PrivacyLevel.private.value));
      expect(retrieved.syncState, equals(SyncState.local.value));
    });

    test('should update activity', () async {
      // Arrange
      final activity = Activity(
        id: 'test-activity-2',
        startTime: Timestamp.now(),
        title: 'Evening Run',
        distance: Distance.kilometers(3.0),
        elevationGain: Elevation.meters(50),
        elevationLoss: Elevation.meters(40),
      );

      final entity = activityDao.toEntity(activity);
      await activityDao.createActivity(entity);

      // Act
      final updatedEntity = entity.copyWith(
        title: 'Updated Evening Run',
        distanceMeters: 4000.0,
        notes: const Value('Added some notes'),
      );
      await activityDao.updateActivity(updatedEntity);

      // Assert
      final retrieved = await activityDao.getActivityById('test-activity-2');
      expect(retrieved!.title, equals('Updated Evening Run'));
      expect(retrieved.distanceMeters, equals(4000.0));
      expect(retrieved.notes, equals('Added some notes'));
    });

    test('should delete activity', () async {
      // Arrange
      final activity = Activity(
        id: 'test-activity-3',
        startTime: Timestamp.now(),
        title: 'Test Run',
      );

      final entity = activityDao.toEntity(activity);
      await activityDao.createActivity(entity);

      // Act
      await activityDao.deleteActivity('test-activity-3');

      // Assert
      final retrieved = await activityDao.getActivityById('test-activity-3');
      expect(retrieved, isNull);
    });

    test('should get active activity', () async {
      // Arrange
      final completedActivity = Activity(
        id: 'completed-activity',
        startTime: Timestamp.now().subtract(const Duration(hours: 2)),
        endTime: Timestamp.now().subtract(const Duration(hours: 1)),
        title: 'Completed Run',
      );

      final activeActivity = Activity(
        id: 'active-activity',
        startTime: Timestamp.now(),
        title: 'Active Run',
        // No endTime - activity is in progress
      );

      await activityDao.createActivity(activityDao.toEntity(completedActivity));
      await activityDao.createActivity(activityDao.toEntity(activeActivity));

      // Act
      final retrieved = await activityDao.getActiveActivity();

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('active-activity'));
      expect(retrieved.endTime, isNull);
    });

    test('should get activities by sync state', () async {
      // Arrange
      final localActivity = Activity(
        id: 'local-activity',
        startTime: Timestamp.now(),
        title: 'Local Activity',
        syncState: SyncState.local,
      );

      final syncedActivity = Activity(
        id: 'synced-activity',
        startTime: Timestamp.now(),
        title: 'Synced Activity',
        syncState: SyncState.synced,
      );

      await activityDao.createActivity(activityDao.toEntity(localActivity));
      await activityDao.createActivity(activityDao.toEntity(syncedActivity));

      // Act
      final localActivities = await activityDao.getActivitiesBySyncState(SyncState.local);
      final syncedActivities = await activityDao.getActivitiesBySyncState(SyncState.synced);

      // Assert
      expect(localActivities.length, equals(1));
      expect(localActivities.first.id, equals('local-activity'));
      expect(syncedActivities.length, equals(1));
      expect(syncedActivities.first.id, equals('synced-activity'));
    });

    test('should get activities in date range', () async {
      // Arrange
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final oldActivity = Activity(
        id: 'old-activity',
        startTime: Timestamp(yesterday.subtract(const Duration(days: 1))),
        title: 'Old Activity',
      );

      final todayActivity = Activity(
        id: 'today-activity',
        startTime: Timestamp(now),
        title: 'Today Activity',
      );

      final futureActivity = Activity(
        id: 'future-activity',
        startTime: Timestamp(tomorrow.add(const Duration(days: 1))),
        title: 'Future Activity',
      );

      await activityDao.createActivity(activityDao.toEntity(oldActivity));
      await activityDao.createActivity(activityDao.toEntity(todayActivity));
      await activityDao.createActivity(activityDao.toEntity(futureActivity));

      // Act
      final activitiesInRange = await activityDao.getActivitiesInDateRange(
        startDate: yesterday,
        endDate: tomorrow,
      );

      // Assert
      expect(activitiesInRange.length, equals(1));
      expect(activitiesInRange.first.id, equals('today-activity'));
    });

    test('should search activities by title and notes', () async {
      // Arrange
      final activity1 = Activity(
        id: 'activity-1',
        startTime: Timestamp.now(),
        title: 'Morning Trail Run',
        notes: 'Beautiful sunrise',
      );

      final activity2 = Activity(
        id: 'activity-2',
        startTime: Timestamp.now(),
        title: 'Evening Jog',
        notes: 'Quick run around the block',
      );

      final activity3 = Activity(
        id: 'activity-3',
        startTime: Timestamp.now(),
        title: 'Weekend Hike',
        notes: 'Mountain trail adventure',
      );

      await activityDao.createActivity(activityDao.toEntity(activity1));
      await activityDao.createActivity(activityDao.toEntity(activity2));
      await activityDao.createActivity(activityDao.toEntity(activity3));

      // Act
      final runResults = await activityDao.searchActivities('run');
      final trailResults = await activityDao.searchActivities('trail');

      // Assert
      expect(runResults.length, equals(2)); // Morning Trail Run and Evening Jog (notes)
      expect(trailResults.length, equals(2)); // Morning Trail Run and Weekend Hike (notes)
    });

    test('should get activities count', () async {
      // Arrange
      final activity1 = Activity(
        id: 'activity-1',
        startTime: Timestamp.now(),
        title: 'Activity 1',
      );

      final activity2 = Activity(
        id: 'activity-2',
        startTime: Timestamp.now(),
        title: 'Activity 2',
      );

      await activityDao.createActivity(activityDao.toEntity(activity1));
      await activityDao.createActivity(activityDao.toEntity(activity2));

      // Act
      final count = await activityDao.getActivitiesCount();

      // Assert
      expect(count, equals(2));
    });

    test('should get activities with pagination', () async {
      // Arrange
      final activities = List.generate(10, (index) => Activity(
        id: 'activity-$index',
        startTime: Timestamp.now().subtract(Duration(hours: index)),
        title: 'Activity $index',
      ));

      for (final activity in activities) {
        await activityDao.createActivity(activityDao.toEntity(activity));
      }

      // Act
      final firstPage = await activityDao.getActivitiesPaginated(limit: 3, offset: 0);
      final secondPage = await activityDao.getActivitiesPaginated(limit: 3, offset: 3);

      // Assert
      expect(firstPage.length, equals(3));
      expect(secondPage.length, equals(3));
      expect(firstPage.first.id, equals('activity-0')); // Most recent first
      expect(secondPage.first.id, equals('activity-3'));
    });

    test('should update activity sync state', () async {
      // Arrange
      final activity = Activity(
        id: 'sync-test-activity',
        startTime: Timestamp.now(),
        title: 'Sync Test',
        syncState: SyncState.local,
      );

      await activityDao.createActivity(activityDao.toEntity(activity));

      // Act
      await activityDao.updateActivitySyncState('sync-test-activity', SyncState.synced);

      // Assert
      final retrieved = await activityDao.getActivityById('sync-test-activity');
      expect(retrieved!.syncState, equals(SyncState.synced.value));
    });

    test('should convert between domain and entity correctly', () async {
      // Arrange
      final domainActivity = Activity(
        id: 'conversion-test',
        startTime: Timestamp.now(),
        endTime: Timestamp.now().add(const Duration(hours: 1)),
        title: 'Conversion Test',
        distance: Distance.kilometers(10.5),
        elevationGain: Elevation.meters(250),
        elevationLoss: Elevation.meters(200),
        averagePace: Pace.minutesPerKilometer(4.5),
        notes: 'Test notes',
        privacy: PrivacyLevel.public,
        coverPhotoId: 'photo-123',
        syncState: SyncState.pending,
      );

      // Act
      final entity = activityDao.toEntity(domainActivity);
      final convertedBack = activityDao.fromEntity(entity);

      // Assert
      expect(convertedBack.id, equals(domainActivity.id));
      expect(convertedBack.title, equals(domainActivity.title));
      expect(convertedBack.distance.kilometers, equals(domainActivity.distance.kilometers));
      expect(convertedBack.elevationGain.meters, equals(domainActivity.elevationGain.meters));
      expect(convertedBack.elevationLoss.meters, equals(domainActivity.elevationLoss.meters));
      expect(convertedBack.averagePace?.secondsPerKilometer, 
             equals(domainActivity.averagePace?.secondsPerKilometer));
      expect(convertedBack.notes, equals(domainActivity.notes));
      expect(convertedBack.privacy, equals(domainActivity.privacy));
      expect(convertedBack.coverPhotoId, equals(domainActivity.coverPhotoId));
      expect(convertedBack.syncState, equals(domainActivity.syncState));
    });
  });
}

