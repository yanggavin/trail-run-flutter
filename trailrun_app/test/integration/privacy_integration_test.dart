import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;

import '../../lib/data/services/privacy_service.dart';
import '../../lib/data/database/database.dart';
import '../../lib/domain/models/activity.dart';
import '../../lib/domain/models/photo.dart';
import '../../lib/domain/models/track_point.dart';
import '../../lib/domain/models/split.dart';
import '../../lib/domain/enums/privacy_level.dart';
import '../../lib/domain/enums/location_source.dart';
import '../../lib/domain/value_objects/coordinates.dart';
import '../../lib/domain/value_objects/timestamp.dart';

void main() {
  group('Privacy Integration Tests', () {
    late TrailRunDatabase database;
    late PrivacyService privacyService;
    late Directory tempDir;

    setUp(() async {
      // Create in-memory database for testing
      database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
      privacyService = PrivacyService(database);
      
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('privacy_integration_test');
    });

    tearDown(() async {
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('End-to-End Privacy Workflow', () {
      test('should create activity, apply privacy settings, and export data', () async {
        // Create test activity with photos
        final activity = Activity(
          id: 'test-activity-1',
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          endTime: DateTime.now().subtract(const Duration(hours: 1)),
          distanceMeters: 5000,
          duration: const Duration(hours: 1),
          elevationGainMeters: 100,
          averagePaceSecondsPerKm: 300,
          title: 'Test Trail Run',
          notes: 'Beautiful trail with great views',
          privacyLevel: PrivacyLevel.public,
          coverPhotoId: null,
          trackPoints: [],
          photos: [],
          splits: [],
        );

        // Insert activity into database
        await database.activityDao.insertActivity(activity);

        // Create test track points
        final trackPoints = List.generate(10, (index) {
          return TrackPoint(
            id: 'tp-$index',
            activityId: activity.id,
            timestamp: Timestamp.fromMilliseconds(
              activity.startTime.millisecondsSinceEpoch + (index * 60000),
            ),
            coordinates: Coordinates(
              latitude: 37.7749 + (index * 0.001),
              longitude: -122.4194 + (index * 0.001),
              elevation: 100.0 + (index * 5),
            ),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: index,
          );
        });

        for (final trackPoint in trackPoints) {
          await database.trackPointDao.insertTrackPoint(trackPoint);
        }

        // Create test photos with files
        final photos = <Photo>[];
        for (int i = 0; i < 3; i++) {
          final photoPath = path.join(tempDir.path, 'photo_$i.jpg');
          final thumbnailPath = path.join(tempDir.path, 'photo_${i}_thumb.jpg');
          
          // Create test image files
          final jpegHeader = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
          ]);
          await File(photoPath).writeAsBytes(jpegHeader);
          await File(thumbnailPath).writeAsBytes(jpegHeader);

          final photo = Photo(
            id: 'photo-$i',
            activityId: activity.id,
            timestamp: Timestamp.fromMilliseconds(
              activity.startTime.millisecondsSinceEpoch + (i * 300000),
            ),
            coordinates: Coordinates(
              latitude: 37.7749 + (i * 0.002),
              longitude: -122.4194 + (i * 0.002),
            ),
            filePath: photoPath,
            thumbnailPath: thumbnailPath,
            hasExifData: true,
            curationScore: 0.8,
          );

          photos.add(photo);
          await database.photoDao.insertPhoto(photo);
        }

        // Create test splits
        final splits = List.generate(5, (index) {
          return Split(
            id: 'split-$index',
            activityId: activity.id,
            splitNumber: index + 1,
            distanceMeters: 1000,
            duration: const Duration(minutes: 5),
            paceSecondsPerKm: 300,
            elevationGainMeters: 20,
            elevationLossMeters: 10,
          );
        });

        for (final split in splits) {
          await database.splitDao.insertSplit(split);
        }

        // Apply privacy settings
        const privacySettings = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
          stripExifData: true,
          shareLocation: false,
          sharePhotos: true,
          shareStats: true,
        );

        await privacyService.applyPrivacySettings(activity.id, privacySettings);

        // Verify privacy settings were applied
        final updatedActivity = await database.activityDao.getActivity(activity.id);
        expect(updatedActivity?.privacyLevel, equals(PrivacyLevel.private));

        // Verify EXIF data was stripped from photos
        for (final photo in photos) {
          final hasExif = await privacyService.hasExifData(photo.filePath);
          expect(hasExif, isFalse);
        }

        // Export data
        final exportPath = await privacyService.exportUserData();
        expect(await File(exportPath).exists(), isTrue);

        // Verify export contains expected data
        final exportContent = await File(exportPath).readAsString();
        expect(exportContent.contains(activity.id), isTrue);
        expect(exportContent.contains(activity.title), isTrue);
        expect(exportContent.contains('private'), isTrue);

        // Export data with photos
        final exportWithPhotosPath = await privacyService.exportUserDataWithPhotos();
        expect(await File(exportWithPhotosPath).exists(), isTrue);

        // Verify ZIP file is larger (contains photos)
        final exportSize = await File(exportPath).length();
        final exportWithPhotosSize = await File(exportWithPhotosPath).length();
        expect(exportWithPhotosSize, greaterThan(exportSize));
      });

      test('should handle privacy-safe coordinate rounding', () {
        const originalCoords = Coordinates(
          latitude: 37.7749295,
          longitude: -122.4194155,
          elevation: 123.456,
        );

        // Test private level (1km accuracy)
        final privateCoords = PrivacyService.getPrivacySafeCoordinates(
          originalCoords,
          PrivacyLevel.private,
        );
        expect(privateCoords.latitude, equals(37.77));
        expect(privateCoords.longitude, equals(-122.42));
        expect(privateCoords.elevation, equals(123.0));

        // Test friends level (100m accuracy)
        final friendsCoords = PrivacyService.getPrivacySafeCoordinates(
          originalCoords,
          PrivacyLevel.friends,
        );
        expect(friendsCoords.latitude, equals(37.775));
        expect(friendsCoords.longitude, equals(-122.419));
        expect(friendsCoords.elevation, equals(123.0));

        // Test public level (full accuracy)
        final publicCoords = PrivacyService.getPrivacySafeCoordinates(
          originalCoords,
          PrivacyLevel.public,
        );
        expect(publicCoords.latitude, equals(originalCoords.latitude));
        expect(publicCoords.longitude, equals(originalCoords.longitude));
        expect(publicCoords.elevation, equals(originalCoords.elevation));
      });

      test('should delete specific activity data completely', () async {
        // Create test activity with all related data
        final activity = Activity(
          id: 'delete-test-activity',
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          distanceMeters: 3000,
          duration: const Duration(hours: 1),
          elevationGainMeters: 50,
          averagePaceSecondsPerKm: 360,
          title: 'Activity to Delete',
          notes: 'This will be deleted',
          privacyLevel: PrivacyLevel.private,
          coverPhotoId: null,
          trackPoints: [],
          photos: [],
          splits: [],
        );

        await database.activityDao.insertActivity(activity);

        // Add track points
        final trackPoint = TrackPoint(
          id: 'tp-delete-test',
          activityId: activity.id,
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        );
        await database.trackPointDao.insertTrackPoint(trackPoint);

        // Add photo with file
        final photoPath = path.join(tempDir.path, 'delete_test_photo.jpg');
        final jpegHeader = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
          0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
        ]);
        await File(photoPath).writeAsBytes(jpegHeader);

        final photo = Photo(
          id: 'photo-delete-test',
          activityId: activity.id,
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          filePath: photoPath,
          thumbnailPath: null,
          hasExifData: false,
          curationScore: 0.5,
        );
        await database.photoDao.insertPhoto(photo);

        // Add split
        final split = Split(
          id: 'split-delete-test',
          activityId: activity.id,
          splitNumber: 1,
          distanceMeters: 1000,
          duration: const Duration(minutes: 6),
          paceSecondsPerKm: 360,
          elevationGainMeters: 10,
          elevationLossMeters: 5,
        );
        await database.splitDao.insertSplit(split);

        // Verify data exists before deletion
        expect(await database.activityDao.getActivity(activity.id), isNotNull);
        expect(await database.trackPointDao.getTrackPointsForActivity(activity.id), hasLength(1));
        expect(await database.photoDao.getPhotosForActivity(activity.id), hasLength(1));
        expect(await database.splitDao.getSplitsForActivity(activity.id), hasLength(1));
        expect(await File(photoPath).exists(), isTrue);

        // Delete activity data
        await privacyService.deleteActivityData(activity.id);

        // Verify all data was deleted
        expect(await database.activityDao.getActivity(activity.id), isNull);
        expect(await database.trackPointDao.getTrackPointsForActivity(activity.id), isEmpty);
        expect(await database.photoDao.getPhotosForActivity(activity.id), isEmpty);
        expect(await database.splitDao.getSplitsForActivity(activity.id), isEmpty);
        expect(await File(photoPath).exists(), isFalse);
      });

      test('should delete all user data completely', () async {
        // Create multiple activities with data
        final activities = List.generate(3, (index) {
          return Activity(
            id: 'activity-$index',
            startTime: DateTime.now().subtract(Duration(hours: index + 1)),
            endTime: DateTime.now().subtract(Duration(hours: index)),
            distanceMeters: (index + 1) * 1000.0,
            duration: Duration(hours: index + 1),
            elevationGainMeters: (index + 1) * 50.0,
            averagePaceSecondsPerKm: 300.0,
            title: 'Activity $index',
            notes: 'Notes for activity $index',
            privacyLevel: PrivacyLevel.private,
            coverPhotoId: null,
            trackPoints: [],
            photos: [],
            splits: [],
          );
        });

        // Insert activities and related data
        for (final activity in activities) {
          await database.activityDao.insertActivity(activity);

          // Add track point
          final trackPoint = TrackPoint(
            id: 'tp-${activity.id}',
            activityId: activity.id,
            timestamp: Timestamp.now(),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          );
          await database.trackPointDao.insertTrackPoint(trackPoint);

          // Add photo with file
          final photoPath = path.join(tempDir.path, 'photo_${activity.id}.jpg');
          final jpegHeader = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
          ]);
          await File(photoPath).writeAsBytes(jpegHeader);

          final photo = Photo(
            id: 'photo-${activity.id}',
            activityId: activity.id,
            timestamp: Timestamp.now(),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
            filePath: photoPath,
            thumbnailPath: null,
            hasExifData: false,
            curationScore: 0.5,
          );
          await database.photoDao.insertPhoto(photo);
        }

        // Verify data exists
        final allActivities = await database.activityDao.getAllActivities();
        final allTrackPoints = await database.trackPointDao.getAllTrackPoints();
        final allPhotos = await database.photoDao.getAllPhotos();

        expect(allActivities, hasLength(3));
        expect(allTrackPoints, hasLength(3));
        expect(allPhotos, hasLength(3));

        // Delete all user data
        await privacyService.deleteAllUserData();

        // Verify all data was deleted
        final remainingActivities = await database.activityDao.getAllActivities();
        final remainingTrackPoints = await database.trackPointDao.getAllTrackPoints();
        final remainingPhotos = await database.photoDao.getAllPhotos();

        expect(remainingActivities, isEmpty);
        expect(remainingTrackPoints, isEmpty);
        expect(remainingPhotos, isEmpty);

        // Verify photo files were deleted
        for (final activity in activities) {
          final photoPath = path.join(tempDir.path, 'photo_${activity.id}.jpg');
          expect(await File(photoPath).exists(), isFalse);
        }
      });

      test('should handle EXIF data operations on real photos', () async {
        // Create a more realistic JPEG file with some metadata
        final photoPath = path.join(tempDir.path, 'test_photo_with_metadata.jpg');
        
        // Create a minimal JPEG with EXIF-like structure
        final jpegWithExif = Uint8List.fromList([
          // JPEG SOI
          0xFF, 0xD8,
          // APP1 marker (EXIF)
          0xFF, 0xE1, 0x00, 0x16,
          // EXIF header
          0x45, 0x78, 0x69, 0x66, 0x00, 0x00,
          // Some dummy EXIF data
          0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00,
          // JPEG EOI
          0xFF, 0xD9
        ]);
        
        await File(photoPath).writeAsBytes(jpegWithExif);

        // Check if photo has EXIF data (should return false for our simple test)
        final hasExifBefore = await privacyService.hasExifData(photoPath);
        
        // Strip EXIF data
        await privacyService.stripPhotoExifData(photoPath);
        
        // Verify file still exists and is readable
        expect(await File(photoPath).exists(), isTrue);
        final strippedBytes = await File(photoPath).readAsBytes();
        expect(strippedBytes.isNotEmpty, isTrue);
        
        // Check EXIF data after stripping
        final hasExifAfter = await privacyService.hasExifData(photoPath);
        expect(hasExifAfter, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle database errors gracefully', () async {
        // Close database to simulate error
        await database.close();

        expect(
          () => privacyService.deleteAllUserData(),
          throwsA(isA<PrivacyServiceException>()),
        );
      });

      test('should handle file system errors gracefully', () async {
        // Try to strip EXIF from non-existent file
        expect(
          () => privacyService.stripPhotoExifData('/non/existent/path.jpg'),
          throwsA(isA<PrivacyServiceException>()),
        );
      });

      test('should handle export errors gracefully', () async {
        // Create database with no write permissions (simulated)
        expect(
          () => privacyService.exportUserData(),
          throwsA(isA<PrivacyServiceException>()),
        );
      });
    });
  });
}