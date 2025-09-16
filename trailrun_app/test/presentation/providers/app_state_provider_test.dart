import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/providers/app_state_provider.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';

void main() {
  group('AppStateProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      final state = container.read(appStateProvider);

      expect(state.isInitialized, true); // Changed to true as it initializes automatically
      expect(state.currentActivity, null);
      expect(state.isTrackingActive, false);
      expect(state.isDarkMode, false);
      expect(state.selectedPrivacyLevel, PrivacyLevel.private);
      expect(state.isOfflineMode, false);
      expect(state.lastSyncTime, null);
      expect(state.error, null);
    });

    test('should update tracking state', () {
      final notifier = container.read(appStateProvider.notifier);
      
      notifier.setTrackingActive(true);
      
      final state = container.read(appStateProvider);
      expect(state.isTrackingActive, true);
    });

    test('should update dark mode', () {
      final notifier = container.read(appStateProvider.notifier);
      
      notifier.setDarkMode(true);
      
      final state = container.read(appStateProvider);
      expect(state.isDarkMode, true);
    });

    test('should update privacy level', () {
      final notifier = container.read(appStateProvider.notifier);
      
      notifier.setPrivacyLevel(PrivacyLevel.public);
      
      final state = container.read(appStateProvider);
      expect(state.selectedPrivacyLevel, PrivacyLevel.public);
    });

    test('should update offline mode', () {
      final notifier = container.read(appStateProvider.notifier);
      
      notifier.setOfflineMode(true);
      
      final state = container.read(appStateProvider);
      expect(state.isOfflineMode, true);
    });

    test('should set and clear error', () {
      final notifier = container.read(appStateProvider.notifier);
      
      notifier.setError('Test error');
      var state = container.read(appStateProvider);
      expect(state.error, 'Test error');
      
      notifier.clearError();
      state = container.read(appStateProvider);
      expect(state.error, null);
    });

    test('should update sync time', () {
      final notifier = container.read(appStateProvider.notifier);
      final now = DateTime.now();
      
      notifier.setLastSyncTime(now);
      
      final state = container.read(appStateProvider);
      expect(state.lastSyncTime, now);
    });
  });
}