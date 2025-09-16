import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/domain/domain.dart';

void main() {
  group('Activity Model Tests', () {
    test('should create activity with required fields', () {
      final activity = Activity(
        id: 'test-id',
        startTime: Timestamp.now(),
        title: 'Morning Run',
      );

      expect(activity.id, 'test-id');
      expect(activity.title, 'Morning Run');
      expect(activity.isInProgress, true);
      expect(activity.distance.meters, 0);
      expect(activity.privacy, PrivacyLevel.private);
      expect(activity.syncState, SyncState.local);
    });

    test('should calculate duration correctly', () {
      final startTime = Timestamp.now();
      final endTime = startTime.add(const Duration(hours: 1, minutes: 30));
      
      final activity = Activity(
        id: 'test-id',
        startTime: startTime,
        endTime: endTime,
        title: 'Test Run',
      );

      expect(activity.duration, const Duration(hours: 1, minutes: 30));
      expect(activity.isCompleted, true);
      expect(activity.isInProgress, false);
    });

    test('should handle track points correctly', () {
      final trackPoint = TrackPoint(
        id: 'point-1',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 0,
      );

      final activity = Activity(
        id: 'activity-1',
        startTime: Timestamp.now(),
        title: 'Test Run',
        trackPoints: [trackPoint],
      );

      expect(activity.hasGpsData, true);
      expect(activity.trackPoints.length, 1);
      expect(activity.trackPointsSortedBySequence.first.sequence, 0);
    });
  });

  group('TrackPoint Model Tests', () {
    test('should calculate distance between points', () {
      final point1 = TrackPoint(
        id: 'point-1',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 0,
      );

      final point2 = TrackPoint(
        id: 'point-2',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4194),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: 1,
      );

      final distance = point1.distanceTo(point2);
      expect(distance, greaterThan(1000)); // Should be about 1.1km
      expect(distance, lessThan(1200));
    });
  });

  group('Value Objects Tests', () {
    test('Distance should convert units correctly', () {
      final distance = Distance.kilometers(5.0);
      
      expect(distance.meters, 5000.0);
      expect(distance.kilometers, 5.0);
      expect(distance.miles, closeTo(3.107, 0.01));
    });

    test('Pace should format correctly', () {
      final pace = Pace.minutesPerKilometer(5.5);
      
      expect(pace.formatMinutesSeconds(), '05:30');
      expect(pace.secondsPerKilometer, 330.0);
    });

    test('Coordinates should calculate distance correctly', () {
      const coord1 = Coordinates(latitude: 0, longitude: 0);
      const coord2 = Coordinates(latitude: 0, longitude: 1);
      
      final distance = coord1.distanceTo(coord2);
      expect(distance, greaterThan(110000)); // About 111km at equator
      expect(distance, lessThan(112000));
    });
  });
}