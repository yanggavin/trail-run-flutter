/// Core error types for the TrailRun application
/// Provides structured error handling with user-friendly messages and recovery actions

abstract class AppError implements Exception {
  const AppError({
    required this.message,
    required this.userMessage,
    this.recoveryActions = const [],
    this.diagnosticInfo,
  });

  /// Technical error message for logging
  final String message;
  
  /// User-friendly error message
  final String userMessage;
  
  /// List of actions the user can take to recover
  final List<RecoveryAction> recoveryActions;
  
  /// Additional diagnostic information
  final Map<String, dynamic>? diagnosticInfo;

  @override
  String toString() => 'AppError: $message';
}

/// Represents an action the user can take to recover from an error
class RecoveryAction {
  const RecoveryAction({
    required this.title,
    required this.description,
    required this.action,
    this.isDestructive = false,
  });

  final String title;
  final String description;
  final Future<void> Function() action;
  final bool isDestructive;
}

/// Location-related errors
class LocationError extends AppError {
  const LocationError({
    required super.message,
    required super.userMessage,
    super.recoveryActions,
    super.diagnosticInfo,
    required this.type,
  });

  final LocationErrorType type;
}

enum LocationErrorType {
  permissionDenied,
  serviceDisabled,
  signalLost,
  accuracyTooLow,
  backgroundRestricted,
  timeout,
}

/// Camera-related errors
class CameraError extends AppError {
  const CameraError({
    required super.message,
    required super.userMessage,
    super.recoveryActions,
    super.diagnosticInfo,
    required this.type,
  });

  final CameraErrorType type;
}

enum CameraErrorType {
  permissionDenied,
  cameraNotAvailable,
  captureFailure,
  storageFailure,
  processingFailure,
}

/// Storage-related errors
class StorageError extends AppError {
  const StorageError({
    required super.message,
    required super.userMessage,
    super.recoveryActions,
    super.diagnosticInfo,
    required this.type,
  });

  final StorageErrorType type;
}

enum StorageErrorType {
  diskFull,
  permissionDenied,
  databaseCorruption,
  encryptionFailure,
  ioFailure,
}

/// Network and sync errors
class SyncError extends AppError {
  const SyncError({
    required super.message,
    required super.userMessage,
    super.recoveryActions,
    super.diagnosticInfo,
    required this.type,
  });

  final SyncErrorType type;
}

enum SyncErrorType {
  networkUnavailable,
  authenticationFailure,
  serverError,
  conflictResolution,
  rateLimited,
}

/// Session and crash recovery errors
class SessionError extends AppError {
  const SessionError({
    required super.message,
    required super.userMessage,
    super.recoveryActions,
    super.diagnosticInfo,
    required this.type,
  });

  final SessionErrorType type;
}

enum SessionErrorType {
  crashRecovery,
  stateCorruption,
  migrationFailure,
  initializationFailure,
}