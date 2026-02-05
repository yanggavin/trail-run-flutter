import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

import '../../lib/domain/errors/app_errors.dart' as domain_errors;
import '../../lib/data/services/error_handler.dart' as service_error;
import '../../lib/data/services/crash_recovery_service.dart';
import '../../lib/data/services/graceful_degradation_service.dart';
import '../../lib/presentation/widgets/error_dialog.dart';
import '../../lib/presentation/widgets/crash_recovery_dialog.dart';
import '../../lib/presentation/widgets/gps_diagnostics_widget.dart';
import '../../lib/presentation/widgets/permission_degradation_widget.dart';
import '../../lib/presentation/providers/error_provider.dart' as error_provider;
import '../../lib/data/services/platform_permission_service.dart';
import '../../lib/data/services/location_service.dart' as location_service;
import '../../lib/data/services/camera_service.dart';
import '../../lib/data/services/gps_diagnostics_service.dart';
import '../../lib/domain/models/activity.dart';
import '../../lib/domain/value_objects/measurement_units.dart';
import '../../lib/domain/value_objects/timestamp.dart';

@GenerateMocks([
  PlatformPermissionService,
  location_service.LocationService,
  CameraService,
  GpsDiagnosticsService,
  CrashRecoveryService,
  GracefulDegradationService,
])
import 'error_handling_integration_test.mocks.dart';

