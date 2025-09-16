import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../../domain/enums/privacy_level.dart';

/// Global app state
class AppState {
  const AppState({
    this.isInitialized = false,
    this.currentActivity,
    this.isTrackingActive = false,
    this.isDarkMode = false,
    this.selectedPrivacyLevel = PrivacyLevel.private,
    this.isOfflineMode = false,
    this.lastSyncTime,
    this.error,
  });

  final bool isInitialized;
  final Activity? currentActivity;
  final bool isTrackingActive;
  final bool isDarkMode;
  final PrivacyLevel selectedPrivacyLevel;
  final bool isOfflineMode;
  final DateTime? lastSyncTime;
  final String? error;

  AppState copyWith({
    bool? isInitialized,
    Activity? currentActivity,
    bool? isTrackingActive,
    bool? isDarkMode,
    PrivacyLevel? selectedPrivacyLevel,
    bool? isOfflineMode,
    DateTime? lastSyncTime,
    String? error,
    bool clearError = false,
  }) {
    return AppState(
      isInitialized: isInitialized ?? this.isInitialized,
      currentActivity: currentActivity ?? this.currentActivity,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedPrivacyLevel: selectedPrivacyLevel ?? this.selectedPrivacyLevel,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// App state notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize app state
    state = state.copyWith(isInitialized: true);
  }

  void setCurrentActivity(Activity? activity) {
    state = state.copyWith(currentActivity: activity);
  }

  void setTrackingActive(bool isActive) {
    state = state.copyWith(isTrackingActive: isActive);
  }

  void setDarkMode(bool isDark) {
    state = state.copyWith(isDarkMode: isDark);
  }

  void setPrivacyLevel(PrivacyLevel level) {
    state = state.copyWith(selectedPrivacyLevel: level);
  }

  void setOfflineMode(bool isOffline) {
    state = state.copyWith(isOfflineMode: isOffline);
  }

  void setLastSyncTime(DateTime time) {
    state = state.copyWith(lastSyncTime: time);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for global app state
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});