import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

/// Base reactive widget that handles common state patterns
abstract class ReactiveWidget extends ConsumerWidget {
  const ReactiveWidget({super.key});

  /// Build method with error and loading handling
  Widget buildWithState(
    BuildContext context,
    WidgetRef ref, {
    required Widget Function() builder,
    Widget Function()? loadingBuilder,
    Widget Function(String error)? errorBuilder,
    List<Provider>? watchProviders,
  }) {
    // Watch for errors
    final currentError = ref.watch(currentErrorProvider);
    final isShowingError = ref.watch(isShowingErrorProvider);

    // Watch for loading states
    final isAnyLoading = ref.watch(loadingProvider).isAnyLoading;

    // Show error if present and should be shown
    if (currentError != null && isShowingError) {
      return errorBuilder?.call(currentError.message) ?? 
             _defaultErrorWidget(context, ref, currentError);
    }

    // Show loading if any operation is loading
    if (isAnyLoading) {
      return loadingBuilder?.call() ?? _defaultLoadingWidget(context);
    }

    // Build normal content
    return builder();
  }

  Widget _defaultErrorWidget(BuildContext context, WidgetRef ref, AppError error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(error.type),
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error.message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (error.details != null) ...[
              const SizedBox(height: 8),
              Text(
                error.details!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (error.isRecoverable) ...[
                  ElevatedButton(
                    onPressed: () => ref.read(errorProvider.notifier).clearCurrentError(),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                ],
                TextButton(
                  onPressed: () => ref.read(errorProvider.notifier).dismissError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultLoadingWidget(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.location:
        return Icons.location_off;
      case ErrorType.camera:
        return Icons.camera_alt_outlined;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.sync:
        return Icons.sync_problem;
      case ErrorType.general:
        return Icons.error;
    }
  }
}

/// Reactive app bar that shows connection status and errors
class ReactiveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ReactiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(appStateProvider).isOfflineMode;
    final isTracking = ref.watch(isTrackingProvider);
    final locationQuality = ref.watch(locationQualityProvider);

    return AppBar(
      title: title,
      leading: leading,
      backgroundColor: backgroundColor,
      actions: [
        // Connection status indicator
        if (isOffline)
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.cloud_off, color: Colors.orange),
          ),
        
        // GPS quality indicator when tracking
        if (isTracking)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _getGpsIcon(locationQuality),
              color: _getGpsColor(locationQuality),
            ),
          ),
        
        ...?actions,
      ],
    );
  }

  IconData _getGpsIcon(LocationQuality quality) {
    switch (quality) {
      case LocationQuality.excellent:
      case LocationQuality.good:
        return Icons.gps_fixed;
      case LocationQuality.fair:
        return Icons.gps_not_fixed;
      case LocationQuality.poor:
      case LocationQuality.unknown:
        return Icons.gps_off;
    }
  }

  Color _getGpsColor(LocationQuality quality) {
    switch (quality) {
      case LocationQuality.excellent:
        return Colors.green;
      case LocationQuality.good:
        return Colors.lightGreen;
      case LocationQuality.fair:
        return Colors.orange;
      case LocationQuality.poor:
      case LocationQuality.unknown:
        return Colors.red;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Reactive floating action button that changes based on tracking state
class ReactiveTrackingFAB extends ConsumerWidget {
  const ReactiveTrackingFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingState = ref.watch(activityTrackingProvider);
    final isTracking = trackingState.isTracking;
    final isPaused = trackingState.isPaused;

    if (!isTracking) {
      return FloatingActionButton.extended(
        onPressed: () => _startTracking(ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
        backgroundColor: Colors.green,
      );
    }

    if (isPaused) {
      return FloatingActionButton.extended(
        onPressed: () => _resumeTracking(ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Resume'),
        backgroundColor: Colors.blue,
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _pauseTracking(ref),
      icon: const Icon(Icons.pause),
      label: const Text('Pause'),
      backgroundColor: Colors.orange,
    );
  }

  void _startTracking(WidgetRef ref) {
    ref.read(activityTrackingProvider.notifier).startActivity();
  }

  void _resumeTracking(WidgetRef ref) {
    ref.read(activityTrackingProvider.notifier).resumeActivity();
  }

  void _pauseTracking(WidgetRef ref) {
    ref.read(activityTrackingProvider.notifier).pauseActivity();
  }
}

/// Reactive status bar that shows current app state
class ReactiveStatusBar extends ConsumerWidget {
  const ReactiveStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final trackingState = ref.watch(activityTrackingProvider);
    final locationState = ref.watch(locationProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tracking status
          if (trackingState.isTracking) ...[
            Icon(
              trackingState.isPaused ? Icons.pause : Icons.radio_button_checked,
              size: 16,
              color: trackingState.isPaused ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              trackingState.isPaused ? 'Paused' : 'Tracking',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 16),
          ],

          // Location status
          Icon(
            locationState.permissionStatus == LocationPermissionStatus.granted
                ? Icons.location_on
                : Icons.location_off,
            size: 16,
            color: locationState.permissionStatus == LocationPermissionStatus.granted
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            _getLocationStatusText(locationState.permissionStatus),
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const Spacer(),

          // Offline indicator
          if (appState.isOfflineMode) ...[
            const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _getLocationStatusText(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return 'GPS Ready';
      case LocationPermissionStatus.denied:
        return 'GPS Denied';
      case LocationPermissionStatus.permanentlyDenied:
        return 'GPS Blocked';
      case LocationPermissionStatus.unknown:
        return 'GPS Unknown';
    }
  }
}