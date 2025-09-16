import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/errors/app_errors.dart';
import '../../presentation/providers/error_provider.dart';
import 'error_handler.dart';
import 'crash_recovery_service.dart';
import 'graceful_degradation_service.dart';
import 'platform_permission_service.dart';
import 'location_service.dart';
import 'camera_service.dart';

/// Central service for managing all error handling and recovery in the app
class AppErrorService {
  AppErrorService({
    required this.ref,
    required this.permissionService,
    required this.locationService,
    required this.cameraService,
    required this.crashRecoveryService,
    required this.gracefulDegradationService,
  }) {
    _errorHandler = ErrorHandler(
      permissionService: permissionService,
      locationService: locationService,
      cameraService: cameraService,
    );
  }

  final Ref ref;
  final PlatformPermissionService permissionService;
  final LocationService locationService;
  final CameraService cameraService;
  final CrashRecoveryService crashRecoveryService;
  final GracefulDegradationService gracefulDegradationService;
  
  late final ErrorHandler _errorHandler;

  /// Handles location-related errors
  Future<void> handleLocationError(dynamic error, StackTrace stackTrace) async {
    try {
      final locationError = _errorHandler.handleLocationError(error, stackTrace);
      _showStructuredError(locationError);
    } catch (handlerError) {
      debugPrint('Error in location error handler: $handlerError');
      _showFallbackError('Location error occurred', error);
    }
  }

  /// Handles camera-related errors
  Future<void> handleCameraError(dynamic error, StackTrace stackTrace) async {
    try {
      final cameraError = _errorHandler.handleCameraError(error, stackTrace);
      _showStructuredError(cameraError);
    } catch (handlerError) {
      debugPrint('Error in camera error handler: $handlerError');
      _showFallbackError('Camera error occurred', error);
    }
  }

  /// Handles storage-related errors
  Future<void> handleStorageError(dynamic error, StackTrace stackTrace) async {
    try {
      final storageError = _errorHandler.handleStorageError(error, stackTrace);
      _showStructuredError(storageError);
    } catch (handlerError) {
      debugPrint('Error in storage error handler: $handlerError');
      _showFallbackError('Storage error occurred', error);
    }
  }

  /// Handles sync-related errors
  Future<void> handleSyncError(dynamic error, StackTrace stackTrace) async {
    try {
      final syncError = _errorHandler.handleSyncError(error, stackTrace);
      _showStructuredError(syncError);
    } catch (handlerError) {
      debugPrint('Error in sync error handler: $handlerError');
      _showFallbackError('Sync error occurred', error);
    }
  }

