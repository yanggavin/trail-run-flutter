import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/app.dart';
import 'package:trailrun_app/data/services/auto_pause_settings_service.dart';
import 'package:trailrun_app/data/services/activity_tracking_provider.dart' as tracking_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final autoPauseSettings = await AutoPauseSettingsService.load();
  tracking_provider.ActivityTrackingProvider.configureAutoPause(
    enabled: autoPauseSettings.enabled,
    speedThreshold: autoPauseSettings.speedThreshold,
    timeThreshold: autoPauseSettings.timeThreshold,
    resumeSpeedThreshold: autoPauseSettings.resumeSpeedThreshold,
  );
  
  // Create provider container with observers
  final container = ProviderContainer(
    observers: [if (kDebugMode) AppProviderObserver()],
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
      case AppLifecycleState.hidden:
        // Handle inactive/hidden state if needed
        break;
    }
  }

  void _handleAppPaused() {
    // App is going to background
    if (kDebugMode) {
      print('App paused - disposing camera resources');
    }
  }

  void _handleAppResumed() {
    // App is coming back to foreground
    if (kDebugMode) {
      print('App resumed');
    }
  }

  void _handleAppDetached() {
    // App is being terminated
    if (kDebugMode) {
      print('App detached - cleaning up resources');
    }
    container.dispose();
  }
}
