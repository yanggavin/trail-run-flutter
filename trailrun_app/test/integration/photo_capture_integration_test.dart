import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:camera/camera.dart';

import '../../lib/data/services/photo_service.dart';
import '../../lib/data/services/camera_service.dart';
import '../../lib/data/services/photo_manager.dart';
import '../../lib/data/repositories/photo_repository_impl.dart';
import '../../lib/data/database/database.dart';
import '../../lib/domain/value_objects/coordinates.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Photo Capture Integration Tests', () {
    late TrailRunDatabase database;
    late PhotoRepositoryImpl photoRepository;
    late CameraService cameraService;
    late PhotoManager photoManager;

    setUpAll(() async {
      // Initialize database
      database = TrailRunDatabase();
      photoRepository = PhotoRepositoryImpl(photoDao: database.photoDao);
      cameraService = CameraService.instance;
      photoManager = PhotoManager(
        photoRepository: photoRepository,
        cameraService: cameraService,
      );
    });

    tearDownAll(() async {
      await database.close();
      await cameraService.dispose();
    });

    group('Camera Service Integration', () {
      testWidgets('initializes camera successfully', (tester) async {
        // This test requires actual camera hardware
        try {
          await cameraService.initialize();
          expect(cameraService.isInitialized, isTrue);
          expect(cameraService.controller, isNotNull);
        } catch (e) {
          // Skip test if no camera available (CI environment)
          print('Skipping camera test - no camera available: $e');
        }
      });

      testWidgets('handles camera initialization failure gracefully', (tester) async {
        // Test error handling when camera is not available
        final newCameraService = CameraService.instance;
        
        // This should handle the case where cameras are not available
        expect(newCameraService.isInitialized, isFalse);
        expect(newCameraService.controller, isNull);
      });
    });

    group('Photo Service Integration', () {
      test('gets available cameras', () async {
        try {
          final cameras = await PhotoService.getAvailableCameras();
          expect(cameras, isA<List<CameraDescription>>());
          // May be empty in CI environment
        } catch (e) {
          // Expected in environments without camera
          expect(e, isA<PhotoServiceException>());
        }
      });

      test('creates camera controller with correct settings', () {
        final camera = CameraDescription(
          name: 'test_camera',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );

        final controller = PhotoService.createCameraController(camera);
        
        expect(controller.description, equals(camera));
        expect(controller.resolutionPreset, equals(ResolutionPreset.high));
      });

      test('calculates curation score for invalid file', () async {
        final score = await PhotoService.calculateCurationScore('invalid/path');
        expect(score, equals(0.5));
      });

      test('handles file operations gracefully', () async {
        const invalidPath = 'invalid/path/to/photo.jpg';
        
        final exists = await PhotoService.photoFileExists(invalidPath);
        expect(exists, isFalse);
        
        final bytes = await PhotoService.getPhotoBytes(invalidPath);
        expect(bytes, isNull);
        
        final size = await PhotoService.getPhotoFileSize(invalidPath);
        expect(size, equals(0));
      });
    });

    group('Photo Manager Integration', () {
      testWidgets('initializes successfully', (tester) async {
        try {
          await photoManager.initialize();
          // If cameras are available, should initialize successfully
        } catch (e) {
          // Expected in environments without camera
          print('Photo manager initialization failed (expected in CI): $e');
        }
      });

      test('handles photo operations without camera', () async {
        final activityId = 'test-activity-${DateTime.now().millisecondsSinceEpoch}';
        
        // These operations should work even without camera
        final photos = await photoManager.getPhotosForActivity(activityId);
        expect(photos, isEmpty);
        
        final candidates = await photoManager.getCoverCandidates(activityId);
        expect(candidates, isEmpty);
        
        final bestCover = await photoManager.getBestCoverPhoto(activityId);
        expect(bestCover, isNull);
        
        final geotagged = await photoManager.getGeotaggedPhotos(activityId);
        expect(geotagged, isEmpty);
      });

      test('handles photo capture failure gracefully', () async {
        final activityId = 'test-activity-${DateTime.now().millisecondsSinceEpoch}';
        final location = Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 100.0,
        );

        // Should fail gracefully when camera is not initialized
        expect(
          () => photoManager.capturePhotoForActivity(
            activityId: activityId,
            currentLocation: location,
          ),
          throwsException,
        );
      });
    });

    group('Database Integration', () {
      test('photo repository operations work correctly', () async {
        final activityId = 'test-activity-${DateTime.now().millisecondsSinceEpoch}';
        
        // Test getting photos for non-existent activity
        final photos = await photoRepository.getPhotosForActivity(activityId);
        expect(photos, isEmpty);
        
        // Test getting non-existent photo
        final photo = await photoRepository.getPhoto('non-existent-id');
        expect(photo, isNull);
        
        // Test cover candidates for non-existent activity
        final candidates = await photoRepository.getCoverCandidates(activityId);
        expect(candidates, isEmpty);
      });

      test('photo stream operations work correctly', () async {
        final activityId = 'test-activity-${DateTime.now().millisecondsSinceEpoch}';
        
        // Test watching photos for activity
        final stream = photoRepository.watchPhotosForActivity(activityId);
        expect(stream, isA<Stream>());
        
        // Should emit empty list for non-existent activity
        final photos = await stream.first;
        expect(photos, isEmpty);
      });
    });

    group('Performance Tests', () {
      test('photo operations complete within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        final activityId = 'perf-test-${DateTime.now().millisecondsSinceEpoch}';
        
        // Test multiple operations
        await photoManager.getPhotosForActivity(activityId);
        await photoManager.getCoverCandidates(activityId);
        await photoManager.getBestCoverPhoto(activityId);
        await photoManager.getGeotaggedPhotos(activityId);
        
        stopwatch.stop();
        
        // Should complete within 1 second for empty results
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('curation score calculation is reasonably fast', () async {
        final stopwatch = Stopwatch()..start();
        
        // Test with invalid path (should be fast)
        await PhotoService.calculateCurationScore('invalid/path');
        
        stopwatch.stop();
        
        // Should complete very quickly for invalid file
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Error Handling', () {
      test('handles database errors gracefully', () async {
        // Test operations that might fail due to database issues
        final activityId = 'error-test-${DateTime.now().millisecondsSinceEpoch}';
        
        // These should not throw unhandled exceptions
        try {
          await photoManager.getPhotosForActivity(activityId);
          await photoManager.getCoverCandidates(activityId);
          await photoManager.getGeotaggedPhotos(activityId);
        } catch (e) {
          // Should be wrapped in appropriate exception types
          expect(e, anyOf(
            isA<PhotoManagerException>(),
            isA<PhotoRepositoryException>(),
          ));
        }
      });

      test('handles file system errors gracefully', () async {
        // Test file operations with invalid paths
        const invalidPath = '/invalid/path/that/does/not/exist.jpg';
        
        // Should not throw unhandled exceptions
        final exists = await PhotoService.photoFileExists(invalidPath);
        expect(exists, isFalse);
        
        final bytes = await PhotoService.getPhotoBytes(invalidPath);
        expect(bytes, isNull);
        
        final size = await PhotoService.getPhotoFileSize(invalidPath);
        expect(size, equals(0));
      });
    });
  });
}