  /// Handles generic errors with automatic type detection
  Future<void> handleGenericError(dynamic error, StackTrace stackTrace) async {
    try {
      // Try to determine error type and use appropriate handler
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('location') || errorString.contains('gps')) {
        await handleLocationError(error, stackTrace);
      } else if (errorString.contains('camera')) {
        await handleCameraError(error, stackTrace);
      } else if (errorString.contains('storage') || errorString.contains('database')) {
        await handleStorageError(error, stackTrace);
      } else if (errorString.contains('sync') || errorString.contains('network')) {
        await handleSyncError(error, stackTrace);
      } else {
        // Generic error
        final genericError = AppError(
          message: 'Generic error: $error',
          userMessage: 'An unexpected error occurred. Please try again.',
          recoveryActions: [
            RecoveryAction(
              title: 'Retry',
              description: 'Try the operation again',
              action: () async {
                // This would need to be implemented based on context
              },
            ),
          ],
          diagnosticInfo: {
            'timestamp': DateTime.now().toIso8601String(),
            'error_type': error.runtimeType.toString(),
            'error_message': error.toString(),
          },
        );
        _showStructuredError(genericError);
      }
    } catch (handlerError) {
      debugPrint('Error in generic error handler: $handlerError');
      _showFallbackError('An error occurred', error);
    }
  }

  /// Wraps an operation with comprehensive error handling
  Future<T> withErrorHandling<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        debugPrint('Error in ${operationName ?? 'operation'} (attempt $attempts): $error');
        
        if (attempts > maxRetries) {
          await handleGenericError(error, stackTrace);
          rethrow;
        }
        
        // Wait before retrying
        await Future.delayed(retryDelay * attempts);
      }
    }
    
    throw StateError('This should never be reached');
  }

  /// Wraps a stream with comprehensive error handling
  Stream<T> withStreamErrorHandling<T>(
    Stream<T> stream, {
    String? streamName,
  }) {
    return stream.handleError((error, stackTrace) async {
      debugPrint('Error in ${streamName ?? 'stream'}: $error');
      await handleGenericError(error, stackTrace);
    });
  }

  /// Checks for and handles crash recovery
  Future<void> handleAppStartup() async {
    try {
      final recoveryResult = await crashRecoveryService.checkForCrashRecovery();
      
      if (recoveryResult.hasError) {
        _showStructuredError(recoveryResult.error!);
      } else if (recoveryResult.needsRecovery) {
        // This would trigger the crash recovery dialog
        // The actual UI handling would be done by the app startup logic
        debugPrint('Crash recovery needed for activity: ${recoveryResult.activity?.id}');
      }
    } catch (error, stackTrace) {
      debugPrint('Error during app startup crash recovery check: $error');
      await handleGenericError(error, stackTrace);
    }
  }

  /// Gets current app capabilities and handles degradation
  Future<AppCapabilities> checkAppCapabilities() async {
    try {
      return await gracefulDegradationService.getAppCapabilities();
    } catch (error, stackTrace) {
      debugPrint('Error checking app capabilities: $error');
      await handleGenericError(error, stackTrace);
      
      // Return minimal capabilities as fallback
      return AppCapabilities()
        ..functionalityLevel = FunctionalityLevel.minimal
        ..limitations = ['Unable to check app capabilities']
        ..recommendations = ['Please restart the app'];
    }
  }

  /// Handles permission denial with graceful degradation
  Future<void> handlePermissionDenial(
    PermissionType permissionType,
    bool isPermanentlyDenied,
  ) async {
    try {
      final response = await gracefulDegradationService.handlePermissionDenial(
        permissionType,
        isPermanentlyDenied,
      );
      
      // Create a structured error for permission denial
      final permissionError = AppError(
        message: 'Permission denied: $permissionType',
        userMessage: response.message,
        recoveryActions: response.alternatives.map((alt) => RecoveryAction(
          title: alt,
          description: alt,
          action: () async {
            if (response.canRetry) {
              // Retry permission request
              switch (permissionType) {
                case PermissionType.location:
                  await permissionService.requestLocationPermission();
                  break;
                case PermissionType.camera:
                  await permissionService.requestCameraPermission();
                  break;
                case PermissionType.storage:
                  await permissionService.requestStoragePermission();
                  break;
              }
            } else if (response.settingsRequired) {
              await permissionService.openAppSettings();
            }
          },
        )).toList(),
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'permission_type': permissionType.toString(),
          'permanently_denied': isPermanentlyDenied,
          'can_retry': response.canRetry,
          'settings_required': response.settingsRequired,
        },
      );
      
      _showStructuredError(permissionError);
    } catch (error, stackTrace) {
      debugPrint('Error handling permission denial: $error');
      await handleGenericError(error, stackTrace);
    }
  }

  /// Gets error statistics for debugging and monitoring
  Map<String, dynamic> getErrorStatistics() {
    final errorNotifier = ref.read(errorProvider.notifier);
    final providerStats = errorNotifier.getErrorStatistics();
    
    return {
      'provider_stats': providerStats,
      'timestamp': DateTime.now().toIso8601String(),
      'total_errors': providerStats.values.fold(0, (sum, count) => sum + count),
    };
  }

  /// Clears all errors
  void clearAllErrors() {
    ref.read(errorProvider.notifier).clearAllErrors();
  }

  void _showStructuredError(AppError error) {
    ref.read(errorProvider.notifier).showStructuredError(error);
  }

  void _showFallbackError(String message, dynamic originalError) {
    ref.read(errorProvider.notifier).showErrorMessage(
      message,
      details: originalError.toString(),
      type: ErrorType.general,
    );
  }
}

/// Provider for the app error service
final appErrorServiceProvider = Provider<AppErrorService>((ref) {
  return AppErrorService(
    ref: ref,
    permissionService: ref.read(platformPermissionServiceProvider),
    locationService: ref.read(locationServiceProvider),
    cameraService: ref.read(cameraServiceProvider),
    crashRecoveryService: ref.read(crashRecoveryServiceProvider),
    gracefulDegradationService: ref.read(gracefulDegradationServiceProvider),
  );
});

/// Provider for platform permission service
final platformPermissionServiceProvider = Provider<PlatformPermissionService>((ref) {
  return PlatformPermissionService();
});

/// Provider for location service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for camera service
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

/// Provider for crash recovery service
final crashRecoveryServiceProvider = Provider<CrashRecoveryService>((ref) {
  return CrashRecoveryService(
    database: ref.read(databaseProvider),
    activityTrackingService: ref.read(activityTrackingServiceProvider),
  );
});

/// Provider for graceful degradation service
final gracefulDegradationServiceProvider = Provider<GracefulDegradationService>((ref) {
  return GracefulDegradationService(
    permissionService: ref.read(platformPermissionServiceProvider),
    locationService: ref.read(locationServiceProvider),
    cameraService: ref.read(cameraServiceProvider),
  );
});

// Placeholder providers - these would need to be implemented based on existing services
final databaseProvider = Provider<dynamic>((ref) => throw UnimplementedError());
final activityTrackingServiceProvider = Provider<dynamic>((ref) => throw UnimplementedError());