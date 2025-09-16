import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/data/services/photo_manager.dart';
import '../../../lib/data/services/camera_service.dart';
import '../../../lib/domain/repositories/photo_repository.dart';
import '../../../lib/domain/models/photo.dart';
import '../../../lib/domain/value_objects/coordinates.dart';
import '../../../lib/domain/value_objects/timestamp.dart';

@GenerateMocks([PhotoRepository, CameraService])
import 'photo_manager_test.mocks.dart';

void main() {
  group('PhotoManager', () {
    late PhotoManager photoManager;
    late MockPhotoRepository mockPhotoRepository;
    late MockCameraService mockCameraService;

    setUp(() {
      mockPhotoRepository = MockPhotoRepository();
      mockCameraService = MockCameraService();
      photoManager = PhotoManager(
        photoRepository: mockPhotoRepository,
        cameraService: mockCameraService,
      );
    });

    group('initialize', () {
      test('initializes camera service', () async {
        when(mockCameraService.initialize()).thenAnswer((_) async {});

        await photoManager.initialize();

        verify(mockCameraService.initialize()).called(1);
      });

      test('handles camera initialization failure', () async {
        when(mockCameraService.initialize()).thenThrow(Exception('Camera error'));

        expect(
          () => photoManager.initialize(),
          throwsException,
        );
      });
    });

    group('capturePhotoForActivity', () {
      test('captures and saves photo successfully', () async {
        // Arrange
        final activityId = 'test-activity';
        final location = Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 100.0,
        );
        final capturedPhoto = Photo(
          id: 'photo-1',
          activityId: activityId,
          timestamp: Timestamp.now(),
          coordinates: location,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/path/to/thumb.jpg',
          hasExifData: true,
          curationScore: 0.5,
        );

        when(mockCameraService.capturePhotoForActivity(
          activityId: activityId,
          currentLocation: location,
        )).thenAnswer((_) async => capturedPhoto);

        when(mockPhotoRepository.createPhoto(capturedPhoto))
            .thenAnswer((_) async => capturedPhoto);

        // Act
        final result = await photoManager.capturePhotoForActivity(
          activityId: activityId,
          currentLocation: location,
        );

        // Assert
        expect(result, equals(capturedPhoto));
        verify(mockCameraService.capturePhotoForActivity(
          activityId: activityId,
          currentLocation: location,
        )).called(1);
        verify(mockPhotoRepository.createPhoto(capturedPhoto)).called(1);
      });

      test('handles camera capture failure', () async {
        // Arrange
        final activityId = 'test-activity';
        
        when(mockCameraService.capturePhotoForActivity(
          activityId: activityId,
        )).thenThrow(Exception('Camera error'));

        // Act & Assert
        expect(
          () => photoManager.capturePhotoForActivity(activityId: activityId),
          throwsA(isA<PhotoManagerException>()),
        );
      });

      test('handles repository save failure', () async {
        // Arrange
        final activityId = 'test-activity';
        final capturedPhoto = Photo(
          id: 'photo-1',
          activityId: activityId,
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
        );

        when(mockCameraService.capturePhotoForActivity(
          activityId: activityId,
        )).thenAnswer((_) async => capturedPhoto);

        when(mockPhotoRepository.createPhoto(capturedPhoto))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => photoManager.capturePhotoForActivity(activityId: activityId),
          throwsA(isA<PhotoManagerException>()),
        );
      });
    });

    group('getPhotosForActivity', () {
      test('returns photos from repository', () async {
        // Arrange
        final activityId = 'test-activity';
        final photos = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
          ),
          Photo(
            id: 'photo-2',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo2.jpg',
          ),
        ];

        when(mockPhotoRepository.getPhotosForActivity(activityId))
            .thenAnswer((_) async => photos);

        // Act
        final result = await photoManager.getPhotosForActivity(activityId);

        // Assert
        expect(result, equals(photos));
        verify(mockPhotoRepository.getPhotosForActivity(activityId)).called(1);
      });

      test('handles repository failure', () async {
        // Arrange
        final activityId = 'test-activity';
        
        when(mockPhotoRepository.getPhotosForActivity(activityId))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => photoManager.getPhotosForActivity(activityId),
          throwsA(isA<PhotoManagerException>()),
        );
      });
    });

    group('watchPhotosForActivity', () {
      test('returns stream from repository', () {
        // Arrange
        final activityId = 'test-activity';
        final photos = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
          ),
        ];

        when(mockPhotoRepository.watchPhotosForActivity(activityId))
            .thenAnswer((_) => Stream.value(photos));

        // Act
        final stream = photoManager.watchPhotosForActivity(activityId);

        // Assert
        expect(stream, emits(photos));
        verify(mockPhotoRepository.watchPhotosForActivity(activityId)).called(1);
      });
    });

    group('getCoverCandidates', () {
      test('returns cover candidates from repository', () async {
        // Arrange
        final activityId = 'test-activity';
        final candidates = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
            curationScore: 0.8,
          ),
        ];

        when(mockPhotoRepository.getCoverCandidates(activityId))
            .thenAnswer((_) async => candidates);

        // Act
        final result = await photoManager.getCoverCandidates(activityId);

        // Assert
        expect(result, equals(candidates));
        verify(mockPhotoRepository.getCoverCandidates(activityId)).called(1);
      });
    });

    group('updatePhotoCaption', () {
      test('updates photo caption successfully', () async {
        // Arrange
        final photoId = 'photo-1';
        final caption = 'Beautiful trail view';
        final photo = Photo(
          id: photoId,
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
        );
        final updatedPhoto = photo.copyWith(caption: caption);

        when(mockPhotoRepository.getPhoto(photoId))
            .thenAnswer((_) async => photo);
        when(mockPhotoRepository.updatePhoto(updatedPhoto))
            .thenAnswer((_) async => updatedPhoto);

        // Act
        await photoManager.updatePhotoCaption(photoId, caption);

        // Assert
        verify(mockPhotoRepository.getPhoto(photoId)).called(1);
        verify(mockPhotoRepository.updatePhoto(updatedPhoto)).called(1);
      });

      test('throws exception when photo not found', () async {
        // Arrange
        final photoId = 'photo-1';
        final caption = 'Beautiful trail view';

        when(mockPhotoRepository.getPhoto(photoId))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => photoManager.updatePhotoCaption(photoId, caption),
          throwsA(isA<PhotoManagerException>()),
        );
      });
    });

    group('deletePhoto', () {
      test('deletes photo successfully', () async {
        // Arrange
        final photoId = 'photo-1';

        when(mockPhotoRepository.deletePhoto(photoId))
            .thenAnswer((_) async {});

        // Act
        await photoManager.deletePhoto(photoId);

        // Assert
        verify(mockPhotoRepository.deletePhoto(photoId)).called(1);
      });
    });

    group('deletePhotosForActivity', () {
      test('deletes all photos for activity successfully', () async {
        // Arrange
        final activityId = 'activity-1';

        when(mockPhotoRepository.deletePhotosForActivity(activityId))
            .thenAnswer((_) async {});

        // Act
        await photoManager.deletePhotosForActivity(activityId);

        // Assert
        verify(mockPhotoRepository.deletePhotosForActivity(activityId)).called(1);
      });
    });

    group('stripExifData', () {
      test('strips EXIF data successfully', () async {
        // Arrange
        final photoId = 'photo-1';

        when(mockPhotoRepository.stripExifData(photoId))
            .thenAnswer((_) async {});

        // Act
        await photoManager.stripExifData(photoId);

        // Assert
        verify(mockPhotoRepository.stripExifData(photoId)).called(1);
      });
    });

    group('getGeotaggedPhotos', () {
      test('returns only photos with location data', () async {
        // Arrange
        final activityId = 'activity-1';
        final photos = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
            coordinates: Coordinates(latitude: 37.7749, longitude: -122.4194),
          ),
          Photo(
            id: 'photo-2',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo2.jpg',
            // No coordinates
          ),
        ];

        when(mockPhotoRepository.getPhotosForActivity(activityId))
            .thenAnswer((_) async => photos);

        // Act
        final result = await photoManager.getGeotaggedPhotos(activityId);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.hasLocation, isTrue);
      });
    });

    group('getBestCoverPhoto', () {
      test('returns highest scoring photo from candidates', () async {
        // Arrange
        final activityId = 'activity-1';
        final candidates = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
            curationScore: 0.8,
          ),
          Photo(
            id: 'photo-2',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo2.jpg',
            curationScore: 0.9,
          ),
        ];

        when(mockPhotoRepository.getCoverCandidates(activityId))
            .thenAnswer((_) async => candidates);

        // Act
        final result = await photoManager.getBestCoverPhoto(activityId);

        // Assert
        expect(result, isNotNull);
        expect(result!.curationScore, equals(0.8)); // First in sorted list
      });

      test('returns best available photo when no candidates', () async {
        // Arrange
        final activityId = 'activity-1';
        final allPhotos = [
          Photo(
            id: 'photo-1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo1.jpg',
            curationScore: 0.3,
          ),
          Photo(
            id: 'photo-2',
            activityId: activityId,
            timestamp: Timestamp.now(),
            filePath: '/path/to/photo2.jpg',
            curationScore: 0.5,
          ),
        ];

        when(mockPhotoRepository.getCoverCandidates(activityId))
            .thenAnswer((_) async => []);
        when(mockPhotoRepository.getPhotosForActivity(activityId))
            .thenAnswer((_) async => allPhotos);

        // Act
        final result = await photoManager.getBestCoverPhoto(activityId);

        // Assert
        expect(result, isNotNull);
        expect(result!.curationScore, equals(0.5)); // Highest score
      });

      test('returns null when no photos available', () async {
        // Arrange
        final activityId = 'activity-1';

        when(mockPhotoRepository.getCoverCandidates(activityId))
            .thenAnswer((_) async => []);
        when(mockPhotoRepository.getPhotosForActivity(activityId))
            .thenAnswer((_) async => []);

        // Act
        final result = await photoManager.getBestCoverPhoto(activityId);

        // Assert
        expect(result, isNull);
      });
    });

    group('dispose', () {
      test('disposes camera service', () async {
        when(mockCameraService.dispose()).thenAnswer((_) async {});

        await photoManager.dispose();

        verify(mockCameraService.dispose()).called(1);
      });
    });
  });

  group('PhotoManagerException', () {
    test('creates exception with message', () {
      const message = 'Test error';
      final exception = PhotoManagerException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('PhotoManagerException: $message'));
    });
  });
}