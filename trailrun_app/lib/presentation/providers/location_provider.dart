import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/track_point.dart';
import '../../domain/repositories/location_repository.dart';
import '../../data/services/location_service_provider.dart';

/// Location state
class LocationState {
  const LocationState({
    this.currentLocation,
    this.isTracking = false,
    this.accuracy,
    this.quality,
    this.permissionStatus = LocationPermissionStatus.notRequested,
    this.isServiceEnabled = false,
    this.error,
  });

  final TrackPoint? currentLocation;
  final bool isTracking;
  final double? accuracy;
  final LocationQuality? quality;
  final LocationPermissionStatus permissionStatus;
  final bool isServiceEnabled;
  final String? error;

  LocationState copyWith({
    TrackPoint? currentLocation,
    bool? isTracking,
    double? accuracy,
    LocationQuality? quality,
    LocationPermissionStatus? permissionStatus,
    bool? isServiceEnabled,
    String? error,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      accuracy: accuracy ?? this.accuracy,
      quality: quality ?? this.quality,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isServiceEnabled: isServiceEnabled ?? this.isServiceEnabled,
      error: error ?? this.error,
    );
  }
}

/// Location state notifier
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier(this._locationRepository) : super(const LocationState()) {
    _initialize();
  }

  final LocationRepository _locationRepository;

  Future<void> _initialize() async {
    try {
      final permissionStatus = await _locationRepository.getPermissionStatus();
      final isServiceEnabled = await _locationRepository.isLocationServiceEnabled();
      
      state = state.copyWith(
        permissionStatus: permissionStatus,
        isServiceEnabled: isServiceEnabled,
      );

      // Listen to location updates
      _locationRepository.locationStream.listen(
        (location) {
          state = state.copyWith(
            currentLocation: location,
            error: null,
          );
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );

      // Listen to quality updates
      _locationRepository.locationQualityStream.listen(
        (quality) {
          state = state.copyWith(quality: quality);
        },
      );

      // Listen to tracking state
      _locationRepository.trackingStateStream.listen(
        (trackingState) {
          state = state.copyWith(
            isTracking: trackingState == LocationTrackingState.active,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> requestPermission() async {
    try {
      final status = await _locationRepository.requestPermission();
      state = state.copyWith(permissionStatus: status);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> startTracking() async {
    try {
      await _locationRepository.startLocationTracking();
      state = state.copyWith(isTracking: true, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopTracking() async {
    try {
      await _locationRepository.stopLocationTracking();
      state = state.copyWith(isTracking: false, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for location state
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationRepository = ref.watch(locationServiceProvider);
  return LocationNotifier(locationRepository);
});

/// Provider for current location (convenience)
final currentLocationProvider = Provider<TrackPoint?>((ref) {
  return ref.watch(locationProvider).currentLocation;
});

/// Provider for location permission status (convenience)
final locationPermissionStatusProvider = Provider<LocationPermissionStatus>((ref) {
  return ref.watch(locationProvider).permissionStatus;
});

/// Provider for location quality (convenience)
final locationQualityProvider = Provider<LocationQuality?>((ref) {
  return ref.watch(locationProvider).quality;
});
