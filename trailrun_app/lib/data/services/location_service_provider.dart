import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/location_repository.dart';
import '../../domain/models/track_point.dart';
import 'location_service_factory.dart';

/// Provider for the location service
final locationServiceProvider = Provider<LocationRepository>((ref) {
  return LocationServiceFactory.create();
});

/// Provider for location tracking state
final locationTrackingStateProvider = StreamProvider<LocationTrackingState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.trackingStateStream;
});

/// Provider for location updates
final locationStreamProvider = StreamProvider<TrackPoint>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.locationStream;
});

/// Provider for location quality updates
final locationQualityProvider = StreamProvider<LocationQuality>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.locationQualityStream;
});

/// Provider for location permission status
final locationPermissionProvider = FutureProvider<LocationPermissionStatus>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPermissionStatus();
});

/// Provider for location service enabled status
final locationServiceEnabledProvider = FutureProvider<bool>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.isLocationServiceEnabled();
});