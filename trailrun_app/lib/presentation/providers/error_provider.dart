import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/errors/app_errors.dart' as domain_errors;
import '../../data/services/error_handler.dart';

/// Legacy error types for backward compatibility
enum ErrorType {
  network,
  location,
  camera,
  storage,
  permission,
  sync,
  general,
}

/// Legacy app error for backward compatibility
class AppError {
  const AppError({
    required this.type,
    required this.message,
    this.details,
    this.timestamp,
    this.isRecoverable = true,
  });

  final ErrorType type;
  final String message;
  final String? details;
  final DateTime? timestamp;
  final bool isRecoverable;

  AppError copyWith({
    ErrorType? type,
    String? message,
    String? details,
    DateTime? timestamp,
    bool? isRecoverable,
  }) {
    return AppError(
      type: type ?? this.type,
      message: message ?? this.message,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      isRecoverable: isRecoverable ?? this.isRecoverable,
    );
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, details: $details)';
  }
}

/// Error state that supports both legacy and new structured errors
class ErrorState {
  const ErrorState({
    this.currentError,
    this.currentStructuredError,
    this.errorHistory = const [],
    this.structuredErrorHistory = const [],
    this.isShowingError = false,
  });

  final AppError? currentError;
  final domain_errors.AppError? currentStructuredError;
  final List<AppError> errorHistory;
  final List<domain_errors.AppError> structuredErrorHistory;
  final bool isShowingError;

  ErrorState copyWith({
    AppError? currentError,
    domain_errors.AppError? currentStructuredError,
    List<AppError>? errorHistory,
    List<domain_errors.AppError>? structuredErrorHistory,
    bool? isShowingError,
    bool clearCurrentError = false,
    bool clearStructuredError = false,
  }) {
    return ErrorState(
      currentError: clearCurrentError ? null : (currentError ?? this.currentError),
      currentStructuredError: clearStructuredError ? null : (currentStructuredError ?? this.currentStructuredError),
      errorHistory: errorHistory ?? this.errorHistory,
      structuredErrorHistory: structuredErrorHistory ?? this.structuredErrorHistory,
      isShowingError: isShowingError ?? this.isShowingError,
    );
  }

  /// Gets the most relevant error to display (structured error takes precedence)
  dynamic get displayError => currentStructuredError ?? currentError;
  
  /// Checks if there's any error to display
  bool get hasError => currentStructuredError != null || currentError != null;
}

/// Error notifier that supports both legacy and structured errors
class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(const ErrorState());

  /// Shows a structured domain error (preferred method)
  void showStructuredError(domain_errors.AppError error) {
    final updatedHistory = [...state.structuredErrorHistory, error];
    
    // Keep only last 10 errors
    if (updatedHistory.length > 10) {
      updatedHistory.removeAt(0);
    }
    
    state = state.copyWith(
      currentStructuredError: error,
      structuredErrorHistory: updatedHistory,
      isShowingError: true,
    );
  }

  /// Shows a legacy error (for backward compatibility)
  void showError(AppError error) {
    final updatedHistory = [...state.errorHistory, error];
    
    // Keep only last 10 errors
    if (updatedHistory.length > 10) {
      updatedHistory.removeAt(0);
    }
    
    state = state.copyWith(
      currentError: error,
      errorHistory: updatedHistory,
      isShowingError: true,
    );
  }

  /// Shows an error from an exception using the error handler
  void showErrorFromException(
    dynamic exception,
    StackTrace stackTrace,
    domain_errors.AppError Function(dynamic, StackTrace) errorHandler,
  ) {
    final structuredError = errorHandler(exception, stackTrace);
    showStructuredError(structuredError);
  }

  void showErrorMessage(
    String message, {
    ErrorType type = ErrorType.general,
    String? details,
    bool isRecoverable = true,
  }) {
    final error = AppError(
      type: type,
      message: message,
      details: details,
      timestamp: DateTime.now(),
      isRecoverable: isRecoverable,
    );
    showError(error);
  }

  void clearCurrentError() {
    state = state.copyWith(
      clearCurrentError: true,
      clearStructuredError: true,
      isShowingError: false,
    );
  }

  void clearAllErrors() {
    state = const ErrorState();
  }

  void dismissError() {
    state = state.copyWith(isShowingError: false);
  }

  /// Gets error statistics for debugging
  Map<String, int> getErrorStatistics() {
    final stats = <String, int>{};
    
    // Count legacy errors
    for (final error in state.errorHistory) {
      final key = 'legacy_${error.type.name}';
      stats[key] = (stats[key] ?? 0) + 1;
    }
    
    // Count structured errors
    for (final error in state.structuredErrorHistory) {
      final key = error.runtimeType.toString();
      stats[key] = (stats[key] ?? 0) + 1;
    }
    
    return stats;
  }

  /// Checks if there have been repeated errors of the same type
  bool hasRepeatedStructuredErrors<T extends domain_errors.AppError>({int threshold = 3}) {
    final recentErrors = state.structuredErrorHistory
        .where((error) => error is T)
        .take(threshold)
        .toList();
    
    return recentErrors.length >= threshold;
  }
}

/// Provider for error state
final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

/// Provider for current error (convenience)
final currentErrorProvider = Provider<AppError?>((ref) {
  return ref.watch(errorProvider).currentError;
});

/// Provider for error visibility (convenience)
final isShowingErrorProvider = Provider<bool>((ref) {
  return ref.watch(errorProvider).isShowingError;
});

/// Error handler utility
class ErrorHandler {
  static void handleError(WidgetRef ref, dynamic error, {ErrorType? type}) {
    final errorNotifier = ref.read(errorProvider.notifier);
    
    if (error is AppError) {
      errorNotifier.showError(error);
    } else {
      final errorType = type ?? _inferErrorType(error);
      errorNotifier.showErrorMessage(
        error.toString(),
        type: errorType,
        isRecoverable: _isRecoverable(errorType),
      );
    }
  }

  static ErrorType _inferErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorType.network;
    } else if (errorString.contains('location') || errorString.contains('gps')) {
      return ErrorType.location;
    } else if (errorString.contains('camera')) {
      return ErrorType.camera;
    } else if (errorString.contains('storage') || errorString.contains('file')) {
      return ErrorType.storage;
    } else if (errorString.contains('permission')) {
      return ErrorType.permission;
    } else if (errorString.contains('sync')) {
      return ErrorType.sync;
    }
    
    return ErrorType.general;
  }

  static bool _isRecoverable(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.sync:
        return true;
      case ErrorType.permission:
      case ErrorType.location:
      case ErrorType.camera:
        return true;
      case ErrorType.storage:
        return false;
      case ErrorType.general:
        return true;
    }
  }
}