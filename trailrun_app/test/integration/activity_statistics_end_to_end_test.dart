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
  group('Activity Statistics End-to-End Tests', () {
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

    test('complete activity lifecycle with statistics calculation', () async {
      // Create a new activity
      final activity = Activity(
        id: 'complete_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        title: 'Complete Trail Run',
      );

      await repository.createActivity(activity);

      // Simulate a realistic trail run with varying elevation and pace
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      
      // Create a 5km trail run with realistic elevation profile
      final elevationProfile = [
        100, 105, 110, 115, 120, 125, 130, 135, 140, 145, // Gradual climb (0-1km)
        150, 155, 160, 165, 170, 175, 180, 185, 190, 195, // Continued climb (1-2km)
        200, 195, 190, 185, 180, 175, 170, 165, 160, 155, // Descent (2-3km)
        150, 145, 140, 135, 130, 125, 120, 115, 110, 105, // Continued descent (3-4km)
        100, 95, 90, 85, 80, 75, 70, 65, 60, 55,          // Final descent (4-5km)
      ];

      // Generate track points every 100m for 5km
      for (int i = 0; i < 50; i++) {
        final timeOffset = i < 20 
            ? i * 35  // Slower pace uphill (35 sec per 100m = 5:50/km)
            : i < 30 
                ? 700 + (i - 20) * 25  // Faster pace on descent (25 sec per 100m = 4:10/km)
                : 950 + (i - 30) * 30; // Moderate pace on flat (30 sec per 100m = 5:00/km)

        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'complete_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: timeOffset))),
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.0009), // ~100m per 0.0009 degree
            longitude: -122.4194,
            elevation: elevationProfile[i].toDouble(),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      // Add track points in batches to simulate real-time tracking
      final batchSize = 10;
      for (int i = 0; i < trackPoints.length; i += batchSize) {
        final endIndex = (i + batchSize).clamp(0, trackPoints.length);
        final batch = trackPoints.sublist(i, endIndex);
        await repository.addTrackPoints('complete_activity', batch);
      }

      // Complete the activity
      final completedActivity = activity.copyWith(
        endTime: Timestamp(baseTime.add(Duration(seconds: 1550))), // Total time
      );
      await repository.updateActivity(completedActivity);

      // Retrieve the final activity with all statistics
      final finalActivity = await repository.getActivity('complete_activity');

      expect(finalActivity, isNotNull);

      // Verify distance calculation
      expect(finalActivity!.distance.kilometers, greaterThan(4.8));
      expect(finalActivity.distance.kilometers, lessThan(5.2));

      // Verify elevation statistics
      expect(finalActivity.elevationGain.meters, greaterThan(90)); // Should be ~100m gain
      expect(finalActivity.elevationGain.meters, lessThan(110));
      expect(finalActivity.elevationLoss.meters, greaterThan(135)); // Should be ~145m loss
      expect(finalActivity.elevationLoss.meters, lessThan(155));
      expect(finalActivity.netElevationChange.meters, lessThan(0)); // Net loss

      // Verify pace calculation
      expect(finalActivity.averagePace, isNotNull);
      expect(finalActivity.averagePace!.minutesPerKilometer, greaterThan(4.0));
      expect(finalActivity.averagePace!.minutesPerKilometer, lessThan(7.0));

      // Verify splits generation
      expect(finalActivity.splits, isNotEmpty);
      expect(finalActivity.splits.length, greaterThanOrEqualTo(4)); // At least 4 complete splits
      expect(finalActivity.splits.length, lessThanOrEqualTo(5)); // At most 5 splits

      // Verify split details
      for (int i = 0; i < finalActivity.splits.length - 1; i++) { // Exclude last partial split
        final split = finalActivity.splits[i];
        expect(split.splitNumber, equals(i + 1));
        expect(split.distance.kilometers, greaterThan(0.95));
        expect(split.distance.kilometers, lessThan(1.05));
        expect(split.pace.minutesPerKilometer, greaterThan(3.0));
        expect(split.pace.minutesPerKilometer, lessThan(8.0));
      }

      // Verify fastest and slowest splits
      final fastestSplit = finalActivity.fastestSplit;
      final slowestSplit = finalActivity.slowestSplit;
      
      expect(fastestSplit, isNotNull);
      expect(slowestSplit, isNotNull);
      expect(fastestSplit!.pace.secondsPerKilometer, 
             lessThan(slowestSplit!.pace.secondsPerKilometer));

      // Verify track points are properly stored
      expect(finalActivity.trackPoints.length, equals(50));
      expect(finalActivity.hasGpsData, isTrue);

      // Test elevation profile generation
      final generatedProfile = statisticsService.generateElevationProfile(
        finalActivity.trackPointsSortedBySequence,
      );
      expect(generatedProfile, isNotEmpty);
      expect(generatedProfile.length, equals(50));
      expect(generatedProfile.first.distance.meters, equals(0));
      expect(generatedProfile.last.distance.meters, greaterThan(4800));

      // Test moving average pace calculation
      final movingAverages = statisticsService.calculateMovingAveragePace(
        finalActivity.trackPointsSortedBySequence,
        windowSize: const Duration(minutes: 2),
      );
      expect(movingAverages, isNotEmpty);
    });

    test('activity statistics with real-world GPS noise and gaps', () async {
      // Create activity
      final activity = Activity(
        id: 'noisy_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 20, 0)), // 20 minute activity
        title: 'Noisy GPS Run',
      );

      await repository.createActivity(activity);

      // Create track points with realistic GPS noise and occasional gaps
      final trackPoints = <TrackPoint>[];
      final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
      
      for (int i = 0; i < 30; i++) {
        // Skip some points to simulate GPS gaps
        if (i == 10 || i == 15 || i == 22) continue;

        // Add some GPS noise
        final latNoise = (i % 3 - 1) * 0.00001; // ±1m noise
        final lonNoise = (i % 5 - 2) * 0.00001; // ±2m noise
        final elevationNoise = (i % 7 - 3) * 0.5; // ±1.5m noise

        trackPoints.add(TrackPoint(
          id: 'point_$i',
          activityId: 'noisy_activity',
          timestamp: Timestamp(baseTime.add(Duration(seconds: i * 40))),
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.0009) + latNoise,
            longitude: -122.4194 + lonNoise,
            elevation: 100 + (i * 1.5) + elevationNoise,
          ),
          accuracy: 5.0 + (i % 3) * 2.0, // Varying accuracy
          source: LocationSource.gps,
          sequence: i,
        ));
      }

      await repository.addTrackPoints('noisy_activity', trackPoints);

      // Retrieve and verify statistics are still reasonable
      final noisyActivity = await repository.getActivity('noisy_activity');

      expect(noisyActivity, isNotNull);
      expect(noisyActivity!.distance.meters, greaterThan(0));
      expect(noisyActivity.elevationGain.meters, greaterThan(0));
      expect(noisyActivity.averagePace, isNotNull);
      
      // Should handle gaps gracefully
      expect(noisyActivity.trackPoints.length, equals(trackPoints.length));
    });

    test('activity with minimal track points', () async {
      // Create activity with just 2 track points
      final activity = Activity(
        id: 'minimal_activity',
        startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
        endTime: Timestamp(DateTime(2023, 1, 1, 10, 5, 0)),
        title: 'Minimal Run',
      );

      await repository.createActivity(activity);

      final trackPoints = [
        TrackPoint(
          id: 'point_0',
          activityId: 'minimal_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'point_1',
          activityId: 'minimal_activity',
          timestamp: Timestamp(DateTime(2023, 1, 1, 10, 5, 0)),
          coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4194, elevation: 110),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];

      await repository.addTrackPoints('minimal_activity', trackPoints);

      final minimalActivity = await repository.getActivity('minimal_activity');

      expect(minimalActivity, isNotNull);
      expect(minimalActivity!.distance.meters, greaterThan(1000)); // ~1.1km
      expect(minimalActivity.elevationGain.meters, equals(10));
      expect(minimalActivity.averagePace, isNotNull);
      expect(minimalActivity.splits.length, equals(1)); // One partial split
    });
  });
}