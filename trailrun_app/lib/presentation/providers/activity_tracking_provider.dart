import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../../data/services/activity_tracking_service.dart';
import '../../data/services/activity_tracking_provider.dart' as service_provider;

/// Activity tracking state
class ActivityTrackingState {
  const ActivityTrackingState({
    this.currentActivity,
    this.isTracking = false,
    this.isPaused = false,
    this.isAutopaused = false,
    this.elapsedTime = Duration.zero,
    this.distance = 0.0,
    this.currentPace = 0.0,
    this.averagePace = 0.0,
    this.elevationGain = 0.0,
    this.elevationLoss = 0.0,
    this.trackPointCount = 0,
    this.photoCount = 0,
    this.error,
  });

  final Activity? currentActivity;
  final bool isTracking;
  final bool isPaused;
  final bool isAutopaused;
  final Duration elapsedTime;
  final double distance;
  final double currentPace;
  final double averagePace;
  final double elevationGain;
  final double elevationLoss;
  final int trackPointCount;
  final int photoCount;
  final String? error;

  ActivityTrackingState copyWith({
    Activity? currentActivity,
    bool? isTracking,
    bool? isPaused,
    bool? isAutopaused,
    Duration? elapsedTime,
    double? distance,
    double? currentPace,
    double? averagePace,
    double? elevationGain,
    double? elevationLoss,
    int? trackPointCount,
    int? photoCount,
    String? error,
  }) {
    return ActivityTrackingState(
      currentActivity: currentActivity ?? this.currentActivity,
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      isAutopaused: isAutopaused ?? this.isAutopaused,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      distance: distance ?? this.distance,
      currentPace: currentPace ?? this.currentPace,
      averagePace: averagePace ?? this.averagePace,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      trackPointCount: trackPointCount ?? this.trackPointCount,
      photoCount: photoCount ?? this.photoCount,
      error: error ?? this.error,
    );
  }

  bool get canStart => !isTracking && currentActivity == null;
  bool get canPause => isTracking && !isPaused;
  bool get canResume => isTracking && isPaused;
  bool get canStop => isTracking;
}

/// Activity tracking notifier
class ActivityTrackingNotifier extends StateNotifier<ActivityTrackingState> {
  ActivityTrackingNotifier(this._trackingService) : super(const ActivityTrackingState()) {
    _initialize();
  }

  final ActivityTrackingService _trackingService;

  void _initialize() {
    // Listen to activity updates
    _trackingService.currentActivityStream.listen(
      (activity) {
        state = state.copyWith(currentActivity: activity);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );

    // Listen to tracking state updates
    _trackingService.trackingStateStream.listen(
      (trackingState) {
        state = state.copyWith(
          isTracking: trackingState.isTracking,
          isPaused: trackingState.isPaused,
          isAutopaused: trackingState.isAutopaused,
        );
      },
    );

    // Listen to statistics updates
    _trackingService.statisticsStream.listen(
      (stats) {
        state = state.copyWith(
          elapsedTime: stats.elapsedTime,
          distance: stats.distanceMeters,
          currentPace: stats.currentPaceSecondsPerKm,
          averagePace: stats.averagePaceSecondsPerKm,
          elevationGain: stats.elevationGainMeters,
          elevationLoss: stats.elevationLossMeters,
          trackPointCount: stats.trackPointCount,
          photoCount: stats.photoCount,
        );
      },
    );
  }

  Future<void> startActivity() async {
    try {
      await _trackingService.startActivity();
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pauseActivity() async {
    try {
      await _trackingService.pauseActivity();
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeActivity() async {
    try {
      await _trackingService.resumeActivity();
      state = state.copyWith(error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Activity?> stopActivity() async {
    try {
      final activity = await _trackingService.stopActivity();
      state = state.copyWith(error: null);
      return activity;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _trackingService.dispose();
    super.dispose();
  }
}

/// Provider for activity tracking service
final activityTrackingServiceProvider = Provider<ActivityTrackingService>((ref) {
  return service_provider.ActivityTrackingProvider.getInstance();
});

/// Provider for activity tracking state
final activityTrackingProvider = StateNotifierProvider<ActivityTrackingNotifier, ActivityTrackingState>((ref) {
  final trackingService = ref.watch(activityTrackingServiceProvider);
  return ActivityTrackingNotifier(trackingService);
});

/// Convenience providers for specific tracking state
final isTrackingProvider = Provider<bool>((ref) {
  return ref.watch(activityTrackingProvider).isTracking;
});

final currentActivityProvider = Provider<Activity?>((ref) {
  return ref.watch(activityTrackingProvider).currentActivity;
});

final trackingStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(activityTrackingProvider);
  return {
    'distance': state.distance,
    'elapsedTime': state.elapsedTime,
    'currentPace': state.currentPace,
    'averagePace': state.averagePace,
    'elevationGain': state.elevationGain,
    'elevationLoss': state.elevationLoss,
    'trackPointCount': state.trackPointCount,
    'photoCount': state.photoCount,
  };
});