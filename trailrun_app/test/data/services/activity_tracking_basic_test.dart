import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import '../../../lib/data/database/database.dart';
import '../../../lib/data/repositories/activity_repository_impl.dart';
import '../../../lib/data/services/activity_tracking_service.dart';
import '../../../lib/data/services/mock_location_service.dart';
import '../../../lib/domain/enums/privacy_level.dart';

void main() {
  group('ActivityTrackingService Basic Tests', () {
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
      );
    });

    tearDown(() async {
      trackingService.dispose();
      await database.close();
    });

    test('should start and stop activity successfully', () async {
      // Start activity
      final activity = await trackingService.startActivity(
        title: 'Basic Test Run',
        privacy: PrivacyLevel.private,
      );

      expect(activity.title, equals('Basic Test Run'));
      expect(activity.privacy, equals(PrivacyLevel.private));
      expect(activity.isInProgress, isTrue);
      expect(trackingService.state, equals(ActivityTrackingState.active));
      expect(trackingService.currentActivity, equals(activity));

      // Verify activity was saved to database
      final savedActivity = await repository.getActivity(activity.id);
      expect(savedActivity, isNotNull);
      expect(savedActivity!.id, equals(activity.id));

      // Stop activity
      final stoppedActivity = await trackingService.stopActivity();
      expect(stoppedActivity.isCompleted, isTrue);
      expect(stoppedActivity.endTime, isNotNull);
      expect(trackingService.state, equals(ActivityTrackingState.stopped));

      // Verify final activity was saved
      final finalActivity = await repository.getActivity(activity.id);
      expect(finalActivity, isNotNull);
      expect(finalActivity!.isCompleted, isTrue);
    });

    test('should handle pause and resume', () async {
      // Start activity
      await trackingService.startActivity(title: 'Pause Test');
      expect(trackingService.state, equals(ActivityTrackingState.active));

      // Pause activity
      await trackingService.pauseActivity();
      expect(trackingService.state, equals(ActivityTrackingState.paused));

      // Resume activity
      await trackingService.resumeActivity();
      expect(trackingService.state, equals(ActivityTrackingState.active));

      // Stop activity
      await trackingService.stopActivity();
      expect(trackingService.state, equals(ActivityTrackingState.stopped));
    });

    test('should calculate basic statistics', () async {
      // Start activity
      await trackingService.startActivity(title: 'Stats Test');

      // Get initial statistics
      final initialStats = trackingService.getCurrentStatistics();
      expect(initialStats.distance.meters, equals(0));
      expect(initialStats.elevationGain.meters, equals(0));
      expect(initialStats.elevationLoss.meters, equals(0));

      // Stop activity
      await trackingService.stopActivity();
    });

    test('should emit state changes', () async {
      final stateChanges = <ActivityTrackingState>[];
      final subscription = trackingService.stateStream.listen(stateChanges.add);

      // Perform activity lifecycle
      await trackingService.startActivity(title: 'State Test');
      await trackingService.pauseActivity();
      await trackingService.resumeActivity();
      await trackingService.stopActivity();

      // Allow streams to emit
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify state changes were emitted
      expect(stateChanges, isNotEmpty);
      expect(stateChanges, contains(ActivityTrackingState.active));
      expect(stateChanges, contains(ActivityTrackingState.paused));
      expect(stateChanges, contains(ActivityTrackingState.stopped));

      await subscription.cancel();
    });

    test('should not start activity when already tracking', () async {
      // Start first activity
      await trackingService.startActivity(title: 'First Run');

      // Try to start second activity
      expect(
        () => trackingService.startActivity(title: 'Second Run'),
        throwsA(isA<StateError>()),
      );

      // Clean up
      await trackingService.stopActivity();
    });

    test('should not stop when no active activity', () async {
      // Try to stop when no activity is active
      expect(
        () => trackingService.stopActivity(),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle recovery when no active activity exists', () async {
      // Attempt recovery when no active activity exists
      final recoveredActivity = await trackingService.recoverInProgressActivity();
      expect(recoveredActivity, isNull);
      expect(trackingService.currentActivity, isNull);
      expect(trackingService.state, equals(ActivityTrackingState.stopped));
    });
  });
}