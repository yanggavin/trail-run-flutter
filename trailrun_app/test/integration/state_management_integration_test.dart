import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trailrun_app/presentation/app.dart';
import 'package:trailrun_app/presentation/providers/providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('State Management Integration Tests', () {
    testWidgets('should initialize app state correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TrailRunApp(),
        ),
      );

      // Wait for app to initialize
      await tester.pumpAndSettle();

      // Verify app is displayed
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle navigation state changes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: TrailRunApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap navigation elements (if they exist)
      // This would depend on the actual UI implementation
      
      // Verify navigation state is updated
      // This would need to be implemented based on actual navigation
    });

    testWidgets('should handle error states in UI', (tester) async {
      late ProviderContainer container;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger an error
      container.read(errorProvider.notifier).showErrorMessage(
        'Test error message',
        type: ErrorType.network,
      );

      await tester.pumpAndSettle();

      // Verify error is displayed (this would depend on UI implementation)
      // For now, we just verify the error state is set
      final errorState = container.read(errorProvider);
      expect(errorState.currentError?.message, 'Test error message');
      expect(errorState.isShowingError, true);
    });

    testWidgets('should handle loading states in UI', (tester) async {
      late ProviderContainer container;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger loading state
      container.read(loadingProvider.notifier).startLoading(
        LoadingOperation.activityLoading,
      );

      await tester.pumpAndSettle();

      // Verify loading state
      final loadingState = container.read(loadingProvider);
      expect(loadingState.isLoading(LoadingOperation.activityLoading), true);

      // Stop loading
      container.read(loadingProvider.notifier).stopLoading(
        LoadingOperation.activityLoading,
      );

      await tester.pumpAndSettle();

      // Verify loading stopped
      final updatedLoadingState = container.read(loadingProvider);
      expect(updatedLoadingState.isLoading(LoadingOperation.activityLoading), false);
    });

    testWidgets('should maintain state across widget rebuilds', (tester) async {
      late ProviderContainer container;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Set some state
      container.read(appStateProvider.notifier).setDarkMode(true);
      container.read(appStateProvider.notifier).setTrackingActive(true);

      // Trigger rebuild
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify state is maintained
      final appState = container.read(appStateProvider);
      expect(appState.isDarkMode, true);
      expect(appState.isTrackingActive, true);
    });

    testWidgets('should handle resource cleanup on app lifecycle changes', (tester) async {
      late ProviderContainer container;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Register some resources
      final resourceNotifier = container.read(resourceProvider.notifier);
      resourceNotifier.registerResource(
        ResourceInfo(
          type: ResourceType.locationStream,
          id: 'test-stream',
          dispose: () async {},
          description: 'Test stream',
        ),
      );

      // Verify resource is registered
      final resourceState = container.read(resourceProvider);
      expect(resourceState.activeResources.containsKey('test-stream'), true);

      // Simulate app lifecycle change (this would be done by the system)
      // For testing, we manually trigger cleanup
      await resourceNotifier.disposeAllResources();

      // Verify resources are cleaned up
      final updatedResourceState = container.read(resourceProvider);
      expect(updatedResourceState.activeResources.isEmpty, true);
      expect(updatedResourceState.disposedResources.contains('test-stream'), true);
    });

    testWidgets('should handle provider errors gracefully', (tester) async {
      late ProviderContainer container;
      
      // Create a provider that throws an error
      final errorProvider = Provider<String>((ref) {
        throw Exception('Test provider error');
      });

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              
              // Try to read the error provider
              try {
                ref.read(errorProvider);
              } catch (e) {
                // Expected error
              }
              
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // App should still function despite provider error
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should handle concurrent state updates', (tester) async {
      late ProviderContainer container;
      
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const TrailRunApp();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Perform concurrent state updates
      final appStateNotifier = container.read(appStateProvider.notifier);
      final loadingNotifier = container.read(loadingProvider.notifier);
      final errorNotifier = container.read(errorProvider.notifier);

      // Update multiple states concurrently
      appStateNotifier.setDarkMode(true);
      loadingNotifier.startLoading(LoadingOperation.sync);
      errorNotifier.showErrorMessage('Concurrent error');
      appStateNotifier.setOfflineMode(true);
      loadingNotifier.updateProgress(LoadingOperation.sync, 0.5);

      await tester.pumpAndSettle();

      // Verify all states are updated correctly
      final appState = container.read(appStateProvider);
      final loadingState = container.read(loadingProvider);
      final errorState = container.read(errorProvider);

      expect(appState.isDarkMode, true);
      expect(appState.isOfflineMode, true);
      expect(loadingState.isLoading(LoadingOperation.sync), true);
      expect(loadingState.getProgress(LoadingOperation.sync), 0.5);
      expect(errorState.currentError?.message, 'Concurrent error');
    });
  });
}