import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/data/services/gps_signal_processor.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';

void main() {
  group('GPS Signal Processing Pipeline End-to-End', () {
    late GpsSignalProcessor processor;

    setUp(() {
      processor = GpsSignalProcessor(
        config: const GpsProcessingConfig(
          maxAccuracy: 30.0,
          maxSpeed: 20.0, // 20 m/s = 72 km/h
          enableKalmanFilter: true,
          enableOutlierDetection: true,
          enableGapInterpolation: true,
          minConfidenceScore: 0.3,
        ),
      );
    });

    test('should process a realistic running session', () {
      final baseTime = DateTime.now();
      final startLat = 37.7749;
      final startLon = -122.4194;
      
      final processedPoints = <TrackPoint>[];
      final rejectedPoints = <String>[];
      
      // Simulate a 5-minute running session with various GPS conditions
      final testPoints = [
        // Good start point
        _createPoint(startLat, startLon, 5.0, baseTime),
        
        // Normal running progression (5 m/s = 18 km/h)
        _createPoint(startLat + 0.000045, startLon, 4.0, baseTime.add(const Duration(seconds: 1))),
        _createPoint(startLat + 0.000090, startLon, 3.0, baseTime.add(const Duration(seconds: 2))),
        _createPoint(startLat + 0.000135, startLon, 4.0, baseTime.add(const Duration(seconds: 3))),
        
        // GPS glitch - should be filtered out
        _createPoint(startLat + 0.001000, startLon, 100.0, baseTime.add(const Duration(seconds: 4))),
        
        // Back to normal after glitch
        _createPoint(startLat + 0.000180, startLon, 5.0, baseTime.add(const Duration(seconds: 5))),
        _createPoint(startLat + 0.000225, startLon, 4.0, baseTime.add(const Duration(seconds: 6))),
        
        // Brief signal loss (gap from 6s to 16s)
        _createPoint(startLat + 0.000450, startLon, 6.0, baseTime.add(const Duration(seconds: 16))),
        
        // Continue running
        _createPoint(startLat + 0.000495, startLon, 5.0, baseTime.add(const Duration(seconds: 17))),
        _createPoint(startLat + 0.000540, startLon, 4.0, baseTime.add(const Duration(seconds: 18))),
        
        // Stationary period (stopped at traffic light)
        _createPoint(startLat + 0.000540, startLon, 3.0, baseTime.add(const Duration(seconds: 19))),
        _createPoint(startLat + 0.000540, startLon, 3.0, baseTime.add(const Duration(seconds: 20))),
        _createPoint(startLat + 0.000540, startLon, 4.0, baseTime.add(const Duration(seconds: 21))),
        
        // Resume running
        _createPoint(startLat + 0.000585, startLon, 5.0, baseTime.add(const Duration(seconds: 22))),
        _createPoint(startLat + 0.000630, startLon, 4.0, baseTime.add(const Duration(seconds: 23))),
      ];
      
      // Process all points
      for (final point in testPoints) {
        final result = processor.processPoint(point);
        if (result.isAccepted && result.point != null) {
          processedPoints.add(result.point!);
        } else {
          rejectedPoints.add(result.reason ?? 'Unknown reason');
        }
      }
      
      // Verify processing results
      expect(processedPoints.length, greaterThan(10)); // Most points should be accepted
      expect(rejectedPoints.length, greaterThan(0)); // Some should be filtered
      
      // Check that the GPS glitch was filtered out
      expect(rejectedPoints.any((reason) => reason.contains('Outlier') || reason.contains('confidence')), isTrue);
      
      // Verify Kalman filtering improved accuracy
      final accuracyImprovements = processedPoints.where((point) => point.accuracy < 5.0).length;
      expect(accuracyImprovements, greaterThan(0));
      
      // Check for gap interpolation
      final beforeGap = processedPoints.where((p) => p.timestamp.dateTime.isBefore(baseTime.add(const Duration(seconds: 10)))).last;
      final afterGap = processedPoints.where((p) => p.timestamp.dateTime.isAfter(baseTime.add(const Duration(seconds: 15)))).first;
      
      final interpolatedPoints = processor.interpolateGap(beforeGap, afterGap);
      expect(interpolatedPoints.length, greaterThan(0));
      
      // Verify interpolated points are reasonable
      for (final interpolated in interpolatedPoints) {
        expect(interpolated.source, equals(LocationSource.interpolated));
        expect(interpolated.coordinates.latitude, greaterThan(beforeGap.coordinates.latitude));
        expect(interpolated.coordinates.latitude, lessThan(afterGap.coordinates.latitude));
      }
    });

    test('should handle challenging GPS conditions', () {
      final baseTime = DateTime.now();
      final startLat = 37.7749;
      final startLon = -122.4194;
      
      // Simulate challenging conditions: urban canyon, tunnels, etc.
      final challengingPoints = [
        // Start with good signal
        _createPoint(startLat, startLon, 3.0, baseTime),
        
        // Enter urban canyon - degraded accuracy
        _createPoint(startLat + 0.000045, startLon, 15.0, baseTime.add(const Duration(seconds: 1))),
        _createPoint(startLat + 0.000090, startLon, 25.0, baseTime.add(const Duration(seconds: 2))),
        _createPoint(startLat + 0.000135, startLon, 35.0, baseTime.add(const Duration(seconds: 3))),
        
        // Multipath errors - inconsistent positions
        _createPoint(startLat + 0.000200, startLon + 0.000050, 20.0, baseTime.add(const Duration(seconds: 4))),
        _createPoint(startLat + 0.000150, startLon - 0.000030, 30.0, baseTime.add(const Duration(seconds: 5))),
        _createPoint(startLat + 0.000250, startLon + 0.000020, 25.0, baseTime.add(const Duration(seconds: 6))),
        
        // Exit urban canyon - signal improves
        _createPoint(startLat + 0.000300, startLon, 8.0, baseTime.add(const Duration(seconds: 7))),
        _createPoint(startLat + 0.000345, startLon, 5.0, baseTime.add(const Duration(seconds: 8))),
        _createPoint(startLat + 0.000390, startLon, 4.0, baseTime.add(const Duration(seconds: 9))),
      ];
      
      int acceptedCount = 0;
      int filteredCount = 0;
      double totalConfidence = 0.0;
      
      for (final point in challengingPoints) {
        final result = processor.processPoint(point);
        if (result.isAccepted) {
          acceptedCount++;
        } else {
          filteredCount++;
        }
        totalConfidence += result.confidence.overall;
      }
      
      final averageConfidence = totalConfidence / challengingPoints.length;
      
      // Verify the processor handled challenging conditions appropriately
      expect(acceptedCount, greaterThan(5)); // Should accept reasonable points
      expect(filteredCount, greaterThan(0)); // Should filter problematic points
      expect(averageConfidence, greaterThan(0.2)); // Should maintain some confidence
      expect(averageConfidence, lessThan(0.8)); // But recognize the challenging conditions
    });

    test('should provide comprehensive statistics', () {
      final baseTime = DateTime.now();
      final startLat = 37.7749;
      final startLon = -122.4194;
      
      // Process a mix of good and bad points
      final mixedPoints = [
        // Good points
        _createPoint(startLat, startLon, 3.0, baseTime),
        _createPoint(startLat + 0.000045, startLon, 4.0, baseTime.add(const Duration(seconds: 1))),
        _createPoint(startLat + 0.000090, startLon, 5.0, baseTime.add(const Duration(seconds: 2))),
        
        // Bad points
        _createPoint(startLat, startLon, 200.0, baseTime.add(const Duration(seconds: 3))), // Poor accuracy
        _createPoint(startLat + 0.001000, startLon, 10.0, baseTime.add(const Duration(seconds: 4))), // Impossible jump
        
        // More good points
        _createPoint(startLat + 0.000135, startLon, 6.0, baseTime.add(const Duration(seconds: 5))),
        _createPoint(startLat + 0.000180, startLon, 4.0, baseTime.add(const Duration(seconds: 6))),
      ];
      
      for (final point in mixedPoints) {
        processor.processPoint(point);
      }
      
      final stats = processor.getStats();
      
      expect(stats.totalProcessed, equals(mixedPoints.length));
      expect(stats.filteredOut, greaterThan(0));
      expect(stats.filterRate, greaterThan(0));
      expect(stats.filterRate, lessThan(1));
      expect(stats.averageConfidence, greaterThan(0));
      expect(stats.averageConfidence, lessThan(1));
      
      // Test statistics reset
      processor.resetStats();
      final resetStats = processor.getStats();
      expect(resetStats.totalProcessed, equals(0));
      expect(resetStats.filteredOut, equals(0));
      expect(resetStats.averageConfidence, equals(0));
    });

    test('should demonstrate confidence scoring accuracy', () {
      final baseTime = DateTime.now();
      final startLat = 37.7749;
      final startLon = -122.4194;
      
      // Test different accuracy levels
      final accuracyTests = [
        (3.0, 'Excellent GPS'),
        (8.0, 'Good GPS'),
        (15.0, 'Fair GPS'),
        (30.0, 'Poor GPS'),
        (100.0, 'Very poor GPS'),
      ];
      
      for (int i = 0; i < accuracyTests.length; i++) {
        final (accuracy, description) = accuracyTests[i];
        final point = _createPoint(
          startLat + (i * 0.000045),
          startLon,
          accuracy,
          baseTime.add(Duration(seconds: i)),
        );
        
        final result = processor.processPoint(point);
        
        // Better accuracy should result in higher confidence
        if (accuracy <= 10.0) {
          expect(result.confidence.accuracy, greaterThan(0.7), 
                 reason: '$description should have high accuracy confidence');
        } else if (accuracy <= 30.0) {
          expect(result.confidence.accuracy, greaterThanOrEqualTo(0.4), 
                 reason: '$description should have moderate accuracy confidence');
        } else {
          expect(result.confidence.accuracy, lessThan(0.4), 
                 reason: '$description should have low accuracy confidence');
        }
      }
    });
  });
}

TrackPoint _createPoint(double lat, double lon, double accuracy, DateTime timestamp) {
  return TrackPoint(
    id: 'test-${timestamp.millisecondsSinceEpoch}',
    activityId: 'test-activity',
    timestamp: Timestamp(timestamp),
    coordinates: Coordinates(latitude: lat, longitude: lon),
    accuracy: accuracy,
    source: LocationSource.gps,
    sequence: 0,
  );
}