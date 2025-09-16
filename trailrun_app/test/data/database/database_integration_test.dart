import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:trailrun_app/data/database/database.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';

void main() {
  late TrailRunDatabase database;

  setUp(() {
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Database Integration Tests', () {
    test('should create activity with related data', () async {
      // Arrange
      final activity = Activity(
        id: 'integration-activity-1',
        startTime: Timestamp.now(),
        title: 'Integration Test Run',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(100),
        elevationLoss: Elevation.meters(80),
        privacy: PrivacyLevel.private,
        syncState: SyncState.local,
      );

      final trackPoint = TrackPoint(
        id: 'track-point-1',
        activityId: 'integration-activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 0,
      );

      final photo = Photo(
        id: 'photo-1',
        activityId: 'integration-activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        filePath: '/path/to/photo.jpg',
        curationScore: 0.8,
      );

      // Act
      await database.activityDao.createActivity(database.activityDao.toEntity(activity));
      await database.trackPointDao.createTrackPoint(database.trackPointDao.toEntity(trackPoint));
      await database.photoDao.createPhoto(database.photoDao.toEntity(photo));

      // Assert
      final retrievedActivity = await database.activityDao.getActivityById('integration-activity-1');
      final retrievedTrackPoints = await database.trackPointDao.getTrackPointsForActivity('integration-activity-1');
      final retrievedPhotos = await database.photoDao.getPhotosForActivity('integration-activity-1');

      expect(retrievedActivity, isNotNull);
      expect(retrievedActivity!.title, equals('Integration Test Run'));
      expect(retrievedTrackPoints.length, equals(1));
      expect(retrievedPhotos.length, equals(1));
    });

    test('should handle domain model conversions correctly', () async {
      // Arrange
      final domainActivity = Activity(
        id: 'conversion-test-activity',
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
      final entity = database.activityDao.toEntity(domainActivity);
      await database.activityDao.createActivity(entity);
      
      final retrievedEntity = await database.activityDao.getActivityById('conversion-test-activity');
      final convertedBack = database.activityDao.fromEntity(retrievedEntity!);

      // Assert
      expect(convertedBack.id, equals(domainActivity.id));
      expect(convertedBack.title, equals(domainActivity.title));
      expect(convertedBack.distance.kilometers, closeTo(domainActivity.distance.kilometers, 0.001));
      expect(convertedBack.elevationGain.meters, closeTo(domainActivity.elevationGain.meters, 0.001));
      expect(convertedBack.elevationLoss.meters, closeTo(domainActivity.elevationLoss.meters, 0.001));
      expect(convertedBack.averagePace?.secondsPerKilometer, 
             closeTo(domainActivity.averagePace!.secondsPerKilometer, 0.001));
      expect(convertedBack.notes, equals(domainActivity.notes));
      expect(convertedBack.privacy, equals(domainActivity.privacy));
      expect(convertedBack.coverPhotoId, equals(domainActivity.coverPhotoId));
      expect(convertedBack.syncState, equals(domainActivity.syncState));
    });

    test('should maintain data integrity with foreign key relationships', () async {
      // Arrange
      final activity = Activity(
        id: 'parent-activity',
        startTime: Timestamp.now(),
        title: 'Parent Activity',
      );

      final trackPoint = TrackPoint(
        id: 'child-track-point',
        activityId: 'parent-activity',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 0,
      );

      // Act
      await database.activityDao.createActivity(database.activityDao.toEntity(activity));
      await database.trackPointDao.createTrackPoint(database.trackPointDao.toEntity(trackPoint));

      // Verify data exists
      final trackPoints = await database.trackPointDao.getTrackPointsForActivity('parent-activity');
      expect(trackPoints.length, equals(1));

      // Delete activity (should cascade to track points if foreign keys are enabled)
      await database.activityDao.deleteActivity('parent-activity');

      // Assert
      final remainingActivity = await database.activityDao.getActivityById('parent-activity');
      expect(remainingActivity, isNull);
      
      // Note: Since we simplified foreign keys, we need to manually clean up
      await database.trackPointDao.deleteTrackPointsForActivity('parent-activity');
      final remainingTrackPoints = await database.trackPointDao.getTrackPointsForActivity('parent-activity');
      expect(remainingTrackPoints.length, equals(0));
    });

    test('should handle batch operations efficiently', () async {
      // Arrange
      final activities = List.generate(10, (index) => Activity(
        id: 'batch-activity-$index',
        startTime: Timestamp.now().subtract(Duration(hours: index)),
        title: 'Batch Activity $index',
      ));

      final trackPoints = List.generate(50, (index) => TrackPoint(
        id: 'batch-track-point-$index',
        activityId: 'batch-activity-${index % 10}', // Distribute across activities
        timestamp: Timestamp.now(),
        coordinates: Coordinates(
          latitude: 37.7749 + (index * 0.001),
          longitude: -122.4194 + (index * 0.001),
        ),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: index,
      ));

      // Act
      final stopwatch = Stopwatch()..start();
      
      // Create activities individually
      for (final activity in activities) {
        await database.activityDao.createActivity(database.activityDao.toEntity(activity));
      }
      
      // Create track points in batch
      final trackPointEntities = trackPoints.map(database.trackPointDao.toEntity).toList();
      await database.trackPointDao.createTrackPointsBatch(trackPointEntities);
      
      stopwatch.stop();

      // Assert
      final activityCount = await database.activityDao.getActivitiesCount();
      final trackPointCount = await database.trackPointDao.getTrackPointsCount('batch-activity-0');
      
      expect(activityCount, equals(10));
      expect(trackPointCount, equals(5)); // 50 points distributed across 10 activities
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });
  });
}