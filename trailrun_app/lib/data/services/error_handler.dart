import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:drift/drift.dart';
import '../../domain/errors/app_errors.dart' as domain_errors;
import 'platform_permission_service.dart';
import 'location_service.dart' as location_service;
import 'camera_service.dart';

/// Central error handler that converts platform exceptions to structured AppErrors
/// and provides recovery mechanisms
class ErrorHandler {
  ErrorHandler({
    required this.locationService,
    required this.cameraService,
  });

  final location_service.LocationService locationService;
  final CameraService cameraService;

  /// Handles location-related errors with appropriate recovery actions
  domain_errors.LocationError handleLocationError(dynamic error, StackTrace stackTrace) {
    debugPrint('Location error: $error\n$stackTrace');

    if (error is LocationServiceDisabledException) {
      return domain_errors.LocationError(
        type: domain_errors.LocationErrorType.serviceDisabled,
        message: 'Location services are disabled',
        userMessage: 'Location services are turned off. Please enable them to track your runs.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Open Settings',
            description: 'Go to device settings to enable location services',
            action: () async => await PlatformPermissionService.openLocationSettings(),
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    }

    if (error is PermissionDeniedException) {
      return domain_errors.LocationError(
        type: domain_errors.LocationErrorType.permissionDenied,
        message: 'Location permission denied',
        userMessage: 'Location permission is required to track your runs.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Grant Permission',
            description: 'Allow location access in app settings',
            action: () async => await PlatformPermissionService.requestLocationPermission(),
          ),
          domain_errors.RecoveryAction(
            title: 'Open App Settings',
            description: 'Manually enable location permission',
            action: () async => await PlatformPermissionService.openAppSettings(),
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.operatingSystem,
        },
      );
    }

    if (error is TimeoutException) {
      return domain_errors.LocationError(
        type: domain_errors.LocationErrorType.timeout,
        message: 'Location request timed out',
        userMessage: 'Unable to get your location. This might be due to poor GPS signal.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Try Again',
            description: 'Retry getting your location',
            action: () async => await locationService.getCurrentLocation(),
          ),
          domain_errors.RecoveryAction(
            title: 'Move to Open Area',
            description: 'Go outside or near a window for better GPS signal',
            action: () async {}, // User action, no code needed
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'timeout_duration': '30s',
          'platform': Platform.operatingSystem,
        },
      );
    }