void main() {
  group('Error Handling Integration Tests', () {
    late MockPlatformPermissionService mockPermissionService;
    late MockLocationService mockLocationService;
    late MockCameraService mockCameraService;
    late MockGpsDiagnosticsService mockGpsDiagnosticsService;
    late MockCrashRecoveryService mockCrashRecoveryService;
    late MockGracefulDegradationService mockGracefulDegradationService;

    setUp(() {
      mockPermissionService = MockPlatformPermissionService();
      mockLocationService = MockLocationService();
      mockCameraService = MockCameraService();
      mockGpsDiagnosticsService = MockGpsDiagnosticsService();
      mockCrashRecoveryService = MockCrashRecoveryService();
      mockGracefulDegradationService = MockGracefulDegradationService();
    });

    group('Error Dialog Integration', () {
      testWidgets('displays location error with recovery actions', (tester) async {
        final locationError = domain_errors.LocationError(
          type: domain_errors.LocationErrorType.permissionDenied,
          message: 'Location permission denied',
          userMessage: 'Location permission is required to track your runs.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Grant Permission',
              description: 'Allow location access in app settings',
              action: () async {},
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorDialog.show(context, locationError),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        // Tap to show error dialog
        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Verify error dialog is displayed
        expect(find.byType(ErrorDialog), findsOneWidget);
        expect(find.text('Location Issue'), findsOneWidget);
        expect(find.text('Location permission is required to track your runs.'), findsOneWidget);
        expect(find.text('Grant Permission'), findsOneWidget);
        expect(find.text('Allow location access in app settings'), findsOneWidget);
      });

      testWidgets('displays camera error with recovery actions', (tester) async {
        final cameraError = domain_errors.CameraError(
          type: domain_errors.CameraErrorType.permissionDenied,
          message: 'Camera permission denied',
          userMessage: 'Camera permission is required to take photos during runs.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Grant Permission',
              description: 'Allow camera access in app settings',
              action: () async {},
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorDialog.show(context, cameraError),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorDialog), findsOneWidget);
        expect(find.text('Camera Issue'), findsOneWidget);
        expect(find.text('Camera permission is required to take photos during runs.'), findsOneWidget);
      });

      testWidgets('displays storage error with destructive recovery action', (tester) async {
        final storageError = domain_errors.StorageError(
          type: domain_errors.StorageErrorType.diskFull,
          message: 'Insufficient storage space',
          userMessage: 'Your device is running low on storage space.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Delete Old Activities',
              description: 'Remove old TrailRun activities to save space',
              action: () async {},
              isDestructive: true,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorDialog.show(context, storageError),
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.byType(ErrorDialog), findsOneWidget);
        expect(find.text('Storage Issue'), findsOneWidget);
        expect(find.text('Delete Old Activities'), findsOneWidget);
      });
    });

    group('Crash Recovery Dialog Integration', () {
      testWidgets('displays crash recovery dialog with activity details', (tester) async {
        final activityStart = Timestamp.fromMilliseconds(
          DateTime.now().subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
        );
        final activityEnd = activityStart.add(const Duration(minutes: 25));
        final activity = Activity(
          id: 'test-activity-id',
          title: 'Morning Run',
          startTime: activityStart,
          endTime: activityEnd,
          distance: Distance.meters(2500),
          elevationGain: Elevation.meters(0),
          elevationLoss: Elevation.meters(0),
          trackPoints: [],
          photos: [],
          splits: [],
        );

        final sessionData = {
          'activeActivityId': 'test-activity-id',
          'isTracking': true,
          'trackingStartTime': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        };

        bool recoverCalled = false;
        bool dismissCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CrashRecoveryDialog.show(
                    context,
                    activity: activity,
                    sessionData: sessionData,
                    onRecover: () => recoverCalled = true,
                    onDismiss: () => dismissCalled = true,
                  ),
                  child: const Text('Show Recovery'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Recovery'));
        await tester.pumpAndSettle();

        // Verify crash recovery dialog is displayed
        expect(find.byType(CrashRecoveryDialog), findsOneWidget);
        expect(find.text('Recover Previous Run?'), findsOneWidget);
        expect(find.text('Morning Run'), findsOneWidget);
        expect(find.text('2.50 km'), findsOneWidget);
        expect(find.text('Continue Run'), findsOneWidget);
        expect(find.text('Start Fresh'), findsOneWidget);
        expect(find.text('View Activity'), findsOneWidget);

        // Test recovery action
        await tester.tap(find.text('Continue Run'));
        await tester.pumpAndSettle();
        expect(recoverCalled, isTrue);
      });
    });

    group('GPS Diagnostics Widget Integration', () {
      testWidgets('displays GPS diagnostics information', (tester) async {
        final diagnostics = GpsDiagnostics()
          ..isLocationServiceEnabled = true
          ..locationPermission = LocationPermission.always
          ..gpsSignalQuality = GpsSignalQuality.good
          ..deviceInfo = {
            'platform': 'Android',
            'model': 'Test Device',
            'version': '12',
          }
          ..lastKnownPosition = {
            'latitude': 37.7749,
            'longitude': -122.4194,
            'accuracy': 5.0,
          }
          ..networkConnectivity = 'Connected'
          ..timestamp = DateTime.now();

        when(mockGpsDiagnosticsService.getDiagnostics())
            .thenAnswer((_) async => diagnostics);
        when(mockGpsDiagnosticsService.getTroubleshootingSteps())
            .thenAnswer((_) async => [
              TroubleshootingStep(
                title: 'GPS is Working Well',
                description: 'Your GPS setup looks good for tracking runs.',
                action: 'If you experience issues, try restarting the app.',
                priority: TroubleshootingPriority.info,
              ),
            ]);

        await tester.pumpWidget(
          MaterialApp(
            home: GpsDiagnosticsWidget(
              diagnosticsService: mockGpsDiagnosticsService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify GPS diagnostics are displayed
        expect(find.text('GPS Diagnostics'), findsOneWidget);
        expect(find.text('GPS is Working'), findsOneWidget);
        expect(find.text('Location Services: Enabled'), findsOneWidget);
        expect(find.text('GPS is Working Well'), findsOneWidget);
      });

      testWidgets('displays GPS test results', (tester) async {
        final diagnostics = GpsDiagnostics()
          ..isLocationServiceEnabled = true
          ..locationPermission = LocationPermission.always;

        final testResult = GpsTestResult()
          ..startTime = DateTime.now().subtract(const Duration(minutes: 1))
          ..endTime = DateTime.now()
          ..totalReadings = 45
          ..averageAccuracy = 8.5
          ..bestAccuracy = 3.2
          ..worstAccuracy = 15.8
          ..signalStability = 'Stable'
          ..recommendations = ['GPS performance looks good for tracking runs.'];

        when(mockGpsDiagnosticsService.getDiagnostics())
            .thenAnswer((_) async => diagnostics);
        when(mockGpsDiagnosticsService.getTroubleshootingSteps())
            .thenAnswer((_) async => []);
        when(mockGpsDiagnosticsService.runGpsTest())
            .thenAnswer((_) async => testResult);

        await tester.pumpWidget(
          MaterialApp(
            home: GpsDiagnosticsWidget(
              diagnosticsService: mockGpsDiagnosticsService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Run GPS test
        await tester.tap(find.text('Run GPS Test'));
        await tester.pumpAndSettle();

        // Verify test results are displayed
        expect(find.text('Total readings: 45'), findsOneWidget);
        expect(find.text('Average accuracy: 8.5m'), findsOneWidget);
        expect(find.text('Signal stability: Stable'), findsOneWidget);
        expect(find.text('GPS performance looks good for tracking runs.'), findsOneWidget);
      });
    });

    group('Permission Degradation Widget Integration', () {
      testWidgets('displays full functionality status', (tester) async {
        final capabilities = AppCapabilities()
          ..canTrackLocation = true
          ..canTrackInBackground = true
          ..canTakePhotos = true
          ..canSaveData = true
          ..functionalityLevel = FunctionalityLevel.full
          ..limitations = []
          ..recommendations = ['All features are available'];

        when(mockGracefulDegradationService.getAppCapabilities())
            .thenAnswer((_) async => capabilities);
        when(mockGracefulDegradationService.getAlternativeFunctionality())
            .thenAnswer((_) async => AlternativeFunctionality());
        when(mockGracefulDegradationService.getDegradedTrackingOptions())
            .thenAnswer((_) async => DegradedTrackingOptions());

        await tester.pumpWidget(
          MaterialApp(
            home: PermissionDegradationWidget(
              degradationService: mockGracefulDegradationService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify full functionality is displayed
        expect(find.text('All Features Available'), findsOneWidget);
        expect(find.text('TrailRun has all the permissions needed'), findsOneWidget);
      });

      testWidgets('displays degraded functionality with alternatives', (tester) async {
        final capabilities = AppCapabilities()
          ..canTrackLocation = false
          ..canTrackInBackground = false
          ..canTakePhotos = false
          ..canSaveData = true
          ..functionalityLevel = FunctionalityLevel.limited
          ..limitations = ['GPS tracking is not available', 'Camera features are not available']
          ..recommendations = ['Grant location permission for GPS tracking'];

        final alternatives = AlternativeFunctionality()
          ..locationAlternatives = [
            AlternativeFeature(
              title: 'Manual Distance Entry',
              description: 'Manually enter your run distance and time',
              isAvailable: true,
              action: () async {},
            ),
          ]
          ..photoAlternatives = [
            AlternativeFeature(
              title: 'Import Photos',
              description: 'Add photos from your gallery after your run',
              isAvailable: true,
              action: () async {},
            ),
          ];

        when(mockGracefulDegradationService.getAppCapabilities())
            .thenAnswer((_) async => capabilities);
        when(mockGracefulDegradationService.getAlternativeFunctionality())
            .thenAnswer((_) async => alternatives);
        when(mockGracefulDegradationService.getDegradedTrackingOptions())
            .thenAnswer((_) async => DegradedTrackingOptions());

        await tester.pumpWidget(
          MaterialApp(
            home: PermissionDegradationWidget(
              degradationService: mockGracefulDegradationService,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify degraded functionality is displayed
        expect(find.text('Limited Functionality'), findsOneWidget);
        expect(find.text('GPS tracking is not available'), findsOneWidget);
        expect(find.text('Camera features are not available'), findsOneWidget);
        expect(find.text('Manual Distance Entry'), findsOneWidget);
        expect(find.text('Import Photos'), findsOneWidget);
      });
    });

    group('Error Provider Integration', () {
      testWidgets('manages structured errors correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  final errorState = ref.watch(error_provider.errorProvider);
                  final errorNotifier = ref.read(error_provider.errorProvider.notifier);

                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Has Error: ${errorState.hasError}'),
                        Text('Error Count: ${errorState.structuredErrorHistory.length}'),
                        ElevatedButton(
                          onPressed: () {
                            final error = domain_errors.LocationError(
                              type: domain_errors.LocationErrorType.permissionDenied,
                              message: 'Test error',
                              userMessage: 'Test user message',
                            );
                            errorNotifier.showStructuredError(error);
                          },
                          child: const Text('Add Error'),
                        ),
                        ElevatedButton(
                          onPressed: () => errorNotifier.clearCurrentError(),
                          child: const Text('Clear Error'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Initially no errors
        expect(find.text('Has Error: false'), findsOneWidget);
        expect(find.text('Error Count: 0'), findsOneWidget);

        // Add an error
        await tester.tap(find.text('Add Error'));
        await tester.pumpAndSettle();

        expect(find.text('Has Error: true'), findsOneWidget);
        expect(find.text('Error Count: 1'), findsOneWidget);

        // Clear the error
        await tester.tap(find.text('Clear Error'));
        await tester.pumpAndSettle();

        expect(find.text('Has Error: false'), findsOneWidget);
        expect(find.text('Error Count: 1'), findsOneWidget); // History is preserved
      });
    });

    group('End-to-End Error Handling Flow', () {
      testWidgets('handles location error from service to UI', (tester) async {
        final errorHandler = service_error.ErrorHandler(
          locationService: mockLocationService,
          cameraService: mockCameraService,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  final errorNotifier = ref.read(error_provider.errorProvider.notifier);

                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        try {
                          throw LocationServiceDisabledException();
                        } catch (error, stackTrace) {
                          final locationError = errorHandler.handleLocationError(error, stackTrace);
                          errorNotifier.showStructuredError(locationError);
                          ErrorDialog.show(context, locationError);
                        }
                      },
                      child: const Text('Trigger Location Error'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Trigger the error flow
        await tester.tap(find.text('Trigger Location Error'));
        await tester.pumpAndSettle();

        // Verify error dialog is shown
        expect(find.byType(ErrorDialog), findsOneWidget);
        expect(find.text('Location Issue'), findsOneWidget);
        expect(find.text('Location services are turned off'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
      });
    });
  });
}
