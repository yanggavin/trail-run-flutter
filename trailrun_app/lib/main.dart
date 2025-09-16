import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/app.dart';
import 'package:trailrun_app/presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create provider container with observers
  final container = ProviderContainer(
    observers: [AppProviderObserver()],
  );

  // Handle app lifecycle for resource cleanup
  WidgetsBinding.instance.addObserver(AppLifecycleObserver(container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrailRunApp(),
    ),
  );
}

/// Provider observer for debugging and monitoring
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Log provider updates in debug mode
    if (kDebugMode) {
      print('Provider ${provider.name ?? provider.runtimeType} updated');
    }
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    // Log provider errors
    print('Provider ${provider.name ?? provider.runtimeType} failed: $error');
    
    // Report error to error provider if available
    try {
      final errorNotifier = container.read(errorProvider.notifier);
      errorNotifier.showErrorMessage(
        'Provider error: ${error.toString()}',
        type: ErrorType.general,
      );
    } catch (e) {
      // Ignore if error provider is not available
    }
  }
}

/// App lifecycle observer for resource cleanup
class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver(this.container);

  final ProviderContainer container;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        // Handle inactive state if needed
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  void _handleAppPaused() {
    // App is going to background
    // Pause non-essential services but keep tracking active
    try {
      // Dispose camera resources
      final resourceNotifier = container.read(resourceProvider.notifier);
      resourceNotifier.disposeResourcesByType(ResourceType.cameraController);
    } catch (e) {
      print('Error handling app pause: $e');
    }
  }

  void _handleAppResumed() {
    // App is coming back to foreground
    // Resume services and refresh state
    try {
      // Refresh location state
      final locationNotifier = container.read(locationProvider.notifier);
      // Location service should automatically resume
      
      // Refresh activity state if tracking
      final trackingState = container.read(activityTrackingProvider);
      if (trackingState.isTracking) {
        // Activity tracking should continue automatically
      }
    } catch (e) {
      print('Error handling app resume: $e');
    }
  }

  void _handleAppDetached() {
    // App is being terminated
    // Clean up all resources
    try {
      final resourceNotifier = container.read(resourceProvider.notifier);
      resourceNotifier.disposeAllResources();
    } catch (e) {
      print('Error handling app detached: $e');
    } finally {
      container.dispose();
    }
  }
}