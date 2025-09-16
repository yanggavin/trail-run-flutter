import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/data/repositories/photo_repository_impl.dart';
import '../../../lib/data/database/daos/photo_dao.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/domain/models/photo.dart';
import '../../../lib/domain/value_objects/coordinates.dart';
import '../../../lib/domain/value_objects/timestamp.dart';

@GenerateMocks([PhotoDao])
import 'photo_repository_impl_test.mocks.dart';

void main() {
  group('PhotoRepositoryImpl', () {
    late PhotoRepositoryImpl repository;
    late MockPhotoDao mockPhotoDao;

    setUp(() {
      mockPhotoDao = MockPhotoDao();
      repository = PhotoRepositoryImpl(photoDao: mockPhotoDao);
    });

    group('createPhoto', () {
      test('creates photo successfully', () async {
        // Arrange
        final photo = Photo(
          id: 'photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
        );
        final entity = PhotoEntity(
          id: photo.id,
          activityId: photo.activityId,
          timestamp: photo.timestamp.millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: photo.filePath,
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.0,
          caption: null,
        );

        when(mockPhotoDao.toEntity(photo)).thenReturn(entity);
        when(mockPhotoDao.createPhoto(entity)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.createPhoto(photo);

        // Assert
        expect(result, equals(photo));
        verify(mockPhotoDao.toEntity(photo)).called(1);
        verify(mockPhotoDao.createPhoto(entity)).called(1);
      });

      test('handles creation failure', () async {
        // Arrange
        final photo = Photo(
          id: 'photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
        );
        final entity = PhotoEntity(
          id: photo.id,
          activityId: photo.activityId,
          timestamp: photo.timestamp.millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: photo.filePath,
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.0,
          caption: null,
        );

        when(mockPhotoDao.toEntity(photo)).thenReturn(entity);
        when(mockPhotoDao.createPhoto(entity)).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createPhoto(photo),
          throwsA(isA<PhotoRepositoryException>()),
        );
      });
    });

    group('updatePhoto', () {
      test('updates photo successfully', () async {
        // Arrange
        final photo = Photo(
          id: 'photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
          caption: 'Updated caption',
        );
        final entity = PhotoEntity(
          id: photo.id,
          activityId: photo.activityId,
          timestamp: photo.timestamp.millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: photo.filePath,
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.0,
          caption: photo.caption,
        );

        when(mockPhotoDao.toEntity(photo)).thenReturn(entity);
        when(mockPhotoDao.updatePhoto(entity)).thenAnswer((_) async => true);

        // Act
        final result = await repository.updatePhoto(photo);

        // Assert
        expect(result, equals(photo));
        verify(mockPhotoDao.toEntity(photo)).called(1);
        verify(mockPhotoDao.updatePhoto(entity)).called(1);
      });

      test('throws exception when photo not found', () async {
        // Arrange
        final photo = Photo(
          id: 'photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
        );
        final entity = PhotoEntity(
          id: photo.id,
          activityId: photo.activityId,
          timestamp: photo.timestamp.millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: photo.filePath,
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.0,
          caption: null,
        );

        when(mockPhotoDao.toEntity(photo)).thenReturn(entity);
        when(mockPhotoDao.updatePhoto(entity)).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => repository.updatePhoto(photo),
          throwsA(isA<PhotoRepositoryException>()),
        );
      });
    });

    group('getPhoto', () {
      test('returns photo when found', () async {
        // Arrange
        final photoId = 'photo-1';
        final entity = PhotoEntity(
          id: photoId,
          activityId: 'activity-1',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: '/path/to/photo.jpg',
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.0,
          caption: null,
        );
        final photo = Photo(
          id: photoId,
          activityId: 'activity-1',
          timestamp: Timestamp.fromMilliseconds(entity.timestamp),
          filePath: '/path/to/photo.jpg',
        );

        when(mockPhotoDao.getPhotoById(photoId)).thenAnswer((_) async => entity);
        when(mockPhotoDao.fromEntity(entity)).thenReturn(photo);

        // Act
        final result = await repository.getPhoto(photoId);

        // Assert
        expect(result, equals(photo));
        verify(mockPhotoDao.getPhotoById(photoId)).called(1);
        verify(mockPhotoDao.fromEntity(entity)).called(1);
      });

      test('returns null when not found', () async {
        // Arrange
        final photoId = 'photo-1';

        when(mockPhotoDao.getPhotoById(photoId)).thenAnswer((_) async => null);

        // Act
        final result = await repository.getPhoto(photoId);

        // Assert
        expect(result, isNull);
        verify(mockPhotoDao.getPhotoById(photoId)).called(1);
      });
    });

    group('getPhotosForActivity', () {
      test('returns photos for activity', () async {
        // Arrange
        final activityId = 'activity-1';
        final entities = [
          PhotoEntity(
            id: 'photo-1',
            activityId: activityId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            latitude: null,
            longitude: null,
            elevation: null,
            filePath: '/path/to/photo1.jpg',
            thumbnailPath: null,
            hasExifData: false,
            curationScore: 0.0,
            caption: null,
          ),
          PhotoEntity(
            id: 'photo-2',
            activityId: activityId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            latitude: null,
            longitude: null,
            elevation: null,
            filePath: '/path/to/photo2.jpg',
            thumbnailPath: null,
            hasExifData: false,
            curationScore: 0.0,
            caption: null,
          ),
        ];
        final photos = entities.map((e) => Photo(
          id: e.id,
          activityId: e.activityId,
          timestamp: Timestamp.fromMilliseconds(e.timestamp),
          filePath: e.filePath,
        )).toList();

        when(mockPhotoDao.getPhotosForActivity(activityId))
            .thenAnswer((_) async => entities);
        when(mockPhotoDao.fromEntity(entities[0])).thenReturn(photos[0]);
        when(mockPhotoDao.fromEntity(entities[1])).thenReturn(photos[1]);

        // Act
        final result = await repository.getPhotosForActivity(activityId);

        // Assert
        expect(result, hasLength(2));
        expect(result, equals(photos));
        verify(mockPhotoDao.getPhotosForActivity(activityId)).called(1);
      });
    });

    group('getCoverCandidates', () {
      test('returns cover candidates with default min score', () async {
        // Arrange
        final activityId = 'activity-1';
        final entities = [
          PhotoEntity(
            id: 'photo-1',
            activityId: activityId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            latitude: null,
            longitude: null,
            elevation: null,
            filePath: '/path/to/photo1.jpg',
            thumbnailPath: null,
            hasExifData: false,
            curationScore: 0.8,
            caption: null,
          ),
        ];
        final photos = entities.map((e) => Photo(
          id: e.id,
          activityId: e.activityId,
          timestamp: Timestamp.fromMilliseconds(e.timestamp),
          filePath: e.filePath,
          curationScore: e.curationScore,
        )).toList();

        when(mockPhotoDao.getCoverCandidatePhotos(
          activityId: activityId,
          minCurationScore: 0.7,
        )).thenAnswer((_) async => entities);
        when(mockPhotoDao.fromEntity(entities[0])).thenReturn(photos[0]);

        // Act
        final result = await repository.getCoverCandidates(activityId);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.curationScore, equals(0.8));
        verify(mockPhotoDao.getCoverCandidatePhotos(
          activityId: activityId,
          minCurationScore: 0.7,
        )).called(1);
      });

      test('returns cover candidates with custom min score', () async {
        // Arrange
        final activityId = 'activity-1';
        final minScore = 0.9;

        when(mockPhotoDao.getCoverCandidatePhotos(
          activityId: activityId,
          minCurationScore: minScore,
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.getCoverCandidates(activityId, minScore: minScore);

        // Assert
        expect(result, isEmpty);
        verify(mockPhotoDao.getCoverCandidatePhotos(
          activityId: activityId,
          minCurationScore: minScore,
        )).called(1);
      });
    });

    group('deletePhoto', () {
      test('deletes photo and files successfully', () async {
        // Arrange
        final photoId = 'photo-1';
        final photo = Photo(
          id: photoId,
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo.jpg',
          thumbnailPath: '/path/to/thumb.jpg',
        );

        // Mock the getPhoto call in deletePhoto
        when(mockPhotoDao.getPhotoById(photoId)).thenAnswer((_) async => PhotoEntity(
          id: photo.id,
          activityId: photo.activityId,
          timestamp: photo.timestamp.millisecondsSinceEpoch,
          latitude: null,
          longitude: null,
          elevation: null,
          filePath: photo.filePath,
          thumbnailPath: photo.thumbnailPath,
          hasExifData: false,
          curationScore: 0.0,
          caption: null,
        ));
        when(mockPhotoDao.fromEntity(any)).thenReturn(photo);
        when(mockPhotoDao.deletePhoto(photoId)).thenAnswer((_) async => 1);

        // Act
        await repository.deletePhoto(photoId);

        // Assert
        verify(mockPhotoDao.deletePhoto(photoId)).called(1);
      });

      test('throws exception when photo not found', () async {
        // Arrange
        final photoId = 'photo-1';

        when(mockPhotoDao.getPhotoById(photoId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.deletePhoto(photoId),
          throwsA(isA<PhotoRepositoryException>()),
        );
      });
    });

    group('watchPhotosForActivity', () {
      test('returns stream of photos', () {
        // Arrange
        final activityId = 'activity-1';
        final entities = [
          PhotoEntity(
            id: 'photo-1',
            activityId: activityId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            latitude: null,
            longitude: null,
            elevation: null,
            filePath: '/path/to/photo1.jpg',
            thumbnailPath: null,
            hasExifData: false,
            curationScore: 0.0,
            caption: null,
          ),
        ];
        final photos = entities.map((e) => Photo(
          id: e.id,
          activityId: e.activityId,
          timestamp: Timestamp.fromMilliseconds(e.timestamp),
          filePath: e.filePath,
        )).toList();

        when(mockPhotoDao.watchPhotosForActivity(activityId))
            .thenAnswer((_) => Stream.value(entities));
        when(mockPhotoDao.fromEntity(entities[0])).thenReturn(photos[0]);

        // Act
        final stream = repository.watchPhotosForActivity(activityId);

        // Assert
        expect(stream, emits(photos));
      });
    });

    group('updateCurationScore', () {
      test('updates curation score successfully', () async {
        // Arrange
        final photoId = 'photo-1';
        final score = 0.8;

        when(mockPhotoDao.updatePhotoCurationScore(photoId, score))
            .thenAnswer((_) async => 1);

        // Act
        await repository.updateCurationScore(photoId, score);

        // Assert
        verify(mockPhotoDao.updatePhotoCurationScore(photoId, score)).called(1);
      });
    });
  });

  group('PhotoRepositoryException', () {
    test('creates exception with message', () {
      const message = 'Test error';
      final exception = PhotoRepositoryException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('PhotoRepositoryException: $message'));
    });
  });
}