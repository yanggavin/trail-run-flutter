import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:trailrun_app/data/database/database.dart';
import 'package:trailrun_app/data/database/daos/photo_dao.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';

void main() {
  late TrailRunDatabase database;
  late PhotoDao photoDao;

  setUp(() {
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
    photoDao = database.photoDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('PhotoDao', () {
    test('should create and retrieve photo', () async {
      // Arrange
      final photo = Photo(
        id: 'photo-1',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 100.0,
        ),
        filePath: '/path/to/photo.jpg',
        thumbnailPath: '/path/to/thumbnail.jpg',
        hasExifData: true,
        curationScore: 0.8,
        caption: 'Beautiful sunset',
      );

      final entity = photoDao.toEntity(photo);

      // Act
      await photoDao.createPhoto(entity);
      final retrieved = await photoDao.getPhotoById('photo-1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('photo-1'));
      expect(retrieved.activityId, equals('activity-1'));
      expect(retrieved.latitude, equals(37.7749));
      expect(retrieved.longitude, equals(-122.4194));
      expect(retrieved.elevation, equals(100.0));
      expect(retrieved.filePath, equals('/path/to/photo.jpg'));
      expect(retrieved.thumbnailPath, equals('/path/to/thumbnail.jpg'));
      expect(retrieved.hasExifData, isTrue);
      expect(retrieved.curationScore, equals(0.8));
      expect(retrieved.caption, equals('Beautiful sunset'));
    });

    test('should create photo without location data', () async {
      // Arrange
      final photo = Photo(
        id: 'photo-no-location',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        filePath: '/path/to/photo.jpg',
        hasExifData: false,
        curationScore: 0.5,
      );

      final entity = photoDao.toEntity(photo);

      // Act
      await photoDao.createPhoto(entity);
      final retrieved = await photoDao.getPhotoById('photo-no-location');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.latitude, isNull);
      expect(retrieved.longitude, isNull);
      expect(retrieved.elevation, isNull);
      expect(retrieved.hasExifData, isFalse);
    });

    test('should get photos for activity ordered by timestamp', () async {
      // Arrange
      final now = DateTime.now();
      final photos = [
        Photo(
          id: 'photo-3',
          activityId: 'activity-1',
          timestamp: Timestamp(now.add(const Duration(minutes: 30))),
          filePath: '/path/to/photo3.jpg',
        ),
        Photo(
          id: 'photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp(now),
          filePath: '/path/to/photo1.jpg',
        ),
        Photo(
          id: 'photo-2',
          activityId: 'activity-1',
          timestamp: Timestamp(now.add(const Duration(minutes: 15))),
          filePath: '/path/to/photo2.jpg',
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final retrieved = await photoDao.getPhotosForActivity('activity-1');

      // Assert
      expect(retrieved.length, equals(3));
      expect(retrieved[0].id, equals('photo-1')); // Earliest timestamp first
      expect(retrieved[1].id, equals('photo-2'));
      expect(retrieved[2].id, equals('photo-3'));
    });

    test('should get geotagged photos only', () async {
      // Arrange
      final photos = [
        Photo(
          id: 'geotagged-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          filePath: '/path/to/geotagged.jpg',
        ),
        Photo(
          id: 'non-geotagged-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/non-geotagged.jpg',
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final geotaggedPhotos = await photoDao.getGeotaggedPhotos('activity-1');

      // Assert
      expect(geotaggedPhotos.length, equals(1));
      expect(geotaggedPhotos.first.id, equals('geotagged-photo'));
    });

    test('should get cover candidate photos', () async {
      // Arrange
      final photos = [
        Photo(
          id: 'high-score-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/high-score.jpg',
          curationScore: 0.9,
        ),
        Photo(
          id: 'medium-score-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/medium-score.jpg',
          curationScore: 0.6,
        ),
        Photo(
          id: 'low-score-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/low-score.jpg',
          curationScore: 0.3,
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final coverCandidates = await photoDao.getCoverCandidatePhotos(
        activityId: 'activity-1',
        minCurationScore: 0.7,
      );

      // Assert
      expect(coverCandidates.length, equals(1));
      expect(coverCandidates.first.id, equals('high-score-photo'));
      expect(coverCandidates.first.curationScore, equals(0.9));
    });

    test('should get photos in time range', () async {
      // Arrange
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      final photos = [
        Photo(
          id: 'old-photo',
          activityId: 'activity-1',
          timestamp: Timestamp(twoHoursAgo),
          filePath: '/path/to/old.jpg',
        ),
        Photo(
          id: 'in-range-photo',
          activityId: 'activity-1',
          timestamp: Timestamp(thirtyMinutesAgo),
          filePath: '/path/to/in-range.jpg',
        ),
        Photo(
          id: 'recent-photo',
          activityId: 'activity-1',
          timestamp: Timestamp(now),
          filePath: '/path/to/recent.jpg',
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final photosInRange = await photoDao.getPhotosInTimeRange(
        activityId: 'activity-1',
        startTime: oneHourAgo,
        endTime: now,
      );

      // Assert
      expect(photosInRange.length, equals(2));
      expect(photosInRange.any((p) => p.id == 'in-range-photo'), isTrue);
      expect(photosInRange.any((p) => p.id == 'recent-photo'), isTrue);
      expect(photosInRange.any((p) => p.id == 'old-photo'), isFalse);
    });

    test('should search photos by caption', () async {
      // Arrange
      final photos = [
        Photo(
          id: 'sunset-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/sunset.jpg',
          caption: 'Beautiful sunset over the mountains',
        ),
        Photo(
          id: 'sunrise-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/sunrise.jpg',
          caption: 'Amazing sunrise at the beach',
        ),
        Photo(
          id: 'trail-photo',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/trail.jpg',
          caption: 'Rocky trail through the forest',
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final sunPhotos = await photoDao.searchPhotosByCaption(
        activityId: 'activity-1',
        query: 'sun',
      );
      final mountainPhotos = await photoDao.searchPhotosByCaption(
        activityId: 'activity-1',
        query: 'mountain',
      );

      // Assert
      expect(sunPhotos.length, equals(2)); // sunset and sunrise
      expect(mountainPhotos.length, equals(1)); // sunset only
    });

    test('should update photo curation score', () async {
      // Arrange
      final photo = Photo(
        id: 'update-score-photo',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        filePath: '/path/to/photo.jpg',
        curationScore: 0.5,
      );

      await photoDao.createPhoto(photoDao.toEntity(photo));

      // Act
      await photoDao.updatePhotoCurationScore('update-score-photo', 0.9);

      // Assert
      final retrieved = await photoDao.getPhotoById('update-score-photo');
      expect(retrieved!.curationScore, equals(0.9));
    });

    test('should update photo caption', () async {
      // Arrange
      final photo = Photo(
        id: 'update-caption-photo',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        filePath: '/path/to/photo.jpg',
        caption: 'Original caption',
      );

      await photoDao.createPhoto(photoDao.toEntity(photo));

      // Act
      await photoDao.updatePhotoCaption('update-caption-photo', 'Updated caption');

      // Assert
      final retrieved = await photoDao.getPhotoById('update-caption-photo');
      expect(retrieved!.caption, equals('Updated caption'));
    });

    test('should create photos in batch', () async {
      // Arrange
      final photos = List.generate(5, (index) => Photo(
        id: 'batch-photo-$index',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        filePath: '/path/to/photo$index.jpg',
        curationScore: index * 0.2,
      ));

      final entities = photos.map(photoDao.toEntity).toList();

      // Act
      await photoDao.createPhotosBatch(entities);

      // Assert
      final retrieved = await photoDao.getPhotosForActivity('activity-1');
      expect(retrieved.length, equals(5));
    });

    test('should get photos count', () async {
      // Arrange
      final photos = List.generate(3, (index) => Photo(
        id: 'count-photo-$index',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        filePath: '/path/to/photo$index.jpg',
      ));

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      final count = await photoDao.getPhotosCount('activity-1');

      // Assert
      expect(count, equals(3));
    });

    test('should delete photos for activity', () async {
      // Arrange
      final photos = [
        Photo(
          id: 'delete-photo-1',
          activityId: 'activity-1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/delete1.jpg',
        ),
        Photo(
          id: 'keep-photo-1',
          activityId: 'activity-2',
          timestamp: Timestamp.now(),
          filePath: '/path/to/keep1.jpg',
        ),
      ];

      for (final photo in photos) {
        await photoDao.createPhoto(photoDao.toEntity(photo));
      }

      // Act
      await photoDao.deletePhotosForActivity('activity-1');

      // Assert
      final activity1Photos = await photoDao.getPhotosForActivity('activity-1');
      final activity2Photos = await photoDao.getPhotosForActivity('activity-2');
      
      expect(activity1Photos.length, equals(0));
      expect(activity2Photos.length, equals(1));
    });

    test('should convert between domain and entity correctly', () async {
      // Arrange
      final domainPhoto = Photo(
        id: 'conversion-test',
        activityId: 'activity-1',
        timestamp: Timestamp.now(),
        coordinates: const Coordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          elevation: 150.5,
        ),
        filePath: '/path/to/photo.jpg',
        thumbnailPath: '/path/to/thumbnail.jpg',
        hasExifData: true,
        curationScore: 0.75,
        caption: 'Test caption',
      );

      // Act
      final entity = photoDao.toEntity(domainPhoto);
      final convertedBack = photoDao.fromEntity(entity);

      // Assert
      expect(convertedBack.id, equals(domainPhoto.id));
      expect(convertedBack.activityId, equals(domainPhoto.activityId));
      expect(convertedBack.coordinates?.latitude, equals(domainPhoto.coordinates?.latitude));
      expect(convertedBack.coordinates?.longitude, equals(domainPhoto.coordinates?.longitude));
      expect(convertedBack.coordinates?.elevation, equals(domainPhoto.coordinates?.elevation));
      expect(convertedBack.filePath, equals(domainPhoto.filePath));
      expect(convertedBack.thumbnailPath, equals(domainPhoto.thumbnailPath));
      expect(convertedBack.hasExifData, equals(domainPhoto.hasExifData));
      expect(convertedBack.curationScore, equals(domainPhoto.curationScore));
      expect(convertedBack.caption, equals(domainPhoto.caption));
    });
  });
}