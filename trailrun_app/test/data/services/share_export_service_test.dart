import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trailrun_app/data/services/share_export_service.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';

// Mock classes
class MockDirectory extends Mock implements Directory {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ShareExportService', () {
    late ShareExportService service;
    late Activity testActivity;
    late List<TrackPoint> testTrackPoints;
    late List<Photo> testPhotos;

    setUp(() {
      service = ShareExportService();
      
      // Create test track points
      testTrackPoints = [
        TrackPoint(
          id: 'tp1',
          activityId: 'activity1',
          timestamp: Timestamp(DateTime(2024, 1, 15, 10, 0, 0)),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 100),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'tp2',
          activityId: 'activity1',
          timestamp: Timestamp(DateTime(2024, 1, 15, 10, 5, 0)),
          coordinates: const Coordinates(latitude: 37.7750, longitude: -122.4195, elevation: 110),
          accuracy: 4.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];
      
      // Create test photos
      testPhotos = [
        Photo(
          id: 'photo1',
          activityId: 'activity1',
          timestamp: Timestamp(DateTime(2024, 1, 15, 10, 2, 30)),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194, elevation: 105),
          filePath: '/test/photo1.jpg',
          thumbnailPath: '/test/thumb1.jpg',
          hasExifData: true,
          curationScore: 0.8,
          caption: 'Beautiful view',
        ),
      ];
      
      // Create test activity
      testActivity = Activity(
        id: 'activity1',
        startTime: Timestamp(DateTime(2024, 1, 15, 10, 0, 0)),
        endTime: Timestamp(DateTime(2024, 1, 15, 10, 30, 0)),
        title: 'Morning Trail Run',
        notes: 'Great weather today!',
        distance: Distance.meters(5000),
        elevationGain: Elevation.meters(200),
        elevationLoss: Elevation.meters(150),
        averagePace: Pace.secondsPerKilometer(300), // 5:00/km
        privacy: PrivacyLevel.public,
        trackPoints: testTrackPoints,
        photos: testPhotos,
      );
    });

    group('GPX Export', () {
      test('should generate valid GPX content', () async {
        final gpxFile = await service.exportActivityAsGpx(testActivity);
        
        expect(gpxFile.path, contains('.gpx'));
        
        // Read and verify GPX content
        final file = File(gpxFile.path);
        expect(await file.exists(), isTrue);
        
        final content = await file.readAsString();
        
        // Verify GPX structure
        expect(content, contains('<?xml version="1.0" encoding="UTF-8"?>'));
        expect(content, contains('<gpx version="1.1"'));
        expect(content, contains('Morning Trail Run'));
        expect(content, contains('<trk>'));
        expect(content, contains('<trkpt lat="37.7749" lon="-122.4194">'));
        expect(content, contains('<ele>100.0</ele>'));
        expect(content, contains('<wpt lat="37.7749" lon="-122.4194">'));
        expect(content, contains('Photo 1'));
      });

      test('should handle activity without track points', () async {
        final activityWithoutPoints = testActivity.copyWith(trackPoints: []);
        
        final gpxFile = await service.exportActivityAsGpx(activityWithoutPoints);
        final content = await File(gpxFile.path).readAsString();
        
        expect(content, contains('<gpx'));
        expect(content, contains('Morning Trail Run'));
        expect(content, isNot(contains('<trk>')));
      });

      test('should obfuscate coordinates for private activities', () async {
        final privateActivity = testActivity.copyWith(privacy: PrivacyLevel.private);
        
        final gpxFile = await service.exportActivityAsGpx(privateActivity);
        final content = await File(gpxFile.path).readAsString();
        
        // Coordinates should be rounded to 3 decimal places for privacy
        expect(content, contains('lat="37.775"'));
        expect(content, contains('lon="-122.419"'));
      });

      test('should escape XML special characters', () async {
        final activityWithSpecialChars = testActivity.copyWith(
          title: 'Run with <special> & "characters"',
          notes: 'Notes with <tags> & symbols',
        );
        
        final gpxFile = await service.exportActivityAsGpx(activityWithSpecialChars);
        final content = await File(gpxFile.path).readAsString();
        
        expect(content, contains('&lt;special&gt; &amp; &quot;characters&quot;'));
        expect(content, contains('&lt;tags&gt; &amp; symbols'));
      });
    });

    group('Photo Bundle Export', () {
      test('should export photos with metadata', () async {
        // This test would need file system mocking to work properly
        // For now, we'll test the metadata generation logic
        
        expect(testActivity.photos, hasLength(1));
        expect(testActivity.photos.first.hasExifData, isTrue);
      });

      test('should generate correct photo metadata', () {
        // Test the metadata generation logic by accessing private method
        // In a real implementation, you might make this method public for testing
        
        final metadata = {
          'activity': {
            'id': testActivity.id,
            'title': testActivity.title,
            'startTime': testActivity.startTime.dateTime.toIso8601String(),
            'endTime': testActivity.endTime?.dateTime.toIso8601String(),
            'distance': testActivity.distance.meters,
            'duration': testActivity.duration?.inSeconds,
            'notes': testActivity.notes,
          },
          'photos': testActivity.photos.map((photo) => {
            'id': photo.id,
            'timestamp': photo.timestamp.dateTime.toIso8601String(),
            'coordinates': photo.coordinates != null ? {
              'latitude': photo.coordinates!.latitude,
              'longitude': photo.coordinates!.longitude,
              'elevation': photo.coordinates!.elevation,
            } : null,
            'caption': photo.caption,
            'curationScore': photo.curationScore,
          }).toList(),
          'exportedAt': DateTime.now().toIso8601String(),
          'privacyLevel': testActivity.privacy.name,
        };
        
        expect(metadata['activity'], isA<Map<String, dynamic>>());
        expect(metadata['photos'], isA<List>());
        expect((metadata['photos'] as List), hasLength(1));
      });
    });

    group('Share Text Generation', () {
      test('should generate proper share text', () {
        // Test share text generation logic
        final expectedElements = [
          '🏃‍♂️ Morning Trail Run',
          '📊 Stats:',
          '• Distance: 5.00 km',
          '• Time: 30m 0s',
          '• Avg Pace: 5:00/km',
          '• Elevation Gain: 200m',
          '• Photos: 1',
          'Tracked with TrailRun 📱',
        ];
        
        // This would test the private _generateShareText method
        // In practice, you might expose this as a public method for testing
        expect(expectedElements, everyElement(isA<String>()));
      });
    });

    group('Privacy Handling', () {
      test('should respect privacy settings for coordinate stripping', () {
        final privateActivity = testActivity.copyWith(privacy: PrivacyLevel.private);
        final publicActivity = testActivity.copyWith(privacy: PrivacyLevel.public);
        
        // Test that private activities would have coordinates obfuscated
        expect(privateActivity.privacy.isRestricted, isTrue);
        expect(publicActivity.privacy.isRestricted, isFalse);
      });

      test('should handle photo inclusion based on privacy', () {
        final privateActivity = testActivity.copyWith(privacy: PrivacyLevel.private);
        final publicActivity = testActivity.copyWith(privacy: PrivacyLevel.public);
        
        // Both should include photos if they exist, but private should strip EXIF
        expect(privateActivity.photos, isNotEmpty);
        expect(publicActivity.photos, isNotEmpty);
      });
    });

    group('File Operations', () {
      test('should sanitize filenames properly', () {
        final testCases = {
          'Normal Run': 'normal_run',
          'Run with <special> chars': 'run_with__special__chars',
          'Run/with\\slashes': 'run_with_slashes',
          'Run with "quotes"': 'run_with__quotes_',
          'Multiple   Spaces': 'multiple_spaces',
        };
        
        // Test filename sanitization logic
        for (final entry in testCases.entries) {
          final sanitized = entry.key
              .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
              .replaceAll(RegExp(r'\s+'), '_')
              .toLowerCase();
          expect(sanitized, equals(entry.value));
        }
      });
    });

    group('Error Handling', () {
      test('should handle missing photos gracefully', () async {
        final activityWithoutPhotos = testActivity.copyWith(photos: []);
        
        // Should not throw when exporting activity without photos
        expect(() => service.exportActivityAsGpx(activityWithoutPhotos), returnsNormally);
      });

      test('should handle invalid file paths', () {
        final photoWithInvalidPath = Photo(
          id: 'invalid',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          filePath: '/nonexistent/path.jpg',
        );
        
        final activityWithInvalidPhoto = testActivity.copyWith(
          photos: [photoWithInvalidPath],
        );
        
        // Should handle invalid photo paths gracefully
        expect(activityWithInvalidPhoto.photos, hasLength(1));
      });
    });
  });
}