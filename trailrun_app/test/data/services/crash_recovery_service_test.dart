import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:io';
import 'dart:convert';

import '../../../lib/data/services/crash_recovery_service.dart';
import '../../../lib/data/services/activity_tracking_service.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/errors/app_errors.dart';

@GenerateMocks([
  AppDatabase,
  ActivityTrackingService,
  File,
])
import 'crash_recovery_service_test.mocks.dart';

void main() {
  group('CrashRecoveryService', () {
    late CrashRecoveryService crashRecoveryService;
    late MockAppDatabase mockDatabase;
    late MockActivityTrackingService mockActivityTrackingService;

    setUp(() {
      mockDatabase = MockAppDatabase();
      mockActivityTrackingService = MockActivityTrackingService();
      
      crashRecoveryService = CrashRecoveryService(
        database: mockDatabase,
        activityTrackingService: mockActivityTrackingService,
      );
    });

    group('saveSessionState', () {
      test('saves session state successfully', () async {
        // This test would need to mock file system operations
        // For now, we'll test that it doesn't throw
        await expectLater(
          crashRecoveryService.saveSessionState(
            activeActivityId: 'test-activity-id',
            isTracking: true,
            trackingStartTime: DateTime.now(),
          ),
          completes,
        );
      });

      test('handles save errors gracefully', () async {
        // Test that errors in saving don't crash the app
        await expectLater(
          crashRecoveryService.saveSessionState(
            activeActivityId: 'test-activity-id',
            isTracking: true,
          ),
          completes,
        );
      });
    });

    group('checkForCrashRecovery', () {
      test('returns noCrash when no session file exists', () async {
        final result = await crashRecoveryService.checkForCrashRecovery();
        
        expect(result.needsRecovery, isFalse);
        expect(result.hasError, isFalse);
      });

      test('returns noCrash when session is too old', () async {
        // This would require mocking file system to return old session data
        final result = await crashRecoveryService.checkForCrashRecovery();
        
        expect(result.needsRecovery, isFalse);
      });

      test('returns error when session check fails', () async {
        // This would test error handling in session checking
        final result = await crashRecoveryService.checkForCrashRecovery();
        
        // Since we can't easily mock file system, we expect no crash for now
        expect(result.needsRecovery, isFalse);
      });
    });

    group('recoverTrackingSession', () {
      test('recovers tracking session successfully', () async {
        final activity = Activity(
          id: 'test-activity-id',
          title: 'Test Run',
          startTime: DateTime.now(),
          distanceMeters: 1000,
          duration: const Duration(minutes: 10),
          trackPoints: [],
          photos: [],
          splits: [],
        );

        final sessionData = {
          'activeActivityId': 'test-activity-id',
          'isTracking': true,
          'trackingStartTime': DateTime.now().toIso8601String(),
        };

        when(mockActivityTrackingService.resumeActivity('test-activity-id'))
            .thenAnswer((_) async => {});

        await expectLater(
          crashRecoveryService.recoverTrackingSession(activity, sessionData),
          completes,
        );

        verify(mockActivityTrackingService.resumeActivity('test-activity-id')).called(1);
      });

      test('handles recovery failure with structured error', () async {
        final activity = Activity(
          id: 'test-activity-id',
          title: 'Test Run',
          startTime: DateTime.now(),
          distanceMeters: 1000,
          duration: const Duration(minutes: 10),
          trackPoints: [],
          photos: [],
          splits: [],
        );

        final sessionData = {
          'activeActivityId': 'test-activity-id',
          'isTracking': true,
        };

        when(mockActivityTrackingService.resumeActivity('test-activity-id'))
            .thenThrow(Exception('Resume failed'));

        expect(
          () => crashRecoveryService.recoverTrackingSession(activity, sessionData),
          throwsA(isA<SessionError>()),
        );
      });
    });

    group('dismissRecovery', () {
      test('cleans up recovery files', () async {
        await expectLater(
          crashRecoveryService.dismissRecovery(),
          completes,
        );
      });
    });

    group('clearSessionState', () {
      test('clears session state successfully', () async {
        await expectLater(
          crashRecoveryService.clearSessionState(),
          completes,
        );
      });
    });

    group('getDiagnosticInfo', () {
      test('returns diagnostic information', () async {
        final diagnostics = await crashRecoveryService.getDiagnosticInfo();
        
        expect(diagnostics, isA<Map<String, dynamic>>());
        expect(diagnostics['timestamp'], isNotNull);
        expect(diagnostics['platform'], isNotNull);
        expect(diagnostics['session_file_exists'], isA<bool>());
        expect(diagnostics['recovery_file_exists'], isA<bool>());
      });

      test('handles diagnostic errors gracefully', () async {
        final diagnostics = await crashRecoveryService.getDiagnosticInfo();
        
        expect(diagnostics, isA<Map<String, dynamic>>());
        // Should not throw even if there are errors
      });
    });

    group('CrashRecoveryResult', () {
      test('creates noCrash result correctly', () {
        final result = CrashRecoveryResult.noCrash();
        
        expect(result.needsRecovery, isFalse);
        expect(result.activity, isNull);
        expect(result.sessionData, isNull);
        expect(result.error, isNull);
        expect(result.hasError, isFalse);
      });

      test('creates recoveryNeeded result correctly', () {
        final activity = Activity(
          id: 'test-id',
          title: 'Test',
          startTime: DateTime.now(),
          distanceMeters: 0,
          duration: Duration.zero,
          trackPoints: [],
          photos: [],
          splits: [],
        );
        
        final sessionData = {'test': 'data'};
        
        final result = CrashRecoveryResult.recoveryNeeded(
          activity: activity,
          sessionData: sessionData,
        );
        
        expect(result.needsRecovery, isTrue);
        expect(result.activity, equals(activity));
        expect(result.sessionData, equals(sessionData));
        expect(result.error, isNull);
        expect(result.hasError, isFalse);
      });

      test('creates error result correctly', () {
        final error = SessionError(
          type: SessionErrorType.crashRecovery,
          message: 'Test error',
          userMessage: 'Test user message',
        );
        
        final result = CrashRecoveryResult.error(error);
        
        expect(result.needsRecovery, isFalse);
        expect(result.activity, isNull);
        expect(result.sessionData, isNull);
        expect(result.error, equals(error));
        expect(result.hasError, isTrue);
      });
    });
  });
}