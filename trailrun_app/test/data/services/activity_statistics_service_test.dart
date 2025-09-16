import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/services/activity_statistics_service.dart';
import '../../../lib/domain/enums/location_source.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/models/track_point.dart';
import '../../../lib/domain/value_objects/coordinates.dart';
import '../../../lib/domain/value_objects/measurement_units.dart';
import '../../../lib/domain/value_objects/timestamp.dart';

void main() {
  group('ActivityStatisticsService', () {
    late ActivityStatisticsService service;

    setUp(() {
      service = ActivityStatisticsService();
    });

    group('calculateTotalDistance', () {
      test('returns zero distance for empty track points', () {
        final distance = service.calculateTotalDistance([]);
        expect(distance.meters, equals(0));
      });

      test('returns zero distance for single track point', () {
        final trackPoint = _createTrackPoint(
          sequence: 0,
          lat: 37.7749,
          lon: -122.4194,
        );
        final distance = service.calculateTotalDistance([trackPoint]);
        expect(distance.meters, equals(0));
      });

      test('calculates distance between two points correctly', () {
        final point1 = _createTrackPoint(
          sequence: 0,
          lat: 37.7749, // San Francisco
          lon: -122.4194,
        );
        final point2 = _createTrackPoint(
          sequence: 1,
          lat: 37.7849, // ~1.1km north
          lon: -122.4194,
        );

        final distance = service.calculateTotalDistance([point1, point2]);
        
        // Should be approximately 1.1km (allowing for some variance due to Earth's curvature)
        expect(distance.meters, greaterThan(1000));
        expect(distance.meters, lessThan(1200));
      });

      test('calculates cumulative distance for multiple points', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194), // ~111m north
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194), // ~111m north
          _createTrackPoint(sequence: 3, lat: 37.7779, lon: -122.4194), // ~111m north
        ];

        final distance = service.calculateTotalDistance(points);
        
        // Should be approximately 333m
        expect(distance.meters, greaterThan(300));
        expect(distance.meters, lessThan(400));
      });

      test('handles unsorted track points correctly', () {
        final points = [
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194),
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194),
        ];

        final distance = service.calculateTotalDistance(points);
        
        // Should be approximately 222m (two segments)
        expect(distance.meters, greaterThan(200));
        expect(distance.meters, lessThan(250));
      });
    });

    group('calculateAveragePace', () {
      test('returns null for empty track points', () {
        final pace = service.calculateAveragePace([], const Duration(minutes: 30));
        expect(pace, isNull);
      });

      test('returns null for null duration', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194),
        ];
        final pace = service.calculateAveragePace(points, null);
        expect(pace, isNull);
      });

      test('returns null for zero duration', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194),
        ];
        final pace = service.calculateAveragePace(points, Duration.zero);
        expect(pace, isNull);
      });

      test('calculates pace correctly for valid input', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194),
          _createTrackPoint(sequence: 1, lat: 37.7849, lon: -122.4194), // ~1.1km
        ];
        final duration = const Duration(minutes: 5); // 5 minutes for ~1.1km

        final pace = service.calculateAveragePace(points, duration);
        
        expect(pace, isNotNull);
        // Should be approximately 4:30-4:40 per km
        expect(pace!.minutesPerKilometer, greaterThan(4.0));
        expect(pace.minutesPerKilometer, lessThan(5.0));
      });
    });

    group('calculateElevationStats', () {
      test('returns zero elevation for empty track points', () {
        final stats = service.calculateElevationStats([]);
        expect(stats.gain.meters, equals(0));
        expect(stats.loss.meters, equals(0));
      });

      test('returns zero elevation for single track point', () {
        final point = _createTrackPoint(
          sequence: 0,
          lat: 37.7749,
          lon: -122.4194,
          elevation: 100,
        );
        final stats = service.calculateElevationStats([point]);
        expect(stats.gain.meters, equals(0));
        expect(stats.loss.meters, equals(0));
      });

      test('calculates elevation gain correctly', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 100),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194, elevation: 120),
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 150),
        ];

        final stats = service.calculateElevationStats(points);
        expect(stats.gain.meters, equals(50)); // 20 + 30
        expect(stats.loss.meters, equals(0));
      });

      test('calculates elevation loss correctly', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 150),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194, elevation: 120),
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 100),
        ];

        final stats = service.calculateElevationStats(points);
        expect(stats.gain.meters, equals(0));
        expect(stats.loss.meters, equals(50)); // 30 + 20
      });

      test('calculates mixed elevation changes correctly', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 100),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194, elevation: 130), // +30
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 110), // -20
          _createTrackPoint(sequence: 3, lat: 37.7779, lon: -122.4194, elevation: 140), // +30
        ];

        final stats = service.calculateElevationStats(points);
        expect(stats.gain.meters, equals(60)); // 30 + 30
        expect(stats.loss.meters, equals(20)); // 20
        expect(stats.netChange.meters, equals(40)); // 60 - 20
      });

      test('ignores points without elevation data', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 100),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194), // no elevation
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 120),
        ];

        final stats = service.calculateElevationStats(points);
        expect(stats.gain.meters, equals(20)); // Only from point 0 to 2
        expect(stats.loss.meters, equals(0));
      });
    });

    group('generateSplits', () {
      test('returns empty list for empty track points', () {
        final splits = service.generateSplits('activity1', []);
        expect(splits, isEmpty);
      });

      test('returns empty list for insufficient track points', () {
        final point = _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194);
        final splits = service.generateSplits('activity1', [point]);
        expect(splits, isEmpty);
      });

      test('generates single split for short distance', () {
        final points = [
          _createTrackPoint(
            sequence: 0,
            lat: 37.7749,
            lon: -122.4194,
            timestamp: DateTime(2023, 1, 1, 10, 0, 0),
          ),
          _createTrackPoint(
            sequence: 1,
            lat: 37.7759,
            lon: -122.4194,
            timestamp: DateTime(2023, 1, 1, 10, 1, 0),
          ),
        ];

        final splits = service.generateSplits('activity1', points);
        expect(splits, hasLength(1));
        
        final split = splits.first;
        expect(split.activityId, equals('activity1'));
        expect(split.splitNumber, equals(1));
        expect(split.distance.meters, greaterThan(100));
        expect(split.distance.meters, lessThan(200));
      });

      test('generates multiple splits for long distance', () {
        // Create points that span approximately 2.5km
        final points = <TrackPoint>[];
        final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
        
        // Generate points every 100m for 2.5km (25 points)
        for (int i = 0; i < 25; i++) {
          points.add(_createTrackPoint(
            sequence: i,
            lat: 37.7749 + (i * 0.001), // ~111m per 0.001 degree
            lon: -122.4194,
            timestamp: baseTime.add(Duration(seconds: i * 30)), // 30 seconds per point
          ));
        }

        final splits = service.generateSplits('activity1', points);
        
        // Should generate 2 complete splits and 1 partial split
        expect(splits.length, greaterThanOrEqualTo(2));
        expect(splits.length, lessThanOrEqualTo(3));
        
        // First split should be approximately 1km
        expect(splits.first.distance.kilometers, greaterThan(0.9));
        expect(splits.first.distance.kilometers, lessThan(1.1));
        expect(splits.first.splitNumber, equals(1));
        
        // Second split should also be approximately 1km
        if (splits.length >= 2) {
          expect(splits[1].distance.kilometers, greaterThan(0.9));
          expect(splits[1].distance.kilometers, lessThan(1.1));
          expect(splits[1].splitNumber, equals(2));
        }
      });

      test('calculates split pace correctly', () {
        final points = [
          _createTrackPoint(
            sequence: 0,
            lat: 37.7749,
            lon: -122.4194,
            timestamp: DateTime(2023, 1, 1, 10, 0, 0),
          ),
          _createTrackPoint(
            sequence: 1,
            lat: 37.7759,
            lon: -122.4194,
            timestamp: DateTime(2023, 1, 1, 10, 1, 0), // 1 minute later
          ),
        ];

        final splits = service.generateSplits('activity1', points);
        expect(splits, hasLength(1));
        
        final split = splits.first;
        expect(split.pace.minutesPerKilometer, greaterThan(5.0)); // Should be reasonable pace
        expect(split.pace.minutesPerKilometer, lessThan(15.0));
      });
    });

    group('calculateMovingAveragePace', () {
      test('returns empty list for empty track points', () {
        final paces = service.calculateMovingAveragePace([]);
        expect(paces, isEmpty);
      });

      test('returns empty list for insufficient track points', () {
        final point = _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194);
        final paces = service.calculateMovingAveragePace([point]);
        expect(paces, isEmpty);
      });

      test('calculates moving average pace correctly', () {
        final baseTime = DateTime(2023, 1, 1, 10, 0, 0);
        final points = [
          _createTrackPoint(
            sequence: 0,
            lat: 37.7749,
            lon: -122.4194,
            timestamp: baseTime,
          ),
          _createTrackPoint(
            sequence: 1,
            lat: 37.7759,
            lon: -122.4194,
            timestamp: baseTime.add(const Duration(seconds: 30)),
          ),
          _createTrackPoint(
            sequence: 2,
            lat: 37.7769,
            lon: -122.4194,
            timestamp: baseTime.add(const Duration(seconds: 60)),
          ),
          _createTrackPoint(
            sequence: 3,
            lat: 37.7779,
            lon: -122.4194,
            timestamp: baseTime.add(const Duration(seconds: 90)),
          ),
        ];

        final paces = service.calculateMovingAveragePace(
          points,
          windowSize: const Duration(seconds: 60),
        );

        expect(paces, isNotEmpty);
        // Each pace should be reasonable
        for (final pace in paces) {
          expect(pace.minutesPerKilometer, greaterThan(1.0));
          expect(pace.minutesPerKilometer, lessThan(20.0));
        }
      });
    });

    group('generateElevationProfile', () {
      test('returns empty list for empty track points', () {
        final profile = service.generateElevationProfile([]);
        expect(profile, isEmpty);
      });

      test('generates elevation profile correctly', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 100),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194, elevation: 120),
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 110),
        ];

        final profile = service.generateElevationProfile(points);
        
        expect(profile, hasLength(3));
        expect(profile[0].distance.meters, equals(0));
        expect(profile[0].elevation.meters, equals(100));
        expect(profile[1].elevation.meters, equals(120));
        expect(profile[2].elevation.meters, equals(110));
        
        // Distances should be cumulative
        expect(profile[1].distance.meters, greaterThan(0));
        expect(profile[2].distance.meters, greaterThan(profile[1].distance.meters));
      });

      test('skips points without elevation data', () {
        final points = [
          _createTrackPoint(sequence: 0, lat: 37.7749, lon: -122.4194, elevation: 100),
          _createTrackPoint(sequence: 1, lat: 37.7759, lon: -122.4194), // no elevation
          _createTrackPoint(sequence: 2, lat: 37.7769, lon: -122.4194, elevation: 120),
        ];

        final profile = service.generateElevationProfile(points);
        
        expect(profile, hasLength(2)); // Only points with elevation
        expect(profile[0].elevation.meters, equals(100));
        expect(profile[1].elevation.meters, equals(120));
      });
    });

    group('updateActivityWithStats', () {
      test('updates activity with calculated statistics', () {
        final points = [
          _createTrackPoint(
            sequence: 0,
            lat: 37.7749,
            lon: -122.4194,
            elevation: 100,
            timestamp: DateTime(2023, 1, 1, 10, 0, 0),
          ),
          _createTrackPoint(
            sequence: 1,
            lat: 37.7759,
            lon: -122.4194,
            elevation: 120,
            timestamp: DateTime(2023, 1, 1, 10, 1, 0),
          ),
        ];

        final activity = Activity(
          id: 'activity1',
          startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
          endTime: Timestamp(DateTime(2023, 1, 1, 10, 1, 0)),
          title: 'Test Run',
          trackPoints: points,
        );

        final updatedActivity = service.updateActivityWithStats(activity);

        expect(updatedActivity.distance.meters, greaterThan(0));
        expect(updatedActivity.elevationGain.meters, equals(20));
        expect(updatedActivity.elevationLoss.meters, equals(0));
        expect(updatedActivity.averagePace, isNotNull);
        expect(updatedActivity.splits, hasLength(1));
      });

      test('handles activity with no track points', () {
        final activity = Activity(
          id: 'activity1',
          startTime: Timestamp(DateTime(2023, 1, 1, 10, 0, 0)),
          title: 'Test Run',
          trackPoints: [],
        );

        final updatedActivity = service.updateActivityWithStats(activity);

        expect(updatedActivity.distance.meters, equals(0));
        expect(updatedActivity.elevationGain.meters, equals(0));
        expect(updatedActivity.elevationLoss.meters, equals(0));
        expect(updatedActivity.averagePace, isNull);
        expect(updatedActivity.splits, isEmpty);
      });
    });
  });
}

TrackPoint _createTrackPoint({
  required int sequence,
  required double lat,
  required double lon,
  double? elevation,
  DateTime? timestamp,
}) {
  return TrackPoint(
    id: 'point_$sequence',
    activityId: 'activity1',
    timestamp: Timestamp(timestamp ?? DateTime.now()),
    coordinates: Coordinates(
      latitude: lat,
      longitude: lon,
      elevation: elevation,
    ),
    accuracy: 5.0,
    source: LocationSource.gps,
    sequence: sequence,
  );
}