    // Generic location error
    return domain_errors.LocationError(
      type: domain_errors.LocationErrorType.signalLost,
      message: 'Location error: $error',
      userMessage: 'There was a problem with location tracking. Please try again.',
      recoveryActions: [
        domain_errors.RecoveryAction(
          title: 'Retry',
          description: 'Try to get your location again',
          action: () async => await locationService.getCurrentLocation(),
        ),
      ],
      diagnosticInfo: {
        'timestamp': DateTime.now().toIso8601String(),
        'error_type': error.runtimeType.toString(),
        'platform': Platform.operatingSystem,
      },
    );
  }

  /// Handles camera-related errors with appropriate recovery actions
  domain_errors.CameraError handleCameraError(dynamic error, StackTrace stackTrace) {
    debugPrint('Camera error: $error\n$stackTrace');

    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
          return domain_errors.CameraError(
            type: domain_errors.CameraErrorType.permissionDenied,
            message: 'Camera permission denied',
            userMessage: 'Camera permission is required to take photos during your runs.',
            recoveryActions: [
              domain_errors.RecoveryAction(
                title: 'Grant Permission',
                description: 'Allow camera access in app settings',
                action: () async => await PlatformPermissionService.requestCameraPermission(),
              ),
              domain_errors.RecoveryAction(
                title: 'Open App Settings',
                description: 'Manually enable camera permission',
                action: () async => await PlatformPermissionService.openAppSettings(),
              ),
            ],
            diagnosticInfo: {
              'timestamp': DateTime.now().toIso8601String(),
              'camera_code': error.code,
              'platform': Platform.operatingSystem,
            },
          );
        case 'CameraNotFound':
          return domain_errors.CameraError(
            type: domain_errors.CameraErrorType.cameraNotAvailable,
            message: 'Camera not available',
            userMessage: 'No camera is available on this device.',
            recoveryActions: [],
            diagnosticInfo: {
              'timestamp': DateTime.now().toIso8601String(),
              'camera_code': error.code,
              'platform': Platform.operatingSystem,
            },
          );
        default:
          return domain_errors.CameraError(
            type: domain_errors.CameraErrorType.captureFailure,
            message: 'Camera error: ${error.code} - ${error.description}',
            userMessage: 'There was a problem with the camera. Please try again.',
            recoveryActions: [
              domain_errors.RecoveryAction(
                title: 'Try Again',
                description: 'Attempt to take the photo again',
                action: () async => await cameraService.initialize(),
              ),
            ],
            diagnosticInfo: {
              'timestamp': DateTime.now().toIso8601String(),
              'camera_code': error.code,
              'camera_description': error.description,
              'platform': Platform.operatingSystem,
            },
          );
      }
    }

    // Generic camera error
    return domain_errors.CameraError(
      type: domain_errors.CameraErrorType.captureFailure,
      message: 'Camera error: $error',
      userMessage: 'There was a problem with the camera. Please try again.',
      recoveryActions: [
        domain_errors.RecoveryAction(
          title: 'Retry',
          description: 'Try to take the photo again',
          action: () async => await cameraService.initialize(),
        ),
      ],
      diagnosticInfo: {
        'timestamp': DateTime.now().toIso8601String(),
        'error_type': error.runtimeType.toString(),
        'platform': Platform.operatingSystem,
      },
    );
  }

  /// Handles storage-related errors with appropriate recovery actions
  domain_errors.StorageError handleStorageError(dynamic error, StackTrace stackTrace) {
    debugPrint('Storage error: $error\n$stackTrace');

    if (error is FileSystemException) {
      if (error.osError?.errorCode == 28) { // ENOSPC - No space left on device
        return domain_errors.StorageError(
          type: domain_errors.StorageErrorType.diskFull,
          message: 'Insufficient storage space',
          userMessage: 'Your device is running low on storage space.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Free Up Space',
              description: 'Delete old photos or apps to make room',
              action: () async {}, // User action
            ),
            domain_errors.RecoveryAction(
              title: 'Delete Old Activities',
              description: 'Remove old TrailRun activities to save space',
              action: () async {
                // This would trigger a cleanup dialog
              },
              isDestructive: true,
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'os_error_code': error.osError?.errorCode,
            'path': error.path,
            'platform': Platform.operatingSystem,
          },
        );
      }
    }

    if (error is DriftWrappedException) {
      return domain_errors.StorageError(
        type: domain_errors.StorageErrorType.databaseCorruption,
        message: 'Database error: ${error.cause}',
        userMessage: 'There was a problem with the app database. Your data may need to be restored.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Restart App',
            description: 'Close and reopen the app to attempt recovery',
            action: () async {
              // This would trigger an app restart
            },
          ),
          domain_errors.RecoveryAction(
            title: 'Reset Database',
            description: 'Clear all data and start fresh (this will delete your activities)',
            action: () async {
              // This would trigger a database reset
            },
            isDestructive: true,
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'drift_error': error.cause.toString(),
          'platform': Platform.operatingSystem,
        },
      );
    }

    // Generic storage error
    return domain_errors.StorageError(
      type: domain_errors.StorageErrorType.ioFailure,
      message: 'Storage error: $error',
      userMessage: 'There was a problem saving your data. Please try again.',
      recoveryActions: [
        domain_errors.RecoveryAction(
          title: 'Retry',
          description: 'Try the operation again',
          action: () async {
            // Retry the failed operation
          },
        ),
      ],
      diagnosticInfo: {
        'timestamp': DateTime.now().toIso8601String(),
        'error_type': error.runtimeType.toString(),
        'platform': Platform.operatingSystem,
      },
    );
  }

  /// Handles sync-related errors with appropriate recovery actions
  domain_errors.SyncError handleSyncError(dynamic error, StackTrace stackTrace) {
    debugPrint('Sync error: $error\n$stackTrace');

    if (error is SocketException) {
      return domain_errors.SyncError(
        type: domain_errors.SyncErrorType.networkUnavailable,
        message: 'Network connection failed',
        userMessage: 'No internet connection available. Your data will sync when connection is restored.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Check Connection',
            description: 'Verify your internet connection and try again',
            action: () async {
              // Retry sync
            },
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'socket_error': error.message,
          'platform': Platform.operatingSystem,
        },
      );
    }

    if (error is HttpException) {
      final statusCode = int.tryParse(error.message.split(' ').first) ?? 0;
      
      if (statusCode == 401 || statusCode == 403) {
        return domain_errors.SyncError(
          type: domain_errors.SyncErrorType.authenticationFailure,
          message: 'Authentication failed: ${error.message}',
          userMessage: 'Please sign in again to sync your data.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Sign In',
              description: 'Re-authenticate to continue syncing',
              action: () async {
                // Trigger re-authentication
              },
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'status_code': statusCode,
            'platform': Platform.operatingSystem,
          },
        );
      }

      if (statusCode >= 500) {
        return domain_errors.SyncError(
          type: domain_errors.SyncErrorType.serverError,
          message: 'Server error: ${error.message}',
          userMessage: 'The sync service is temporarily unavailable. We\'ll try again later.',
          recoveryActions: [
            domain_errors.RecoveryAction(
              title: 'Try Later',
              description: 'Sync will be retried automatically',
              action: () async {}, // Automatic retry
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'status_code': statusCode,
            'platform': Platform.operatingSystem,
          },
        );
      }
    }

    // Generic sync error
    return domain_errors.SyncError(
      type: domain_errors.SyncErrorType.networkUnavailable,
      message: 'Sync error: $error',
      userMessage: 'There was a problem syncing your data. We\'ll try again later.',
      recoveryActions: [
        domain_errors.RecoveryAction(
          title: 'Retry Now',
          description: 'Try to sync again immediately',
          action: () async {
            // Retry sync
          },
        ),
      ],
      diagnosticInfo: {
        'timestamp': DateTime.now().toIso8601String(),
        'error_type': error.runtimeType.toString(),
        'platform': Platform.operatingSystem,
      },
    );
  }

  /// Wraps a function with error handling and automatic conversion to domain_errors.AppError
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation, {
    required domain_errors.AppError Function(dynamic error, StackTrace stackTrace) errorHandler,
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        if (attempts > maxRetries) {
          throw errorHandler(error, stackTrace);
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw StateError('This should never be reached');
  }

  /// Wraps a stream with error handling
  static Stream<T> withStreamErrorHandling<T>(
    Stream<T> stream, {
    required domain_errors.AppError Function(dynamic error, StackTrace stackTrace) errorHandler,
  }) {
    return stream.handleError((error, stackTrace) {
      throw errorHandler(error, stackTrace);
    });
  }
}
