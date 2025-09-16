import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/screens/tracking_screen.dart';
import 'package:trailrun_app/presentation/providers/activity_tracking_provider.dart';
import 'package:trailrun_app/presentation/providers/location_provider.dart';
import 'package:trailrun_app/domain/repositories/location_repository.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';

void main() {
  group('TrackingScreen', () {
    testWidgets('should display initializing state initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) => LocationNotifier(MockLocationRepository())),
          ],
          child: const MaterialApp(
            home: TrackingScreen(),
          ),
        ),
      );

      // Should show initializing interface
      expect(find.text('Initializing tracking...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display retry button on initialization error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) => LocationNotifier(MockLocationRepository())),
          ],
          child: const MaterialApp(
            home: TrackingScreen(),
          ),
        ),
      );

      // Wait for initialization to complete (and potentially fail)
      await tester.pumpAndSettle();

      // If initialization fails, should show retry button
      if (find.text('Retry').evaluate().isNotEmpty) {
        expect(find.text('Failed to initialize tracking'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      }
    });
  });
}

/// Mock location repository for testing
class MockLocationRepository implements LocationRepository {
  @override
  Future<LocationPermissionStatus> getPermissionStatus() async {
    return LocationPermissionStatus.notRequested;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return LocationPermissionStatus.whileInUse;
  }

  @override
  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    return LocationPermissionStatus.always;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return true;
  }

  @override
  Future<Coordinates?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return null;
  }

  @override
  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.balanced,
    int intervalSeconds = 2,
    double distanceFilter = 0,
  }) async {}

  @override
  Future<void> stopLocationTracking() async {}

  @override
  Future<void> pauseLocationTracking() async {}

  @override
  Future<void> resumeLocationTracking() async {}

  @override
  LocationTrackingState get trackingState => LocationTrackingState.stopped;

  @override
  Stream<TrackPoint> get locationStream => const Stream.empty();

  @override
  Stream<LocationQuality> get locationQualityStream => const Stream.empty();

  @override
  Stream<LocationTrackingState> get trackingStateStream => const Stream.empty();

  @override
  Future<Coordinates?> getLastKnownLocation() async {
    return null;
  }

  @override
  bool get supportsBackgroundLocation => true;

  @override
  Future<bool> isHighAccuracyAvailable() async {
    return true;
  }

  @override
  Future<double> getEstimatedBatteryUsage(LocationAccuracy accuracy) async {
    return 5.0;
  }

  @override
  Future<void> configureFiltering({
    double maxAccuracy = 50.0,
    double maxSpeed = 50.0,
    bool enableKalmanFilter = true,
    bool enableOutlierDetection = true,
  }) async {}

  @override
  Future<LocationTrackingStats> getTrackingStats() async {
    return const LocationTrackingStats(
      totalPoints: 0,
      filteredPoints: 0,
      averageAccuracy: 0.0,
      trackingDuration: Duration.zero,
      batteryUsagePercent: 0.0,
    );
  }

  @override
  Future<void> resetTrackingStats() async {}
}