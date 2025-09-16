import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import '../../lib/data/database/database.dart';
import '../../lib/data/repositories/activity_repository_impl.dart';
import '../../lib/data/services/activity_statistics_service.dart';
import '../../lib/domain/enums/location_source.dart';
import '../../lib/domain/models/activity.dart';
import '../../lib/domain/models/track_point.dart';
import '../../lib/domain/value_objects/coordinates.dart';
import '../../lib/domain/value_objects/timestamp.dart';

void main() {
  group('Activity Statistics Integration Tests', () {
    late TrailRunDatabase database;
    late ActivityRepositoryImpl repository;
    late ActivityStatisticsService statisticsService;

    setUp(() async {
      database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
      statisticsService = ActivityStatisticsService();
      repository = ActivityRepositoryImpl(
        database: database,
        statisticsService: statisticsService,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('should calculate and store activity statistics when track points are added', () async {
      // Create an activity
      final activity = Activity(
        id: 'test_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 30, 0)),
        title: 'Test Run',
      );

      await repository.createActivity(activity);

      // Create track points that simulate a 2km run with elevation changes
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      
      // Generate points every 100m for 2km (20 points)
      for (int i = 0; i < 20; i++) {
        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'test_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: i * 90))), // 90 seconds per point
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.0009), // ~100m per 0.0009 degree
            longitude: -122.4194,
            elevation: 100 + (i * 2.0), // 2m elevation gain per point
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      // Add track points in batch
      await repository.addTrackPoints('test_activity', trackPoints);

      // Retrieve the updated activity
      final updatedActivity = await repository.getActivity('test_activity');

      expect(updatedActivity, isNotNull);
      expect(updatedActivity!.distance.kilometers, greaterThan(1.8));
      expect(updatedActivity.distance.kilometers, lessThan(2.2));
      expect(updatedActivity.elevationGain.meters, greaterThan(35));
      expect(updatedActivity.elevationGain.meters, lessThan(45));
      expect(updatedActivity.elevationLoss.meters, equals(0));
      expect(updatedActivity.averagePace, isNotNull);
      expect(updatedActivity.splits, isNotEmpty);
      expect(updatedActivity.splits.length, greaterThanOrEqualTo(1));
    });

    test('should generate correct splits for multi-kilometer activity', () async {
      // Create an activity
      final activity = Activity(
        id: 'long_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 45, 0)),
        title: 'Long Run',
      );

      await repository.createActivity(activity);

      // Create track points for a 3.5km run
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      
      // Generate points every 50m for 3.5km (70 points)
      for (int i = 0; i < 70; i++) {
        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'long_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: i * 25))), // ~25 seconds per 50m (reasonable running pace)
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.00045), // ~50m per 0.00045 degree
            longitude: -122.4194,
            elevation: 100 + (i % 20) * 3.0, // Undulating elevation
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      await repository.addTrackPoints('long_activity', trackPoints);

      // Retrieve the updated activity
      final updatedActivity = await repository.getActivity('long_activity');

      expect(updatedActivity, isNotNull);
      expect(updatedActivity!.distance.kilometers, greaterThan(3.0));
      expect(updatedActivity.distance.kilometers, lessThan(4.0));
      
      // Should have 3 complete splits and possibly 1 partial split
      expect(updatedActivity.splits.length, greaterThanOrEqualTo(3));
      expect(updatedActivity.splits.length, lessThanOrEqualTo(4));
      
      // First three splits should be approximately 1km each
      for (int i = 0; i < 3; i++) {
        final split = updatedActivity.splits[i];
        expect(split.splitNumber, equals(i + 1));
        expect(split.distance.kilometers, greaterThan(0.9));
        expect(split.distance.kilometers, lessThan(1.1));
        expect(split.pace.minutesPerKilometer, greaterThan(3.0));
        expect(split.pace.minutesPerKilometer, lessThan(10.0));
      }
    });

    test('should handle elevation gain and loss correctly', () async {
      // Create an activity with significant elevation changes
      final activity = Activity(
        id: 'hilly_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 20, 0)),
        title: 'Hilly Run',
      );

      await repository.createActivity(activity);

      // Create track points with elevation profile: up, down, up
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      final elevations = [
        100, 110, 120, 130, 140, 150, // +50m gain
        140, 130, 120, 110, 100, 90,  // -60m loss
        100, 110, 120, 130, 140,      // +50m gain
      ];
      
      for (int i = 0; i < elevations.length; i++) {
        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'hilly_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: i * 80))),
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.0005),
            longitude: -122.4194,
            elevation: elevations[i].toDouble(),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      await repository.addTrackPoints('hilly_activity', trackPoints);

      // Retrieve the updated activity
      final updatedActivity = await repository.getActivity('hilly_activity');

      expect(updatedActivity, isNotNull);
      expect(updatedActivity!.elevationGain.meters, equals(100)); // 50 + 50
      expect(updatedActivity.elevationLoss.meters, equals(60));
      expect(updatedActivity.netElevationChange.meters, equals(40)); // 100 - 60
    });

    test('should update statistics when track points are added incrementally', () async {
      // Create an activity
      final activity = Activity(
        id: 'incremental_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        title: 'Incremental Run',
      );

      await repository.createActivity(activity);

      // Add first batch of track points
      final firstBatch = [
        TrackPoint(
          id: 'point_0',
          activityId: 'incremental_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'point_1',
          activityId: 'incremental_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 1, 0)),
          coordinates: const Coordinates(latitude: 37.7759, longitude: -122.4194, elevation: 110),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];

      await repository.addTrackPoints('incremental_activity', firstBatch);

      // Check initial statistics
      var updatedActivity = await repository.getActivity('incremental_activity');
      expect(updatedActivity, isNotNull);
      final initialDistance = updatedActivity!.distance.meters;
      final initialElevationGain = updatedActivity.elevationGain.meters;

      // Add second batch
      final secondBatch = [
        TrackPoint(
          id: 'point_2',
          activityId: 'incremental_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 2, 0)),
          coordinates: const Coordinates(latitude: 37.7769, longitude: -122.4194, elevation: 120),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 2,
        ),
        TrackPoint(
          id: 'point_3',
          activityId: 'incremental_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 3, 0)),
          coordinates: const Coordinates(latitude: 37.7779, longitude: -122.4194, elevation: 130),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 3,
        ),
      ];

      await repository.addTrackPoints('incremental_activity', secondBatch);

      // Check updated statistics
      updatedActivity = await repository.getActivity('incremental_activity');
      expect(updatedActivity, isNotNull);
      expect(updatedActivity!.distance.meters, greaterThan(initialDistance));
      expect(updatedActivity.elevationGain.meters, greaterThan(initialElevationGain));
      expect(updatedActivity.elevationGain.meters, equals(30)); // Total gain
    });

    test('should handle activities with no elevation data', () async {
      // Create an activity
      final activity = Activity(
        id: 'flat_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 15, 0)),
        title: 'Flat Run',
      );

      await repository.createActivity(activity);

      // Create track points without elevation data
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      
      for (int i = 0; i < 10; i++) {
        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'flat_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: i * 90))),
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.001),
            longitude: -122.4194,
            // No elevation data
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      await repository.addTrackPoints('flat_activity', trackPoints);

      // Retrieve the updated activity
      final updatedActivity = await repository.getActivity('flat_activity');

      expect(updatedActivity, isNotNull);
      expect(updatedActivity!.distance.meters, greaterThan(0));
      expect(updatedActivity.elevationGain.meters, equals(0));
      expect(updatedActivity.elevationLoss.meters, equals(0));
      expect(updatedActivity.averagePace, isNotNull);
    });
  });
}