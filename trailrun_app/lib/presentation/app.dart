import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/app_router.dart';
import 'providers/providers.dart';

class TrailRunApp extends ConsumerWidget {
  const TrailRunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    
    return MaterialApp(
      title: 'TrailRun',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRoutes.home,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _AppWrapper(child: child);
      },
    );
  }
}

/// Wrapper that provides global error handling and resource cleanup
class _AppWrapper extends ConsumerWidget {
  const _AppWrapper({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for errors and show snackbars
    ref.listen<ErrorState>(errorProvider, (previous, next) {
      if (next.currentError != null && next.isShowingError) {
        _showErrorSnackBar(context, ref, next.currentError!);
      }
    });

    // Initialize app state
    ref.listen<AppState>(appStateProvider, (previous, next) {
      if (!next.isInitialized && previous?.isInitialized != true) {
        _initializeApp(ref);
      }
    });

    return child ?? const SizedBox.shrink();
  }

  void _showErrorSnackBar(BuildContext context, WidgetRef ref, AppError error) {
    if (!error.isRecoverable) return; // Don't show snackbar for non-recoverable errors

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ref.read(errorProvider.notifier).dismissError();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _initializeApp(WidgetRef ref) {
    // Initialize app state
    ref.read(appStateProvider.notifier);
    
    // Initialize location provider
    ref.read(locationProvider.notifier);
    
    // Initialize activity tracking
    ref.read(activityTrackingProvider.notifier);
  }
}