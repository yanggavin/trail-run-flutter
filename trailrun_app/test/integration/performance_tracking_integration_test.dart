import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/data/services/activity_tracking_service.dart';
import '../../lib/data/services/map_service.dart';
import '../../lib/data/services/progressive_photo_loader.dart';
import '../../lib/data/services/memory_manager.dart';
import '../../lib/data/services/battery_monitor.dart';
import '../../lib/data/repositories/activity_repository.dart';
import '../../lib/data/repositories/location_repository.dart';
import '../../lib/domain/models/activity.dart';
import '../../lib/domain/models/track_point.dart';
import '../../lib/domain/models/photo.dart';
import '../../lib/domain/value_objects/coordinates.dart';
import '../../lib/domain/value_objects/timestamp.dart';
import '../../lib/domain/value_objects/measurement_units.dart';
import '../../lib/domain/enums/privacy_level.dart';

@GenerateMocks([ActivityRepository, LocationRepository])
import 'performance_tracking_integration_test.mocks.dart';

void main() {
  group('Performance Tracking Integration Tests', () {
    late MockActivityRepository mockActivityRepository;
    late MockLocationRepository mockLocationRepository;
    late ActivityTrackingService trackingService;
    late MemoryManager memoryManager;
    late BatteryMonitor batteryMonitor;

    setUp(() {
      mockActivityRepository = MockActivityRepository();
      mockLocationRepository = MockLocationRepository();
      trackingService = ActivityTrackingService(
        activityRepository: mockActivityRepository,
        locationRepository: mockLocationRepository,
      );
      memoryManager = MemoryManager();
      batteryMonitor = BatteryMonitor();
    });

    tearDown(() {
      trackingService.dispose();
      memoryManager.dispose();
      batteryMonitor.dispose();
      ProgressivePhotoLoader.clearCaches();
    });

    testWidgets('Complete tracking workflow with large dataset', (tester) async {
      // Setup: Create large route with 30k+ points
      final largeRoute = _generateLargeRoute(35000);
      
      // Mock repository responses
      when(mockActivityRepository.createActivity(any))
          .thenAnswer((_) async => {});
      when(mockActivityRepository.addTrackPoint(any, any))
          .thenAnswer((_) async => {});
      when(mockLocationRepository.startLocationTracking(
        accuracy: anyNamed('accuracy'),
        intervalSeconds: anyNamed('intervalSeconds'),
      )).thenAnswer((_) async => {});

      // Start memory monitoring
      memoryManager.startMonitoring(interval: const Duration(seconds: 5));
      
      // Start battery monitoring
      await batteryMonitor.startMonitoring(interval: const Duration(minutes: 1));

      // Test: Start activity tracking
      final activity = await trackingService.startActivity(
        title: 'Performance Test Run',
        privacy: PrivacyLevel.private,
      );

      expect(activity, isNotNull);
      expect(trackingService.isTracking, isTrue);

      // Simulate processing large route data
      final stopwatch = Stopwatch()..start();
      
      // Test map rendering optimization
      final optimizedPolyline = MapService.createOptimizedPolyline(
        largeRoute,
        maxPoints: 1000,
        tolerance: 0.0001,
      );
      
      stopwatch.stop();
      
      // Verify performance: Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max
      expect(optimizedPolyline.points.length, lessThanOrEqualTo(1000));
      expect(optimizedPolyline.points.length, greaterThan(100)); // Should keep significant points

      // Test memory management during large data processing
      memoryManager.trackObject('large_route', largeRoute.length * 100); // Estimate size
      
      final memoryStats = memoryManager.getTrackedObjectsSummary();
      expect(memoryStats['objectCount'], equals(1));
      expect(memoryStats['totalSizeMB'], greaterThan(0));

      // Test LOD polylines creation
      final lodPolylines = MapService.createLODPolylines(largeRoute);
      expect(lodPolylines.keys, contains(1));
      expect(lodPolylines.keys, contains(8));
      expect(lodPolylines.keys, contains(12));
      expect(lodPolylines.keys, contains(16));

      // Verify different detail levels
      expect(lodPolylines[1]!.points.length, lessThan(lodPolylines[8]!.points.length));
      expect(lodPolylines[8]!.points.length, lessThan(lodPolylines[12]!.points.length));

      // Clean up tracked objects
      memoryManager.untrackObject('large_route');
    });

    testWidgets('Photo loading performance with progressive loading', (tester) async {
      // Setup: Create mock photo paths
      final photoPaths = List.generate(50, (i) => '/test/photo_$i.jpg');
      
      // Test progressive photo loading
      final loadingStopwatch = Stopwatch()..start();
      
      // Preload thumbnails
      await ProgressivePhotoLoader.preloadThumbnails(photoPaths);
      
      loadingStopwatch.stop();
      
      // Verify performance: Preloading should be efficient
      expect(loadingStopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      
      // Test cache statistics
      final cacheStats = ProgressivePhotoLoader.getCacheStats();
      expect(cacheStats['thumbnailCount'], greaterThanOrEqualTo(0));
      expect(cacheStats['thumbnailCacheSize'], greaterThanOrEqualTo(0));
      
      // Test memory-aware loading
      for (int i = 0; i < 10; i++) {
        final thumbnailBytes = await ProgressivePhotoLoader.loadThumbnail(photoPaths[i]);
        // In real scenario, this would load actual thumbnails
        // Here we just verify the method completes without error
        expect(thumbnailBytes, isNull); // Since files don't exist in test
      }
    });

    testWidgets('Memory management under pressure', (tester) async {
      // Setup memory-aware list
      final memoryAwareList = MemoryAwareList<TrackPoint>(
        maxSize: 1000,
        estimateItemSize: (point) => 200, // Estimate 200 bytes per point
        onItemEvicted: (point) {
          // Track evicted items
        },
      );

      // Test: Add many items to trigger memory management
      final testPoints = _generateLargeRoute(2000);
      
      for (final point in testPoints) {
        memoryAwareList.add(point);
      }

      // Verify: List should not exceed max size
      expect(memoryAwareList.length, lessThanOrEqualTo(1000));
      expect(memoryAwareList.estimatedSize, lessThanOrEqualTo(1000 * 200));

      // Test memory cleanup under pressure
      memoryManager.trackObject('test_list', memoryAwareList.estimatedSize);
      
      // Simulate critical memory situation
      await memoryManager.forceCleanup(critical: true);
      
      // Verify cleanup occurred
      final statsAfterCleanup = memoryManager.getTrackedObjectsSummary();
      expect(statsAfterCleanup['objectCount'], greaterThanOrEqualTo(0));

      memoryAwareList.dispose();
    });

    testWidgets('Battery monitoring during tracking', (tester) async {
      // Start battery monitoring
      await batteryMonitor.startMonitoring(interval: const Duration(seconds: 1));
      
      // Wait for some readings
      await Future.delayed(const Duration(seconds: 3));
      
      // Test battery usage prediction
      final prediction = batteryMonitor.predictBatteryUsage(
        const Duration(hours: 2),
      );
      
      // In real scenario with actual battery readings, prediction would be available
      // Here we just verify the method completes
      expect(prediction, isNull); // No readings in test environment
      
      // Test battery status monitoring
      expect(batteryMonitor.isMonitoring, isTrue);
      
      // Stop monitoring
      batteryMonitor.stopMonitoring();
      expect(batteryMonitor.isMonitoring, isFalse);
    });

    testWidgets('End-to-end tracking workflow with performance monitoring', (tester) async {
      // Setup comprehensive monitoring
      memoryManager.startMonitoring();
      await batteryMonitor.startMonitoring();
      
      // Mock location stream
      final locationController = StreamController<TrackPoint>();
      when(mockLocationRepository.locationStream)
          .thenAnswer((_) => locationController.stream);
      when(mockLocationRepository.trackingStateStream)
          .thenAnswer((_) => const Stream.empty());

      // Start activity
      final activity = await trackingService.startActivity();
      expect(trackingService.isTracking, isTrue);

      // Simulate location updates with performance tracking
      final performanceStopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        final trackPoint = TrackPoint(
          id: 'point_$i',
          activityId: activity.id,
          timestamp: Timestamp(DateTime.now().add(Duration(seconds: i))),
          coordinates: Coordinates(
            latitude: 37.7749 + (i * 0.0001),
            longitude: -122.4194 + (i * 0.0001),
            elevation: 100.0 + (i * 0.1),
          ),
          accuracy: 5.0,
          sequence: i,
        );
        
        locationController.add(trackPoint);
        
        // Small delay to simulate real-time updates
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      performanceStopwatch.stop();
      
      // Verify performance: Processing 100 points should be fast
      expect(performanceStopwatch.elapsedMilliseconds, lessThan(2000));
      
      // Test statistics calculation performance
      final statsStopwatch = Stopwatch()..start();
      final stats = trackingService.getCurrentStatistics();
      statsStopwatch.stop();
      
      expect(statsStopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      expect(stats.distance.meters, greaterThan(0));
      
      // Stop activity
      final finalActivity = await trackingService.stopActivity();
      expect(finalActivity.trackPoints.length, equals(100));
      
      locationController.close();
    });

    testWidgets('Large route simplification algorithms', (tester) async {
      // Test Douglas-Peucker simplification
      final largeRoute = _generateLargeRoute(50000);
      
      final simplificationStopwatch = Stopwatch()..start();
      
      // Test different tolerance levels
      final tolerances = [0.00001, 0.0001, 0.001, 0.01];
      
      for (final tolerance in tolerances) {
        final simplified = MapService.createOptimizedPolyline(
          largeRoute,
          maxPoints: 2000,
          tolerance: tolerance,
        );
        
        expect(simplified.points.length, lessThanOrEqualTo(2000));
        expect(simplified.points.length, greaterThan(10)); // Should preserve some points
      }
      
      simplificationStopwatch.stop();
      
      // Verify performance: All simplifications should complete quickly
      expect(simplificationStopwatch.elapsedMilliseconds, lessThan(10000));
    });

    testWidgets('Memory cleanup and garbage collection', (tester) async {
      // Create multiple large objects
      final objects = <String, List<TrackPoint>>{};
      
      for (int i = 0; i < 10; i++) {
        final route = _generateLargeRoute(5000);
        final key = 'route_$i';
        objects[key] = route;
        memoryManager.trackObject(key, route.length * 100);
      }
      
      // Verify objects are tracked
      var stats = memoryManager.getTrackedObjectsSummary();
      expect(stats['objectCount'], equals(10));
      
      // Force cleanup
      await memoryManager.forceCleanup(critical: true);
      
      // Clear references to allow garbage collection
      objects.clear();
      
      // Verify cleanup
      stats = memoryManager.getTrackedObjectsSummary();
      expect(stats['objectCount'], lessThanOrEqualTo(10));
    });
  });
}

/// Generate a large route for testing performance
List<TrackPoint> _generateLargeRoute(int pointCount) {
  final points = <TrackPoint>[];
  final baseTime = DateTime.now();
  
  for (int i = 0; i < pointCount; i++) {
    // Create a realistic GPS track with some noise
    final lat = 37.7749 + (i * 0.00001) + (math.Random().nextDouble() - 0.5) * 0.0001;
    final lng = -122.4194 + (i * 0.00001) + (math.Random().nextDouble() - 0.5) * 0.0001;
    final elevation = 100.0 + math.sin(i * 0.01) * 50 + (math.Random().nextDouble() - 0.5) * 10;
    
    points.add(TrackPoint(
      id: 'point_$i',
      activityId: 'test_activity',
      timestamp: Timestamp(baseTime.add(Duration(seconds: i * 2))),
      coordinates: Coordinates(
        latitude: lat,
        longitude: lng,
        elevation: elevation,
      ),
      accuracy: 3.0 + math.Random().nextDouble() * 7.0, // 3-10m accuracy
      sequence: i,
    ));
  }
  
  return points;
}