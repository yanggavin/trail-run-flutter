import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/data/services/gps_signal_processor.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';

void main() {
  group('GpsSignalProcessor', () {
    late GpsSignalProcessor processor;

    setUp(() {
      processor = GpsSignalProcessor();
    });

    group('Confidence Scoring', () {
      test('should give high confidence to accurate GPS points', () {
        final point = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 3.0,
          timestamp: DateTime.now(),
        );

        final result = processor.processPoint(point);

        expect(result.isAccepted, isTrue);
        expect(result.confidence.accuracy, greaterThan(0.8));
        expect(result.confidence.overall, greaterThan(0.7));
      });

      test('should give low confidence to inaccurate GPS points', () {
        final point = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 100.0,
          timestamp: DateTime.now(),
        );

        final result = processor.processPoint(point);

        expect(result.confidence.accuracy, lessThan(0.3));
      });

      test('should detect unrealistic speed changes', () {
        final baseTime = DateTime.now();
        
        // First point
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        // Second point with impossible speed (1000m in 1 second = 1000 m/s)
        final point2 = _createTrackPoint(
          latitude: 37.7840, // ~1000m north
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        );

        final result = processor.processPoint(point2);
        expect(result.confidence.speed, lessThan(0.2));
      });

      test('should reward consistent movement patterns', () {
        final baseTime = DateTime.now();
        final baseLatitude = 37.7749;
        final baseLongitude = -122.4194;
        
        // Start with stationary points to establish baseline
        final point1 = _createTrackPoint(
          latitude: baseLatitude,
          longitude: baseLongitude,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        final point2 = _createTrackPoint(
          latitude: baseLatitude,
          longitude: baseLongitude,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        );
        final result2 = processor.processPoint(point2);
        
        // For stationary points, consistency should be high
        expect(result2.confidence.consistency, greaterThanOrEqualTo(0.8));
      });
    });

    group('Outlier Detection', () {
      test('should filter out points with impossible distance jumps', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableOutlierDetection: true,
            maxJumpDistance: 100.0,
          ),
        );

        final baseTime = DateTime.now();
        
        // First point in San Francisco
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        final result1 = processor.processPoint(point1);
        expect(result1.isAccepted, isTrue);

        // Second point in New York (impossible jump)
        final point2 = _createTrackPoint(
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        );

        final result2 = processor.processPoint(point2);
        expect(result2.isAccepted, isFalse);
        expect(result2.reason, contains('Outlier'));
      });

      test('should filter out points with impossible speeds', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableOutlierDetection: true,
            maxSpeed: 20.0, // 20 m/s max
          ),
        );

        final baseTime = DateTime.now();
        
        // First point
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        // Second point with speed > 20 m/s
        final point2 = _createTrackPoint(
          latitude: 37.7749 + 0.0002, // ~22m north
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        );

        final result = processor.processPoint(point2);
        expect(result.isAccepted, isFalse);
      });

      test('should accept realistic movement', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableOutlierDetection: true,
            maxSpeed: 20.0,
          ),
        );

        final baseTime = DateTime.now();
        
        // First point
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        // Second point with realistic running speed (~5 m/s)
        final point2 = _createTrackPoint(
          latitude: 37.7749 + 0.000045, // ~5m north
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        );

        final result = processor.processPoint(point2);
        expect(result.isAccepted, isTrue);
      });
    });

    group('Kalman Filtering', () {
      test('should smooth GPS coordinates', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableKalmanFilter: true,
            kalmanProcessNoise: 0.1,
          ),
        );

        final baseTime = DateTime.now();
        final trueLat = 37.7749;
        final trueLon = -122.4194;
        
        // First point (initialization)
        final point1 = _createTrackPoint(
          latitude: trueLat,
          longitude: trueLon,
          accuracy: 5.0,
          timestamp: baseTime,
        );
        final result1 = processor.processPoint(point1);
        expect(result1.isAccepted, isTrue);

        // Second point with some noise
        final noisyLat = trueLat + 0.0001; // Add noise
        final point2 = _createTrackPoint(
          latitude: noisyLat,
          longitude: trueLon,
          accuracy: 10.0,
          timestamp: baseTime.add(const Duration(seconds: 2)),
        );

        final result2 = processor.processPoint(point2);
        expect(result2.isAccepted, isTrue);
        
        // Filtered point should be closer to true position than noisy input
        final filteredLat = result2.point!.coordinates.latitude;
        final noiseDifference = (noisyLat - trueLat).abs();
        final filteredDifference = (filteredLat - trueLat).abs();
        
        expect(filteredDifference, lessThan(noiseDifference));
      });

      test('should improve accuracy estimate', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableKalmanFilter: true,
          ),
        );

        final baseTime = DateTime.now();
        
        // First point
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 10.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        // Second point
        final point2 = _createTrackPoint(
          latitude: 37.7749 + 0.00001,
          longitude: -122.4194,
          accuracy: 10.0,
          timestamp: baseTime.add(const Duration(seconds: 2)),
        );

        final result = processor.processPoint(point2);
        expect(result.isAccepted, isTrue);
        
        // Filtered accuracy should be better than input
        expect(result.point!.accuracy, lessThan(10.0));
      });
    });

    group('Gap Interpolation', () {
      test('should interpolate points for reasonable gaps', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableGapInterpolation: true,
            maxGapDuration: Duration(seconds: 30),
          ),
        );

        final baseTime = DateTime.now();
        
        // Point before gap
        final beforeGap = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );

        // Point after gap (20 seconds later, 100m away)
        final afterGap = _createTrackPoint(
          latitude: 37.7749 + 0.0009, // ~100m north
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 20)),
        );

        final interpolatedPoints = processor.interpolateGap(beforeGap, afterGap);
        
        expect(interpolatedPoints, isNotEmpty);
        expect(interpolatedPoints.length, greaterThan(0));
        
        // Check that interpolated points are between start and end
        for (final point in interpolatedPoints) {
          expect(point.coordinates.latitude, 
                 greaterThan(beforeGap.coordinates.latitude));
          expect(point.coordinates.latitude, 
                 lessThan(afterGap.coordinates.latitude));
          expect(point.source, equals(LocationSource.interpolated));
        }
      });

      test('should not interpolate gaps that are too large', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableGapInterpolation: true,
            maxGapDuration: Duration(seconds: 30),
          ),
        );

        final baseTime = DateTime.now();
        
        // Point before gap
        final beforeGap = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );

        // Point after gap (60 seconds later - too long)
        final afterGap = _createTrackPoint(
          latitude: 37.7749 + 0.0009,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 60)),
        );

        final interpolatedPoints = processor.interpolateGap(beforeGap, afterGap);
        expect(interpolatedPoints, isEmpty);
      });

      test('should not interpolate gaps with unrealistic speeds', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableGapInterpolation: true,
            maxSpeed: 20.0,
          ),
        );

        final baseTime = DateTime.now();
        
        // Point before gap
        final beforeGap = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime,
        );

        // Point after gap with impossible speed (1000m in 10 seconds)
        final afterGap = _createTrackPoint(
          latitude: 37.7749 + 0.009, // ~1000m north
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: baseTime.add(const Duration(seconds: 10)),
        );

        final interpolatedPoints = processor.interpolateGap(beforeGap, afterGap);
        expect(interpolatedPoints, isEmpty);
      });
    });

    group('Statistics', () {
      test('should track processing statistics', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            maxAccuracy: 20.0,
            minConfidenceScore: 0.8, // High threshold to ensure filtering
          ),
        );

        final baseTime = DateTime.now();
        int acceptedCount = 0;
        int filteredCount = 0;
        
        // Process some good points
        for (int i = 0; i < 5; i++) {
          final point = _createTrackPoint(
            latitude: 37.7749 + (i * 0.00001),
            longitude: -122.4194,
            accuracy: 3.0, // Very good accuracy
            timestamp: baseTime.add(Duration(seconds: i)),
          );
          final result = processor.processPoint(point);
          if (result.isAccepted) acceptedCount++;
        }

        // Process some bad points that should definitely be filtered
        for (int i = 0; i < 3; i++) {
          final point = _createTrackPoint(
            latitude: 37.7749,
            longitude: -122.4194,
            accuracy: 200.0, // Very poor accuracy
            timestamp: baseTime.add(Duration(seconds: 10 + i)),
          );
          final result = processor.processPoint(point);
          if (!result.isAccepted) filteredCount++;
        }

        final stats = processor.getStats();
        expect(stats.totalProcessed, equals(8));
        expect(filteredCount, greaterThan(0)); // At least some should be filtered
        expect(stats.averageConfidence, greaterThan(0));
      });

      test('should reset statistics', () {
        final processor = GpsSignalProcessor();
        
        // Process some points
        final point = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        processor.processPoint(point);

        var stats = processor.getStats();
        expect(stats.totalProcessed, greaterThan(0));

        // Reset and check
        processor.resetStats();
        stats = processor.getStats();
        expect(stats.totalProcessed, equals(0));
        expect(stats.filteredOut, equals(0));
      });
    });

    group('Configuration', () {
      test('should respect accuracy threshold', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            maxAccuracy: 10.0,
            minConfidenceScore: 0.1, // Low threshold to test accuracy specifically
          ),
        );

        // Point with good accuracy
        final goodPoint = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
        );
        final goodResult = processor.processPoint(goodPoint);
        expect(goodResult.isAccepted, isTrue);

        // Point with poor accuracy
        final badPoint = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 50.0,
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
        );
        final badResult = processor.processPoint(badPoint);
        expect(badResult.confidence.accuracy, lessThan(0.5));
      });

      test('should allow disabling Kalman filter', () {
        final processor = GpsSignalProcessor(
          config: const GpsProcessingConfig(
            enableKalmanFilter: false,
          ),
        );

        final baseTime = DateTime.now();
        
        // First point
        final point1 = _createTrackPoint(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 10.0,
          timestamp: baseTime,
        );
        processor.processPoint(point1);

        // Second point
        final point2 = _createTrackPoint(
          latitude: 37.7749 + 0.00001,
          longitude: -122.4194,
          accuracy: 10.0,
          timestamp: baseTime.add(const Duration(seconds: 2)),
        );

        final result = processor.processPoint(point2);
        expect(result.isAccepted, isTrue);
        
        // Without Kalman filter, accuracy should be unchanged
        expect(result.point!.accuracy, equals(10.0));
      });
    });
  });
}

TrackPoint _createTrackPoint({
  required double latitude,
  required double longitude,
  double? elevation,
  required double accuracy,
  required DateTime timestamp,
  LocationSource source = LocationSource.gps,
  String activityId = 'test-activity',
  int sequence = 0,
}) {
  return TrackPoint(
    id: 'test-${timestamp.millisecondsSinceEpoch}',
    activityId: activityId,
    timestamp: Timestamp(timestamp),
    coordinates: Coordinates(
      latitude: latitude,
      longitude: longitude,
      elevation: elevation,
    ),
    accuracy: accuracy,
    source: source,
    sequence: sequence,
  );
}