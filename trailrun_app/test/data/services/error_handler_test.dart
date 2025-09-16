import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'dart:io';

import '../../../lib/data/services/error_handler.dart';
import '../../../lib/data/services/platform_permission_service.dart';
import '../../../lib/data/services/location_service.dart';
import '../../../lib/data/services/camera_service.dart';
import '../../../lib/domain/errors/app_errors.dart';

@GenerateMocks([
  PlatformPermissionService,
  LocationService,
  CameraService,
])
import 'error_handler_test.mocks.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;
    late MockPlatformPermissionService mockPermissionService;
    late MockLocationService mockLocationService;
    late MockCameraService mockCameraService;

    setUp(() {
      mockPermissionService = MockPlatformPermissionService();
      mockLocationService = MockLocationService();
      mockCameraService = MockCameraService();
      
      errorHandler = ErrorHandler(
        permissionService: mockPermissionService,
        locationService: mockLocationService,
        cameraService: mockCameraService,
      );
    });

    group('handleLocationError', () {
      test('handles LocationServiceDisabledException correctly', () {
        final exception = LocationServiceDisabledException();
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleLocationError(exception, stackTrace);

        expect(result, isA<LocationError>());
        expect(result.type, LocationErrorType.serviceDisabled);
        expect(result.userMessage, contains('Location services are turned off'));
        expect(result.recoveryActions, hasLength(1));
        expect(result.recoveryActions.first.title, 'Open Settings');
      });

      test('handles PermissionDeniedException correctly', () {
        final exception = PermissionDeniedException('Location permission denied');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleLocationError(exception, stackTrace);

        expect(result, isA<LocationError>());
        expect(result.type, LocationErrorType.permissionDenied);
        expect(result.userMessage, contains('Location permission is required'));
        expect(result.recoveryActions, hasLength(2));
        expect(result.recoveryActions.first.title, 'Grant Permission');
        expect(result.recoveryActions.last.title, 'Open App Settings');
      });

      test('handles TimeoutException correctly', () {
        final exception = TimeoutException('Location timeout', const Duration(seconds: 30));
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleLocationError(exception, stackTrace);

        expect(result, isA<LocationError>());
        expect(result.type, LocationErrorType.timeout);
        expect(result.userMessage, contains('Unable to get your location'));
        expect(result.recoveryActions, hasLength(2));
        expect(result.diagnosticInfo?['timeout_duration'], '30s');
      });

      test('handles generic location error', () {
        final exception = Exception('Generic location error');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleLocationError(exception, stackTrace);

        expect(result, isA<LocationError>());
        expect(result.type, LocationErrorType.signalLost);
        expect(result.userMessage, contains('problem with location tracking'));
        expect(result.recoveryActions, hasLength(1));
      });
    });

    group('handleCameraError', () {
      test('handles camera access denied', () {
        final exception = CameraException('CameraAccessDenied', 'Camera access denied');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleCameraError(exception, stackTrace);

        expect(result, isA<CameraError>());
        expect(result.type, CameraErrorType.permissionDenied);
        expect(result.userMessage, contains('Camera permission is required'));
        expect(result.recoveryActions, hasLength(2));
        expect(result.diagnosticInfo?['camera_code'], 'CameraAccessDenied');
      });

      test('handles camera not found', () {
        final exception = CameraException('CameraNotFound', 'No camera available');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleCameraError(exception, stackTrace);

        expect(result, isA<CameraError>());
        expect(result.type, CameraErrorType.cameraNotAvailable);
        expect(result.userMessage, contains('No camera is available'));
        expect(result.recoveryActions, isEmpty);
      });

      test('handles generic camera error', () {
        final exception = CameraException('UnknownError', 'Unknown camera error');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleCameraError(exception, stackTrace);

        expect(result, isA<CameraError>());
        expect(result.type, CameraErrorType.captureFailure);
        expect(result.userMessage, contains('problem with the camera'));
        expect(result.recoveryActions, hasLength(1));
      });
    });

    group('handleStorageError', () {
      test('handles disk full error', () {
        final exception = FileSystemException('No space left on device', '', OSError('No space left on device', 28));
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleStorageError(exception, stackTrace);

        expect(result, isA<StorageError>());
        expect(result.type, StorageErrorType.diskFull);
        expect(result.userMessage, contains('running low on storage space'));
        expect(result.recoveryActions, hasLength(2));
        expect(result.recoveryActions.last.isDestructive, isTrue);
      });

      test('handles generic storage error', () {
        final exception = FileSystemException('Generic file error');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleStorageError(exception, stackTrace);

        expect(result, isA<StorageError>());
        expect(result.type, StorageErrorType.ioFailure);
        expect(result.userMessage, contains('problem saving your data'));
        expect(result.recoveryActions, hasLength(1));
      });
    });

    group('handleSyncError', () {
      test('handles network unavailable', () {
        final exception = SocketException('Network is unreachable');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleSyncError(exception, stackTrace);

        expect(result, isA<SyncError>());
        expect(result.type, SyncErrorType.networkUnavailable);
        expect(result.userMessage, contains('No internet connection'));
        expect(result.recoveryActions, hasLength(1));
      });

      test('handles authentication failure', () {
        final exception = HttpException('401 Unauthorized');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleSyncError(exception, stackTrace);

        expect(result, isA<SyncError>());
        expect(result.type, SyncErrorType.authenticationFailure);
        expect(result.userMessage, contains('sign in again'));
        expect(result.recoveryActions, hasLength(1));
      });

      test('handles server error', () {
        final exception = HttpException('500 Internal Server Error');
        final stackTrace = StackTrace.current;

        final result = errorHandler.handleSyncError(exception, stackTrace);

        expect(result, isA<SyncError>());
        expect(result.type, SyncErrorType.serverError);
        expect(result.userMessage, contains('temporarily unavailable'));
        expect(result.recoveryActions, hasLength(1));
      });
    });

    group('withErrorHandling', () {
      test('executes operation successfully', () async {
        final result = await ErrorHandler.withErrorHandling<String>(
          () async => 'success',
          errorHandler: (error, stackTrace) => throw error,
        );

        expect(result, 'success');
      });

      test('handles error and converts to AppError', () async {
        final testError = Exception('Test error');
        
        expect(
          () => ErrorHandler.withErrorHandling<String>(
            () async => throw testError,
            errorHandler: (error, stackTrace) => LocationError(
              type: LocationErrorType.signalLost,
              message: 'Test error',
              userMessage: 'Test user message',
            ),
          ),
          throwsA(isA<LocationError>()),
        );
      });

      test('retries operation on failure', () async {
        int attempts = 0;
        
        expect(
          () => ErrorHandler.withErrorHandling<String>(
            () async {
              attempts++;
              if (attempts < 3) {
                throw Exception('Retry error');
              }
              return 'success after retries';
            },
            errorHandler: (error, stackTrace) => LocationError(
              type: LocationErrorType.signalLost,
              message: 'Retry error',
              userMessage: 'Retry user message',
            ),
            maxRetries: 2,
            retryDelay: const Duration(milliseconds: 10),
          ),
          throwsA(isA<LocationError>()),
        );
        
        expect(attempts, 3);
      });
    });

    group('withStreamErrorHandling', () {
      test('passes through successful stream events', () async {
        final sourceStream = Stream.fromIterable([1, 2, 3]);
        
        final handledStream = ErrorHandler.withStreamErrorHandling<int>(
          sourceStream,
          errorHandler: (error, stackTrace) => throw error,
        );
        
        final events = await handledStream.toList();
        expect(events, [1, 2, 3]);
      });

      test('handles stream errors', () async {
        final sourceStream = Stream<int>.error(Exception('Stream error'));
        
        final handledStream = ErrorHandler.withStreamErrorHandling<int>(
          sourceStream,
          errorHandler: (error, stackTrace) => LocationError(
            type: LocationErrorType.signalLost,
            message: 'Stream error',
            userMessage: 'Stream user message',
          ),
        );
        
        expect(
          handledStream.toList(),
          throwsA(isA<LocationError>()),
        );
      });
    });
  });
}