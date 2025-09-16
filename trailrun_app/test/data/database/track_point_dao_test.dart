import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:trailrun_app/data/database/database.dart';
import 'package:trailrun_app/data/database/daos/track_point_dao.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';

void main() {
  late TrailRunDatabase database;
  late TrackPointDao trackPointDao;

  setUp(() {
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
    trackPointDao = database.trackPointDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('TrackPointDao', () {
    test('should create and retrieve track point', () async {
      // Arrange
      final trackPoint = TrackPoint(
        id: 'track-point-1',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 100.0,
        ),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 0,
      );

      final entity = trackPointDao.toEntity(trackPoint);

      // Act
      await trackPointDao.createTrackPoint(entity);
      final retrieved = await trackPointDao.getTrackPointById('track-point-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('track-point-1'));
      expect(retrieved.activityId, equals('activity-1'));
      expect(retrieved.latitude, equals(37.7749));
      expect(retrieved.longitude, equals(-122.4194));
      expect(retrieved.elevation, equals(100.0));
      expect(retrieved.accuracy, equals(5.0));
      expect(retrieved.source, equals(LocationSource.gps.value));
      expect(retrieved.sequence, equals(0));
    });

    test('should get track points for activity ordered by sequence', () async {
      // Arrange
      final trackPoints = [
        TrackPoint(
          id: 'track-point-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 2,
        ),
        TrackPoint(
          id: 'track-point-2',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195),
          accuracy: 4.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'track-point-3',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7751, longitude: -122.4196),
          accuracy: 6.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      final retrieved = await trackPointDao.getTrackPointsForActivity('activity-1');

      // Assert
      expect(retrieved.length, equals(3));
      expect(retrieved[0].sequence, equals(0)); // Should be ordered by sequence
      expect(retrieved[1].sequence, equals(1));
      expect(retrieved[2].sequence, equals(2));
    });

    test('should get latest track point for activity', () async {
      // Arrange
      final trackPoints = [
        TrackPoint(
          id: 'track-point-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'track-point-2',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195),
          accuracy: 4.0,
          source: LocationSource.gps,
          sequence: 2,
        ),
        TrackPoint(
          id: 'track-point-3',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7751, longitude: -122.4196),
          accuracy: 6.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      final latest = await trackPointDao.getLatestTrackPoint('activity-1');

      // Assert
      expect(latest, isNotNull);
      expect(latest!.id, equals('track-point-2')); // Highest sequence number
      expect(latest.sequence, equals(2));
    });

    test('should get track points with good accuracy', () async {
      // Arrange
      final trackPoints = [
        TrackPoint(
          id: 'accurate-point',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 3.0, // Good accuracy
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'inaccurate-point',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195),
          accuracy: 15.0, // Poor accuracy
          source: LocationSource.network,
          sequence: 1,
        ),
      ];

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      final accuratePoints = await trackPointDao.getAccurateTrackPoints(
        activityId: 'activity-1',
        maxAccuracyMeters: 10.0,
      );

      // Assert
      expect(accuratePoints.length, equals(1));
      expect(accuratePoints.first.id, equals('accurate-point'));
      expect(accuratePoints.first.accuracy, equals(3.0));
    });

    test('should get track points in time range', () async {
      // Arrange
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));

      final trackPoints = [
        TrackPoint(
          id: 'old-point',
          activityId: 'activity-1',
          timestamp: Timestamp(twoHoursAgo),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'in-range-point',
          activityId: 'activity-1',
          timestamp: Timestamp(thirtyMinutesAgo),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195),
          accuracy: 4.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
        TrackPoint(
          id: 'recent-point',
          activityId: 'activity-1',
          timestamp: Timestamp(now),
          coordinates: const Coordinates(latitude: 37.7751, longitude: -122.4196),
          accuracy: 6.0,
          source: LocationSource.gps,
          sequence: 2,
        ),
      ];

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      final pointsInRange = await trackPointDao.getTrackPointsInTimeRange(
        activityId: 'activity-1',
        startTime: oneHourAgo,
        endTime: now,
      );

      // Assert
      expect(pointsInRange.length, equals(2)); // in-range-point and recent-point
      expect(pointsInRange.any((p) => p.id == 'in-range-point'), isTrue);
      expect(pointsInRange.any((p) => p.id == 'recent-point'), isTrue);
      expect(pointsInRange.any((p) => p.id == 'old-point'), isFalse);
    });

    test('should create track points in batch', () async {
      // Arrange
      final trackPoints = List.generate(5, (index) => TrackPoint(
        id: 'batch-point-$index',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: Coordinates(
          latitude: 37.7749 + (index * 0.001),
          longitude: -122.4194 + (index * 0.001),
        ),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: index,
      ));

      final entities = trackPoints.map(trackPointDao.toEntity).toList();

      // Act
      await trackPointDao.createTrackPointsBatch(entities);

      // Assert
      final retrieved = await trackPointDao.getTrackPointsForActivity('activity-1');
      expect(retrieved.length, equals(5));
    });

    test('should get track points count', () async {
      // Arrange
      final trackPoints = List.generate(3, (index) => TrackPoint(
        id: 'count-point-$index',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: index,
      ));

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      final count = await trackPointDao.getTrackPointsCount('activity-1');

      // Assert
      expect(count, equals(3));
    });

    test('should delete track points for activity', () async {
      // Arrange
      final trackPoints = [
        TrackPoint(
          id: 'delete-point-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'keep-point-1',
          activityId: 'activity-2',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195),
          accuracy: 4.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
      ];

      for (final trackPoint in trackPoints) {
        await trackPointDao.createTrackPoint(trackPointDao.toEntity(trackPoint));
      }

      // Act
      await trackPointDao.deleteTrackPointsForActivity('activity-1');

      // Assert
      final activity1Points = await trackPointDao.getTrackPointsForActivity('activity-1');
      final activity2Points = await trackPointDao.getTrackPointsForActivity('activity-2');
      
      expect(activity1Points.length, equals(0));
      expect(activity2Points.length, equals(1));
    });

    test('should convert between domain and entity correctly', () async {
      // Arrange
      final domainTrackPoint = TrackPoint(
        id: 'conversion-test',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 150.5,
        ),
        accuracy: 3.2,
        source: LocationSource.fused,
        sequence: 42,
      );

      // Act
      final entity = trackPointDao.toEntity(domainTrackPoint);
      final convertedBack = trackPointDao.fromEntity(entity);

      // Assert
      expect(convertedBack.id, equals(domainTrackPoint.id));
      expect(convertedBack.activityId, equals(domainTrackPoint.activityId));
      expect(convertedBack.coordinates.latitude, equals(domainTrackPoint.coordinates.latitude));
      expect(convertedBack.coordinates.longitude, equals(domainTrackPoint.coordinates.longitude));
      expect(convertedBack.coordinates.elevation, equals(domainTrackPoint.coordinates.elevation));
      expect(convertedBack.accuracy, equals(domainTrackPoint.accuracy));
      expect(convertedBack.source, equals(domainTrackPoint.source));
      expect(convertedBack.sequence, equals(domainTrackPoint.sequence));
    });
  });
}