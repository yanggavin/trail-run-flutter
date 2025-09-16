import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../../../lib/data/services/photo_service.dart';
import '../../../lib/domain/value_objects/coordinates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PhotoService', () {
    group('createCameraController', () {
      test('creates controller with correct settings', () {
        final camera = CameraDescription(
          name: 'test_camera',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        );

        final controller = PhotoService.createCameraController(camera);

        expect(controller.description, equals(camera));
        expect(controller.resolutionPreset, equals(ResolutionPreset.high));
      });
    });

    group('calculateCurationScore', () {
      test('returns 0.0 for invalid file', () async {
        final score = await PhotoService.calculateCurationScore('invalid/path');
        expect(score, equals(0.0)); // Returns 0.0 when file doesn't exist
      });
    });

    group('photoFileExists', () {
      test('returns false for non-existent file', () async {
        final exists = await PhotoService.photoFileExists('invalid/path');
        expect(exists, isFalse);
      });
    });

    group('getPhotoBytes', () {
      test('returns null for non-existent file', () async {
        final bytes = await PhotoService.getPhotoBytes('invalid/path');
        expect(bytes, isNull);
      });
    });

    group('getPhotoFileSize', () {
      test('returns 0 for non-existent file', () async {
        final size = await PhotoService.getPhotoFileSize('invalid/path');
        expect(size, equals(0));
      });
    });

    group('getAvailableCameras', () {
      test('handles camera availability gracefully', () async {
        // This test will pass or fail based on device capabilities
        try {
          final cameras = await PhotoService.getAvailableCameras();
          expect(cameras, isA<List<CameraDescription>>());
        } catch (e) {
          expect(e, isA<PhotoServiceException>());
        }
      });
    });

    // Note: cleanupOrphanedFiles test removed as it requires platform channels
  });

  group('PhotoServiceException', () {
    test('creates exception with message', () {
      const message = 'Test error';
      final exception = PhotoServiceException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('PhotoServiceException: $message'));
    });
  });
}