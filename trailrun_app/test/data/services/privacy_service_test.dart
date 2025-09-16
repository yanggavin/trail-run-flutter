import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;

import '../../../lib/data/services/privacy_service.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/domain/models/activity.dart';
import '../../../lib/domain/models/photo.dart';
import '../../../lib/domain/models/track_point.dart';
import '../../../lib/domain/models/split.dart';
import '../../../lib/domain/enums/privacy_level.dart';
import '../../../lib/domain/enums/location_source.dart';
import '../../../lib/domain/value_objects/coordinates.dart';
import '../../../lib/domain/value_objects/timestamp.dart';

@GenerateMocks([TrailRunDatabase, ActivityDao, PhotoDao, TrackPointDao, SplitDao, SyncQueueDao])
import 'privacy_service_test.mocks.dart';

void main() {
  group('PrivacyService', () {
    late MockTrailRunDatabase mockDatabase;
    late MockActivityDao mockActivityDao;
    late MockPhotoDao mockPhotoDao;
    late MockTrackPointDao mockTrackPointDao;
    late MockSplitDao mockSplitDao;
    late MockSyncQueueDao mockSyncQueueDao;
    late PrivacyService privacyService;
    late Directory tempDir;

    setUp(() async {
      mockDatabase = MockTrailRunDatabase();
      mockActivityDao = MockActivityDao();
      mockPhotoDao = MockPhotoDao();
      mockTrackPointDao = MockTrackPointDao();
      mockSplitDao = MockSplitDao();
      mockSyncQueueDao = MockSyncQueueDao();

      when(mockDatabase.activityDao).thenReturn(mockActivityDao);
      when(mockDatabase.photoDao).thenReturn(mockPhotoDao);
      when(mockDatabase.trackPointDao).thenReturn(mockTrackPointDao);
      when(mockDatabase.splitDao).thenReturn(mockSplitDao);
      when(mockDatabase.syncQueueDao).thenReturn(mockSyncQueueDao);

      privacyService = PrivacyService(mockDatabase);

      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('privacy_service_test');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('EXIF Data Stripping', () {
      test('should strip EXIF data from photo file', () async {
        // Create a test image file with mock EXIF data
        final testImagePath = path.join(tempDir.path, 'test_image.jpg');
        final testImageFile = File(testImagePath);
        
        // Create a simple JPEG file (minimal valid JPEG)
        final jpegHeader = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
          0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
        ]);
        await testImageFile.writeAsBytes(jpegHeader);

        // Strip EXIF data
        await privacyService.stripPhotoExifData(testImagePath);

        // Verify file still exists and is readable
        expect(await testImageFile.exists(), isTrue);
        final strippedBytes = await testImageFile.readAsBytes();
        expect(strippedBytes.isNotEmpty, isTrue);
      });

      test('should throw exception for non-existent file', () async {
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        expect(
          () => privacyService.stripPhotoExifData(nonExistentPath),
          throwsA(isA<PrivacyServiceException>()),
        );
      });

      test('should strip EXIF data from multiple photos', () async {
        // Create multiple test image files
        final imagePaths = <String>[];
        for (int i = 0; i < 3; i++) {
          final imagePath = path.join(tempDir.path, 'test_image_$i.jpg');
          final imageFile = File(imagePath);
          
          final jpegHeader = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
          ]);
          await imageFile.writeAsBytes(jpegHeader);
          imagePaths.add(imagePath);
        }

        // Strip EXIF data from all photos
        await privacyService.stripMultiplePhotosExifData(imagePaths);

        // Verify all files still exist
        for (final imagePath in imagePaths) {
          expect(await File(imagePath).exists(), isTrue);
        }
      });

      test('should check if photo has EXIF data', () async {
        final testImagePath = path.join(tempDir.path, 'test_image.jpg');
        final testImageFile = File(testImagePath);
        
        final jpegHeader = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
          0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9
        ]);
        await testImageFile.writeAsBytes(jpegHeader);

        final hasExif = await privacyService.hasExifData(testImagePath);
        expect(hasExif, isFalse); // Simple JPEG without EXIF
      });

      test('should return false for non-existent file when checking EXIF', () async {
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');
        final hasExif = await privacyService.hasExifData(nonExistentPath);
        expect(hasExif, isFalse);
      });
    });

    group('Data Deletion', () {
      test('should delete all user data', () async {
        // Setup mock transaction
        when(mockDatabase.transaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function();
          return await callback();
        });

        when(mockSyncQueueDao.deleteAll()).thenAnswer((_) async => 0);
        when(mockSplitDao.deleteAll()).thenAnswer((_) async => 0);
        when(mockPhotoDao.deleteAll()).thenAnswer((_) async => 0);
        when(mockTrackPointDao.deleteAll()).thenAnswer((_) async => 0);
        when(mockActivityDao.deleteAll()).thenAnswer((_) async => 0);

        await privacyService.deleteAllUserData();

        verify(mockSyncQueueDao.deleteAll()).called(1);
        verify(mockSplitDao.deleteAll()).called(1);
        verify(mockPhotoDao.deleteAll()).called(1);
        verify(mockTrackPointDao.deleteAll()).called(1);
        verify(mockActivityDao.deleteAll()).called(1);
      });

      test('should delete specific activity data', () async {
        const activityId = 'test-activity-id';
        final testPhotos = [
          Photo(
            id: 'photo1',
            activityId: activityId,
            timestamp: Timestamp.now(),
            coordinates: const Coordinates(latitude: 0, longitude: 0),
            filePath: path.join(tempDir.path, 'photo1.jpg'),
            thumbnailPath: path.join(tempDir.path, 'photo1_thumb.jpg'),
            hasExifData: true,
            curationScore: 0.5,
          ),
        ];

        // Create test photo files
        for (final photo in testPhotos) {
          await File(photo.filePath).create();
          if (photo.thumbnailPath != null) {
            await File(photo.thumbnailPath!).create();
          }
        }

        when(mockDatabase.transaction(any)).thenAnswer((invocation) async {
          final callback = invocation.positionalArguments[0] as Function();
          return await callback();
        });

        when(mockPhotoDao.getPhotosForActivity(activityId))
            .thenAnswer((_) async => testPhotos);
        when(mockSyncQueueDao.deleteByEntityId(activityId))
            .thenAnswer((_) async => 0);
        when(mockSplitDao.deleteByActivityId(activityId))
            .thenAnswer((_) async => 0);
        when(mockPhotoDao.deleteByActivityId(activityId))
            .thenAnswer((_) async => 0);
        when(mockTrackPointDao.deleteByActivityId(activityId))
            .thenAnswer((_) async => 0);
        when(mockActivityDao.deleteActivity(activityId))
            .thenAnswer((_) async => 0);

        await privacyService.deleteActivityData(activityId);

        verify(mockPhotoDao.getPhotosForActivity(activityId)).called(1);
        verify(mockSyncQueueDao.deleteByEntityId(activityId)).called(1);
        verify(mockSplitDao.deleteByActivityId(activityId)).called(1);
        verify(mockPhotoDao.deleteByActivityId(activityId)).called(1);
        verify(mockTrackPointDao.deleteByActivityId(activityId)).called(1);
        verify(mockActivityDao.deleteActivity(activityId)).called(1);
      });
    });

    group('Data Export', () {
      test('should export user data as JSON', () async {
        final testActivities = [
          Activity(
            id: 'activity1',
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(hours: 1)),
            distanceMeters: 5000,
            duration: const Duration(hours: 1),
            elevationGainMeters: 100,
            averagePaceSecondsPerKm: 300,
            title: 'Test Run',
            notes: 'Test notes',
            privacyLevel: PrivacyLevel.private,
            coverPhotoId: null,
            trackPoints: [],
            photos: [],
            splits: [],
          ),
        ];

        final testTrackPoints = [
          TrackPoint(
            id: 'tp1',
            activityId: 'activity1',
            timestamp: Timestamp.now(),
            coordinates: const Coordinates(latitude: 0, longitude: 0),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 1,
          ),
        ];

        final testPhotos = [
          Photo(
            id: 'photo1',
            activityId: 'activity1',
            timestamp: Timestamp.now(),
            coordinates: const Coordinates(latitude: 0, longitude: 0),
            filePath: '/test/photo1.jpg',
            thumbnailPath: '/test/photo1_thumb.jpg',
            hasExifData: true,
            curationScore: 0.5,
          ),
        ];

        final testSplits = [
          Split(
            id: 'split1',
            activityId: 'activity1',
            splitNumber: 1,
            distanceMeters: 1000,
            duration: const Duration(minutes: 5),
            paceSecondsPerKm: 300,
            elevationGainMeters: 10,
            elevationLossMeters: 5,
          ),
        ];

        when(mockActivityDao.getAllActivities())
            .thenAnswer((_) async => testActivities);
        when(mockTrackPointDao.getAllTrackPoints())
            .thenAnswer((_) async => testTrackPoints);
        when(mockPhotoDao.getAllPhotos())
            .thenAnswer((_) async => testPhotos);
        when(mockSplitDao.getAllSplits())
            .thenAnswer((_) async => testSplits);

        final exportPath = await privacyService.exportUserData();

        expect(await File(exportPath).exists(), isTrue);
        
        // Verify the exported JSON contains expected data
        final exportContent = await File(exportPath).readAsString();
        expect(exportContent.contains('activity1'), isTrue);
        expect(exportContent.contains('Test Run'), isTrue);
      });
    });

    group('Privacy Settings Application', () {
      test('should apply privacy settings to activity', () async {
        const activityId = 'test-activity-id';
        final testActivity = Activity(
          id: activityId,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          distanceMeters: 5000,
          duration: const Duration(hours: 1),
          elevationGainMeters: 100,
          averagePaceSecondsPerKm: 300,
          title: 'Test Run',
          notes: 'Test notes',
          privacyLevel: PrivacyLevel.public,
          coverPhotoId: null,
          trackPoints: [],
          photos: [],
          splits: [],
        );

        final privacySettings = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
          stripExifData: true,
        );

        when(mockActivityDao.getActivity(activityId))
            .thenAnswer((_) async => testActivity);
        when(mockActivityDao.updateActivity(any))
            .thenAnswer((_) async => 1);
        when(mockPhotoDao.getPhotosForActivity(activityId))
            .thenAnswer((_) async => []);

        await privacyService.applyPrivacySettings(activityId, privacySettings);

        verify(mockActivityDao.getActivity(activityId)).called(1);
        verify(mockActivityDao.updateActivity(any)).called(1);
      });

      test('should throw exception for non-existent activity', () async {
        const activityId = 'non-existent-activity';
        final privacySettings = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
        );

        when(mockActivityDao.getActivity(activityId))
            .thenAnswer((_) async => null);

        expect(
          () => privacyService.applyPrivacySettings(activityId, privacySettings),
          throwsA(isA<PrivacyServiceException>()),
        );
      });
    });

    group('Privacy-Safe Coordinates', () {
      test('should round coordinates for private level', () {
        const original = Coordinates(
          latitude: 37.7749295,
          longitude: -122.4194155,
          elevation: 123.456,
        );

        final privateSafe = PrivacyService.getPrivacySafeCoordinates(
          original,
          PrivacyLevel.private,
        );

        expect(privateSafe.latitude, equals(37.77));
        expect(privateSafe.longitude, equals(-122.42));
        expect(privateSafe.elevation, equals(123.0));
      });

      test('should round coordinates for friends level', () {
        const original = Coordinates(
          latitude: 37.7749295,
          longitude: -122.4194155,
          elevation: 123.456,
        );

        final friendsSafe = PrivacyService.getPrivacySafeCoordinates(
          original,
          PrivacyLevel.friends,
        );

        expect(friendsSafe.latitude, equals(37.775));
        expect(friendsSafe.longitude, equals(-122.419));
        expect(friendsSafe.elevation, equals(123.0));
      });

      test('should keep full accuracy for public level', () {
        const original = Coordinates(
          latitude: 37.7749295,
          longitude: -122.4194155,
          elevation: 123.456,
        );

        final publicSafe = PrivacyService.getPrivacySafeCoordinates(
          original,
          PrivacyLevel.public,
        );

        expect(publicSafe.latitude, equals(original.latitude));
        expect(publicSafe.longitude, equals(original.longitude));
        expect(publicSafe.elevation, equals(original.elevation));
      });
    });

    group('Privacy Settings', () {
      test('should create privacy settings with defaults', () {
        const settings = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
        );

        expect(settings.privacyLevel, equals(PrivacyLevel.private));
        expect(settings.stripExifData, isTrue);
        expect(settings.shareLocation, isFalse);
        expect(settings.sharePhotos, isTrue);
        expect(settings.shareStats, isTrue);
      });

      test('should copy privacy settings with changes', () {
        const original = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
          stripExifData: true,
          shareLocation: false,
        );

        final updated = original.copyWith(
          privacyLevel: PrivacyLevel.public,
          shareLocation: true,
        );

        expect(updated.privacyLevel, equals(PrivacyLevel.public));
        expect(updated.stripExifData, isTrue); // Unchanged
        expect(updated.shareLocation, isTrue); // Changed
      });

      test('should serialize and deserialize privacy settings', () {
        const original = PrivacySettings(
          privacyLevel: PrivacyLevel.friends,
          stripExifData: false,
          shareLocation: true,
          sharePhotos: false,
          shareStats: true,
        );

        final json = original.toJson();
        final deserialized = PrivacySettings.fromJson(json);

        expect(deserialized.privacyLevel, equals(original.privacyLevel));
        expect(deserialized.stripExifData, equals(original.stripExifData));
        expect(deserialized.shareLocation, equals(original.shareLocation));
        expect(deserialized.sharePhotos, equals(original.sharePhotos));
        expect(deserialized.shareStats, equals(original.shareStats));
      });
    });
  });
}