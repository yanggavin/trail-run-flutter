import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/providers/loading_provider.dart';

void main() {
  group('LoadingProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state', () {
      final state = container.read(loadingProvider);

      expect(state.activeOperations, isEmpty);
      expect(state.progress, isEmpty);
      expect(state.isAnyLoading, false);
    });

    test('should start loading operation', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.activityLoading);
      
      final state = container.read(loadingProvider);
      expect(state.isLoading(LoadingOperation.activityLoading), true);
      expect(state.isAnyLoading, true);
    });

    test('should start loading with initial progress', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.sync, initialProgress: 0.3);
      
      final state = container.read(loadingProvider);
      expect(state.isLoading(LoadingOperation.sync), true);
      expect(state.getProgress(LoadingOperation.sync), 0.3);
    });

    test('should update progress', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.export);
      notifier.updateProgress(LoadingOperation.export, 0.7);
      
      final state = container.read(loadingProvider);
      expect(state.getProgress(LoadingOperation.export), 0.7);
    });

    test('should clamp progress between 0 and 1', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.share);
      notifier.updateProgress(LoadingOperation.share, -0.5);
      expect(container.read(loadingProvider).getProgress(LoadingOperation.share), 0.0);
      
      notifier.updateProgress(LoadingOperation.share, 1.5);
      expect(container.read(loadingProvider).getProgress(LoadingOperation.share), 1.0);
    });

    test('should not update progress for non-active operation', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.updateProgress(LoadingOperation.photoCapture, 0.5);
      
      final state = container.read(loadingProvider);
      expect(state.getProgress(LoadingOperation.photoCapture), null);
    });

    test('should stop loading operation', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.activitySaving);
      expect(container.read(loadingProvider).isLoading(LoadingOperation.activitySaving), true);
      
      notifier.stopLoading(LoadingOperation.activitySaving);
      
      final state = container.read(loadingProvider);
      expect(state.isLoading(LoadingOperation.activitySaving), false);
      expect(state.getProgress(LoadingOperation.activitySaving), null);
    });

    test('should handle multiple loading operations', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.activityLoading);
      notifier.startLoading(LoadingOperation.photoLoading);
      notifier.startLoading(LoadingOperation.sync);
      
      final state = container.read(loadingProvider);
      expect(state.activeOperations.length, 3);
      expect(state.isAnyLoading, true);
      expect(state.isLoading(LoadingOperation.activityLoading), true);
      expect(state.isLoading(LoadingOperation.photoLoading), true);
      expect(state.isLoading(LoadingOperation.sync), true);
    });

    test('should stop all loading operations', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.activityLoading);
      notifier.startLoading(LoadingOperation.photoLoading);
      notifier.updateProgress(LoadingOperation.activityLoading, 0.5);
      
      notifier.stopAllLoading();
      
      final state = container.read(loadingProvider);
      expect(state.activeOperations, isEmpty);
      expect(state.progress, isEmpty);
      expect(state.isAnyLoading, false);
    });

    test('convenience providers should work correctly', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.appInitialization);
      expect(container.read(isAppInitializingProvider), true);
      
      notifier.startLoading(LoadingOperation.activityLoading);
      expect(container.read(isActivityLoadingProvider), true);
      
      notifier.startLoading(LoadingOperation.photoCapture);
      expect(container.read(isPhotoCaptureLoadingProvider), true);
      
      notifier.stopLoading(LoadingOperation.appInitialization);
      expect(container.read(isAppInitializingProvider), false);
    });
  });

  group('LoadingHelper', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle loading operations directly through notifier', () async {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.activitySaving);
      expect(container.read(loadingProvider).isLoading(LoadingOperation.activitySaving), true);
      
      notifier.stopLoading(LoadingOperation.activitySaving);
      expect(container.read(loadingProvider).isLoading(LoadingOperation.activitySaving), false);
    });

    test('should handle progress updates directly through notifier', () {
      final notifier = container.read(loadingProvider.notifier);
      
      notifier.startLoading(LoadingOperation.export);
      notifier.updateProgress(LoadingOperation.export, 0.8);
      
      expect(container.read(loadingProvider).getProgress(LoadingOperation.export), 0.8);
    });
  });
}