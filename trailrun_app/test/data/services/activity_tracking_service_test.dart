import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../lib/data/services/activity_tracking_service.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/models/track_point.dart';
import '../../../lib/domain/repositories/activity_repository.dart';
import '../../../lib/domain/repositories/location_repository.dart';
import '../../../lib/domain/enums/privacy_level.dart';
import '../../../lib/domain/enums/sync_state.dart';
import '../../../lib/domain/enums/location_source.dart';
import '../../../lib/domain/value_objects/measurement_units.dart';
import '../../../lib/domain/value_objects/timestamp.dart';
import '../../../lib/domain/value_objects/coordinates.dart';

// Mock classes
class MockActivityRepository extends Mock implements ActivityRepository {}
class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  group('ActivityTrackingService', () {
    late ActivityTrackingService service;
    late MockActivityRepository mockActivityRepository;
    late MockLocationRepository mockLocationRepository;
    late StreamController<TrackPoint> locationStreamController;
    late StreamController<LocationTrackingState> locationStateStreamController;

    setUp(() {
      mockActivityRepository = MockActivityRepository();
      mockLocationRepository = MockLocationRepository();
      locationStreamController = StreamController<TrackPoint>.broadcast();
      locationStateStreamController = StreamController<LocationTrackingState>.broadcast();

      // Setup mock streams
      when(() => mockLocationRepository.locationStream)
          .thenAnswer((_) => locationStreamController.stream);
      when(() => mockLocationRepository.trackingStateStream)
          .thenAnswer((_) => locationStateStreamController.stream);

      // Setup default mock responses
      when(() => mockLocationRepository.startLocationTracking(
            accuracy: any(named: 'accuracy'),
            intervalSeconds: any(named: 'intervalSeconds'),
          )).thenAnswer((_) async {});
      when(() => mockLocationRepository.stopLocationTracking())
          .thenAnswer((_) async {});
      when(() => mockLocationRepository.pauseLocationTracking())
          .thenAnswer((_) async {});
      when(() => mockLocationRepository.resumeLocationTracking())
          .thenAnswer((_) async {});

      when(() => mockActivityRepository.createActivity(any()))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as Activity);
      when(() => mockActivityRepository.updateActivity(any()))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as Activity);
      when(() => mockActivityRepository.addTrackPoint(any(), any()))
          .thenAnswer((_) async {});

      service = ActivityTrackingService(
        activityRepository: mockActivityRepository,
        locationRepository: mockLocationRepository,
        autoPauseConfig: const AutoPauseConfig(
          enabled: true,
          speedThreshold: 0.5,
          timeThreshold: Duration(seconds: 2), // Shorter for testing
          resumeSpeedThreshold: 1.0,
        ),
      );
    });

    tearDown(() {
      locationStreamController.close();
      locationStateStreamController.close();
      service.dispose();
    });

    group('Activity Lifecycle', () {
      test('should start new activity successfully', () async {
        // Act
        final activity = await service.startActivity(
          title: 'Test Run',
          privacy: PrivacyLevel.public,
        );

        // Assert
        expect(activity.title, equals('Test Run'));
        expect(activity.privacy, equals(PrivacyLevel.public));
        expect(activity.isInProgress, isTrue);
        expect(service.state, equals(ActivityTrackingState.active));
        expect(service.currentActivity, equals(activity));

        verify(() => mockActivityRepository.createActivity(any())).called(1);
        verify(() => mockLocationRepository.startLocationTracking(
              accuracy: LocationAccuracy.high,
              intervalSeconds: 2,
            )).called(1);
      });

      test('should not start activity when already tracking', () async {
        // Arrange
        await service.startActivity(title: 'First Run');

        // Act & Assert
        expect(
          () => service.startActivity(title: 'Second Run'),
          throwsA(isA<StateError>()),
        );
      });

      test('should pause activity successfully', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');

        // Act
        await service.pauseActivity();

        // Assert
        expect(service.state, equals(ActivityTrackingState.paused));
        verify(() => mockLocationRepository.pauseLocationTracking()).called(1);
      });

      test('should resume activity successfully', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        await service.pauseActivity();

        // Act
        await service.resumeActivity();

        // Assert
        expect(service.state, equals(ActivityTrackingState.active));
        verify(() => mockLocationRepository.resumeLocationTracking()).called(1);
      });

      test('should stop activity successfully', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');

        // Act
        final stoppedActivity = await service.stopActivity();

        // Assert
        expect(stoppedActivity.isCompleted, isTrue);
        expect(stoppedActivity.endTime, isNotNull);
        expect(stoppedActivity.syncState, equals(SyncState.pending));
        expect(service.state, equals(ActivityTrackingState.stopped));

        verify(() => mockLocationRepository.stopLocationTracking()).called(1);
        verify(() => mockActivityRepository.updateActivity(any())).called(1);
      });

      test('should not stop when no active activity', () async {
        // Act & Assert
        expect(
          () => service.stopActivity(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Location Tracking', () {
      test('should process location updates and update statistics', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        
        final trackPoint1 = TrackPoint(
          id: 'tp1',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        final trackPoint2 = TrackPoint(
          id: 'tp2',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 30))),
          coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4294, elevation: 120),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        );

        // Act
        locationStreamController.add(trackPoint1);
        await Future.delayed(const Duration(milliseconds: 10));
        locationStreamController.add(trackPoint2);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        final stats = service.getCurrentStatistics();
        expect(stats.distance.meters, greaterThan(0));
        expect(stats.elevationGain.meters, equals(20));
        expect(stats.currentSpeed.metersPerSecond, greaterThan(0));

        verify(() => mockActivityRepository.addTrackPoint(any(), any())).called(2);
      });

      test('should handle location errors', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');

        // Act
        locationStreamController.addError('Location error');
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(service.state, equals(ActivityTrackingState.error));
      });

      test('should ignore location updates when paused', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        await service.pauseActivity();

        final trackPoint = TrackPoint(
          id: 'tp1',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        // Act
        locationStreamController.add(trackPoint);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        verifyNever(() => mockActivityRepository.addTrackPoint(any(), any()));
      });
    });

    group('Auto-Pause Functionality', () {
      test('should auto-pause when speed is below threshold', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        
        final baseTime = DateTime.now();
        final slowTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'tp_slow_$index',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(baseTime.add(Duration(seconds: index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.00001), // Very small movement
            longitude: -122.4194 + (index * 0.00001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        // Act - Send slow track points
        for (final point in slowTrackPoints) {
          locationStreamController.add(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for auto-pause timer
        await Future.delayed(const Duration(seconds: 3));

        // Assert
        expect(service.state, equals(ActivityTrackingState.autoPaused));
        expect(service.isAutoPaused, isTrue);
      });

      test('should auto-resume when speed increases', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        
        // First, trigger auto-pause with slow movement
        final baseTime = DateTime.now();
        final slowTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'tp_slow_$index',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(baseTime.add(Duration(seconds: index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.00001),
            longitude: -122.4194 + (index * 0.00001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        for (final point in slowTrackPoints) {
          locationStreamController.add(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }
        await Future.delayed(const Duration(seconds: 3));

        expect(service.state, equals(ActivityTrackingState.autoPaused));

        // Now send fast track points to trigger auto-resume
        final fastTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'tp_fast_$index',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(baseTime.add(Duration(seconds: 10 + index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.001), // Larger movement
            longitude: -122.4194 + (index * 0.001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 10 + index,
        ));

        // Act
        for (final point in fastTrackPoints) {
          locationStreamController.add(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Assert
        expect(service.state, equals(ActivityTrackingState.active));
        expect(service.isAutoPaused, isFalse);
      });

      test('should not auto-pause when disabled', () async {
        // Arrange
        final serviceWithoutAutoPause = ActivityTrackingService(
          activityRepository: mockActivityRepository,
          locationRepository: mockLocationRepository,
          autoPauseConfig: const AutoPauseConfig(enabled: false),
        );

        await serviceWithoutAutoPause.startActivity(title: 'Test Run');
        
        final slowTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'tp_slow_$index',
          activityId: serviceWithoutAutoPause.currentActivity!.id,
          timestamp: Timestamp(DateTime.now().add(Duration(seconds: index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.00001),
            longitude: -122.4194 + (index * 0.00001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        // Act
        for (final point in slowTrackPoints) {
          locationStreamController.add(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }
        await Future.delayed(const Duration(seconds: 3));

        // Assert
        expect(serviceWithoutAutoPause.state, equals(ActivityTrackingState.active));
        expect(serviceWithoutAutoPause.isAutoPaused, isFalse);

        serviceWithoutAutoPause.dispose();
      });
    });

    group('Statistics Calculation', () {
      test('should calculate real-time statistics correctly', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        
        final trackPoints = [
          TrackPoint(
            id: 'tp1',
            activityId: service.currentActivity!.id,
            timestamp: Timestamp(DateTime.now()),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 0,
          ),
          TrackPoint(
            id: 'tp2',
            activityId: service.currentActivity!.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 60))),
            coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4294, elevation: 120),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          ),
          TrackPoint(
            id: 'tp3',
            activityId: service.currentActivity!.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 120))),
            coordinates: const Coordinates(latitude: 37.7949, longitude: -122.4394, elevation: 110),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 2,
          ),
        ];

        // Act
        for (final point in trackPoints) {
          locationStreamController.add(point);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Assert
        final stats = service.getCurrentStatistics();
        expect(stats.distance.meters, greaterThan(0));
        expect(stats.elevationGain.meters, equals(20));
        expect(stats.elevationLoss.meters, equals(10));
        expect(stats.duration.inSeconds, greaterThan(0));
        expect(stats.averagePace, isNotNull);
        expect(stats.maxSpeed.metersPerSecond, greaterThan(0));
      });

      test('should emit statistics updates', () async {
        // Arrange
        await service.startActivity(title: 'Test Run');
        
        final statisticsUpdates = <ActivityStatistics>[];
        final subscription = service.statisticsStream.listen(statisticsUpdates.add);

        final trackPoint = TrackPoint(
          id: 'tp1',
          activityId: service.currentActivity!.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        // Act
        locationStreamController.add(trackPoint);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(statisticsUpdates, isNotEmpty);
        
        await subscription.cancel();
      });
    });

    group('Crash Recovery', () {
      test('should recover in-progress activity', () async {
        // Arrange
        final existingActivity = Activity(
          id: 'existing_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(minutes: 30))),
          title: 'Recovered Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
          trackPoints: [
            TrackPoint(
              id: 'existing_tp',
              activityId: 'existing_activity',
              timestamp: Timestamp(DateTime.now().subtract(const Duration(minutes: 25))),
              coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
              accuracy: 5.0,
              source: LocationSource.gps,
              sequence: 0,
            ),
          ],
        );

        when(() => mockActivityRepository.getActiveActivity())
            .thenAnswer((_) async => existingActivity);

        // Act
        final recoveredActivity = await service.recoverInProgressActivity();

        // Assert
        expect(recoveredActivity, isNotNull);
        expect(recoveredActivity!.id, equals('existing_activity'));
        expect(service.currentActivity, equals(recoveredActivity));
        expect(service.state, equals(ActivityTrackingState.paused));
      });

      test('should return null when no active activity to recover', () async {
        // Arrange
        when(() => mockActivityRepository.getActiveActivity())
            .thenAnswer((_) async => null);

        // Act
        final recoveredActivity = await service.recoverInProgressActivity();

        // Assert
        expect(recoveredActivity, isNull);
        expect(service.currentActivity, isNull);
        expect(service.state, equals(ActivityTrackingState.stopped));
      });
    });

    group('State Management', () {
      test('should emit state changes', () async {
        // Arrange
        final stateChanges = <ActivityTrackingState>[];
        final subscription = service.stateStream.listen(stateChanges.add);

        // Act
        await service.startActivity(title: 'Test Run');
        await service.pauseActivity();
        await service.resumeActivity();
        await service.stopActivity();

        // Assert
        expect(stateChanges, contains(ActivityTrackingState.starting));
        expect(stateChanges, contains(ActivityTrackingState.active));
        expect(stateChanges, contains(ActivityTrackingState.paused));
        expect(stateChanges, contains(ActivityTrackingState.stopping));
        expect(stateChanges, contains(ActivityTrackingState.stopped));

        await subscription.cancel();
      });

      test('should emit activity updates', () async {
        // Arrange
        final activityUpdates = <Activity>[];
        final subscription = service.activityStream.listen(activityUpdates.add);

        // Act
        await service.startActivity(title: 'Test Run');
        await service.stopActivity();

        // Assert
        expect(activityUpdates, hasLength(2));
        expect(activityUpdates.first.isInProgress, isTrue);
        expect(activityUpdates.last.isCompleted, isTrue);

        await subscription.cancel();
      });
    });
  });
}