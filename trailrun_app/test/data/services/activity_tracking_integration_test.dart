import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import '../../../lib/data/database/database.dart';
import '../../../lib/data/repositories/activity_repository_impl.dart';
import '../../../lib/data/services/activity_tracking_service.dart';
import '../../../lib/data/services/mock_location_service.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/models/track_point.dart';
import '../../../lib/domain/enums/privacy_level.dart';
import '../../../lib/domain/enums/sync_state.dart';
import '../../../lib/domain/enums/location_source.dart';
import '../../../lib/domain/value_objects/measurement_units.dart';
import '../../../lib/domain/value_objects/timestamp.dart';
import '../../../lib/domain/value_objects/coordinates.dart';

void main() {
  group('ActivityTrackingService Integration Tests', () {
    late TrailRunDatabase database;
    late ActivityRepositoryImpl repository;
    late MockLocationService mockLocationService;
    late ActivityTrackingService trackingService;

    setUp(() async {
      database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
      repository = ActivityRepositoryImpl(database: database);
      mockLocationService = MockLocationService();
      
      trackingService = ActivityTrackingService(
        activityRepository: repository,
        locationRepository: mockLocationService,
        autoPauseConfig: const AutoPauseConfig(
          enabled: true,
          speedThreshold: 0.5,
          timeThreshold: Duration(seconds: 2), // Shorter for testing
          resumeSpeedThreshold: 1.0,
        ),
      );
    });

    tearDown(() async {
      trackingService.dispose();
      await database.close();
    });

    group('Activity Lifecycle Integration', () {
      test('should complete full activity lifecycle', () async {
        // Start activity
        final activity = await trackingService.startActivity(
          title: 'Integration Test Run',
          privacy: PrivacyLevel.public,
        );

        expect(activity.title, equals('Integration Test Run'));
        expect(activity.privacy, equals(PrivacyLevel.public));
        expect(activity.isInProgress, isTrue);
        expect(trackingService.state, equals(ActivityTrackingState.active));

        // Verify activity was saved to database
        final savedActivity = await repository.getActivity(activity.id);
        expect(savedActivity, isNotNull);
        expect(savedActivity!.id, equals(activity.id));

        // Simulate location updates
        final trackPoints = [
          TrackPoint(
            id: 'tp1',
            activityId: activity.id,
            timestamp: Timestamp(DateTime.now()),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 0,
          ),
          TrackPoint(
            id: 'tp2',
            activityId: activity.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 30))),
            coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4294, elevation: 120),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          ),
        ];

        // Emit location updates
        for (final point in trackPoints) {
          mockLocationService.emitLocationUpdate(point);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Check statistics are updated
        final stats = trackingService.getCurrentStatistics();
        expect(stats.distance.meters, greaterThan(0));
        expect(stats.elevationGain.meters, equals(20));

        // Pause activity
        await trackingService.pauseActivity();
        expect(trackingService.state, equals(ActivityTrackingState.paused));

        // Resume activity
        await trackingService.resumeActivity();
        expect(trackingService.state, equals(ActivityTrackingState.active));

        // Stop activity
        final stoppedActivity = await trackingService.stopActivity();
        expect(stoppedActivity.isCompleted, isTrue);
        expect(stoppedActivity.endTime, isNotNull);
        expect(stoppedActivity.syncState, equals(SyncState.pending));
        expect(trackingService.state, equals(ActivityTrackingState.stopped));

        // Verify final activity was saved with track points
        final finalActivity = await repository.getActivity(activity.id);
        expect(finalActivity, isNotNull);
        expect(finalActivity!.isCompleted, isTrue);
        expect(finalActivity.trackPoints.length, greaterThan(0));
        expect(finalActivity.distance.meters, greaterThan(0));
      });

      test('should handle crash recovery', () async {
        // Create an in-progress activity directly in database
        final existingActivity = Activity(
          id: 'recovery_test_activity',
          startTime: Timestamp(DateTime.now().subtract(const Duration(minutes: 30))),
          title: 'Recovery Test Run',
          privacy: PrivacyLevel.private,
          syncState: SyncState.local,
        );

        await repository.createActivity(existingActivity);

        // Add some track points
        final trackPoint = TrackPoint(
          id: 'recovery_tp',
          activityId: existingActivity.id,
          timestamp: Timestamp(DateTime.now().subtract(const Duration(minutes: 25))),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        await repository.addTrackPoint(existingActivity.id, trackPoint);

        // Attempt recovery
        final recoveredActivity = await trackingService.recoverInProgressActivity();

        expect(recoveredActivity, isNotNull);
        expect(recoveredActivity!.id, equals('recovery_test_activity'));
        expect(trackingService.currentActivity, equals(recoveredActivity));
        expect(trackingService.state, equals(ActivityTrackingState.paused));

        // Verify statistics are recalculated from existing track points
        final stats = trackingService.getCurrentStatistics();
        expect(stats.duration.inMinutes, greaterThan(0));
      });
    });

    group('Auto-Pause Integration', () {
      test('should auto-pause and resume based on movement', () async {
        // Start activity
        await trackingService.startActivity(title: 'Auto-Pause Test');
        expect(trackingService.state, equals(ActivityTrackingState.active));

        // Simulate slow movement (should trigger auto-pause)
        final baseTime = DateTime.now();
        final slowTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'slow_tp_$index',
          activityId: trackingService.currentActivity!.id,
          timestamp: Timestamp(baseTime.add(Duration(seconds: index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.00001), // Very small movement
            longitude: -122.4194 + (index * 0.00001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        // Emit slow track points
        for (final point in slowTrackPoints) {
          mockLocationService.emitLocationUpdate(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Wait for auto-pause timer
        await Future.delayed(const Duration(seconds: 3));

        expect(trackingService.state, equals(ActivityTrackingState.autoPaused));
        expect(trackingService.isAutoPaused, isTrue);

        // Simulate fast movement (should trigger auto-resume)
        final fastTrackPoints = List.generate(6, (index) => TrackPoint(
          id: 'fast_tp_$index',
          activityId: trackingService.currentActivity!.id,
          timestamp: Timestamp(baseTime.add(Duration(seconds: 10 + index))),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.001), // Larger movement
            longitude: -122.4194 + (index * 0.001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 10 + index,
        ));

        // Emit fast track points
        for (final point in fastTrackPoints) {
          mockLocationService.emitLocationUpdate(point);
          await Future.delayed(const Duration(milliseconds: 100));
        }

        expect(trackingService.state, equals(ActivityTrackingState.active));
        expect(trackingService.isAutoPaused, isFalse);
      });
    });

    group('Statistics Calculation Integration', () {
      test('should calculate real-time statistics correctly', () async {
        // Start activity
        await trackingService.startActivity(title: 'Statistics Test');

        // Create track points with known distances and elevations
        final trackPoints = [
          TrackPoint(
            id: 'stats_tp1',
            activityId: trackingService.currentActivity!.id,
            timestamp: Timestamp(DateTime.now()),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 0,
          ),
          TrackPoint(
            id: 'stats_tp2',
            activityId: trackingService.currentActivity!.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 60))),
            coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4294, elevation: 120),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          ),
          TrackPoint(
            id: 'stats_tp3',
            activityId: trackingService.currentActivity!.id,
            timestamp: Timestamp(DateTime.now().add(const Duration(seconds: 120))),
            coordinates: const Coordinates(latitude: 37.7949, longitude: -122.4394, elevation: 110),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 2,
          ),
        ];

        // Emit track points
        for (final point in trackPoints) {
          mockLocationService.emitLocationUpdate(point);
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Check statistics
        final stats = trackingService.getCurrentStatistics();
        expect(stats.distance.meters, greaterThan(0));
        expect(stats.elevationGain.meters, equals(20)); // 100 -> 120 -> 110 (net gain = 20)
        expect(stats.elevationLoss.meters, equals(10)); // 120 -> 110 (loss = 10)
        expect(stats.duration.inSeconds, greaterThan(0));
        expect(stats.averagePace, isNotNull);
        expect(stats.maxSpeed.metersPerSecond, greaterThan(0));

        // Stop activity and verify final statistics are persisted
        final stoppedActivity = await trackingService.stopActivity();
        expect(stoppedActivity.distance.meters, greaterThan(0));
        expect(stoppedActivity.elevationGain.meters, equals(20));
        expect(stoppedActivity.elevationLoss.meters, equals(10));
      });
    });

    group('State Management Integration', () {
      test('should emit state and activity updates', () async {
        final stateChanges = <ActivityTrackingState>[];
        final activityUpdates = <Activity>[];

        final stateSubscription = trackingService.stateStream.listen(stateChanges.add);
        final activitySubscription = trackingService.activityStream.listen(activityUpdates.add);

        // Perform activity lifecycle
        await trackingService.startActivity(title: 'State Test');
        await trackingService.pauseActivity();
        await trackingService.resumeActivity();
        await trackingService.stopActivity();

        // Allow streams to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify state changes
        expect(stateChanges, contains(ActivityTrackingState.starting));
        expect(stateChanges, contains(ActivityTrackingState.active));
        expect(stateChanges, contains(ActivityTrackingState.paused));
        expect(stateChanges, contains(ActivityTrackingState.stopping));
        expect(stateChanges, contains(ActivityTrackingState.stopped));

        // Verify activity updates
        expect(activityUpdates, hasLength(2));
        expect(activityUpdates.first.isInProgress, isTrue);
        expect(activityUpdates.last.isCompleted, isTrue);

        await stateSubscription.cancel();
        await activitySubscription.cancel();
      });

      test('should emit statistics updates', () async {
        final statisticsUpdates = <ActivityStatistics>[];
        final subscription = trackingService.statisticsStream.listen(statisticsUpdates.add);

        await trackingService.startActivity(title: 'Statistics Stream Test');

        final trackPoint = TrackPoint(
          id: 'stream_tp',
          activityId: trackingService.currentActivity!.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        mockLocationService.emitLocationUpdate(trackPoint);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(statisticsUpdates, isNotEmpty);

        await subscription.cancel();
      });
    });

    group('Database Integration', () {
      test('should persist activity data correctly', () async {
        // Start and complete an activity
        final activity = await trackingService.startActivity(title: 'Persistence Test');

        // Add track points
        final trackPoint = TrackPoint(
          id: 'persist_tp',
          activityId: activity.id,
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        );

        mockLocationService.emitLocationUpdate(trackPoint);
        await Future.delayed(const Duration(milliseconds: 50));

        await trackingService.stopActivity();

        // Verify data persistence
        final savedActivity = await repository.getActivity(activity.id);
        expect(savedActivity, isNotNull);
        expect(savedActivity!.isCompleted, isTrue);
        expect(savedActivity.trackPoints, isNotEmpty);
        expect(savedActivity.distance.meters, greaterThan(0));

        // Verify track points are saved
        final trackPoints = await repository.getTrackPoints(activity.id);
        expect(trackPoints, isNotEmpty);
        expect(trackPoints.first.coordinates.latitude, equals(37.7749));
      });
    });
  });
}