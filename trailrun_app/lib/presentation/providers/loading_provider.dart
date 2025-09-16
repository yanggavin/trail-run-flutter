import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loading operation types
enum LoadingOperation {
  appInitialization,
  activityLoading,
  activitySaving,
  photoCapture,
  photoLoading,
  locationTracking,
  sync,
  export,
  share,
}

/// Loading state
class LoadingState {
  const LoadingState({
    this.activeOperations = const {},
    this.progress = const {},
  });

  final Set<LoadingOperation> activeOperations;
  final Map<LoadingOperation, double> progress;

  LoadingState copyWith({
    Set<LoadingOperation>? activeOperations,
    Map<LoadingOperation, double>? progress,
  }) {
    return LoadingState(
      activeOperations: activeOperations ?? this.activeOperations,
      progress: progress ?? this.progress,
    );
  }

  bool isLoading(LoadingOperation operation) {
    return activeOperations.contains(operation);
  }

  bool get isAnyLoading => activeOperations.isNotEmpty;

  double? getProgress(LoadingOperation operation) {
    return progress[operation];
  }
}

/// Loading notifier
class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(const LoadingState());

  void startLoading(LoadingOperation operation, {double? initialProgress}) {
    final updatedOperations = {...state.activeOperations, operation};
    final updatedProgress = {...state.progress};
    
    if (initialProgress != null) {
      updatedProgress[operation] = initialProgress;
    }
    
    state = state.copyWith(
      activeOperations: updatedOperations,
      progress: updatedProgress,
    );
  }

  void updateProgress(LoadingOperation operation, double progress) {
    if (!state.activeOperations.contains(operation)) return;
    
    final updatedProgress = {...state.progress};
    updatedProgress[operation] = progress.clamp(0.0, 1.0);
    
    state = state.copyWith(progress: updatedProgress);
  }

  void stopLoading(LoadingOperation operation) {
    final updatedOperations = {...state.activeOperations}..remove(operation);
    final updatedProgress = {...state.progress}..remove(operation);
    
    state = state.copyWith(
      activeOperations: updatedOperations,
      progress: updatedProgress,
    );
  }

  void stopAllLoading() {
    state = const LoadingState();
  }
}

/// Provider for loading state
final loadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
});

/// Convenience providers for specific loading states
final isAppInitializingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.appInitialization);
});

final isActivityLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.activityLoading);
});

final isActivitySavingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.activitySaving);
});

final isPhotoCaptureLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.photoCapture);
});

final isPhotoLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.photoLoading);
});

final isLocationTrackingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.locationTracking);
});

final isSyncLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.sync);
});

final isExportLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.export);
});

final isShareLoadingProvider = Provider<bool>((ref) {
  return ref.watch(loadingProvider).isLoading(LoadingOperation.share);
});

/// Loading helper utility
class LoadingHelper {
  static Future<T> withLoading<T>(
    WidgetRef ref,
    LoadingOperation operation,
    Future<T> Function() task, {
    void Function(double)? onProgress,
  }) async {
    final loadingNotifier = ref.read(loadingProvider.notifier);
    
    try {
      loadingNotifier.startLoading(operation);
      
      if (onProgress != null) {
        // If progress callback is provided, we assume the task will call it
        return await task();
      } else {
        return await task();
      }
    } finally {
      loadingNotifier.stopLoading(operation);
    }
  }

  static void updateProgress(WidgetRef ref, LoadingOperation operation, double progress) {
    ref.read(loadingProvider.notifier).updateProgress(operation, progress);
  }
}