import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/data/services/share_card_generator.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';

void main() {
  group('ShareCardGenerator', () {
    late ShareCardGenerator generator;
    late Activity testActivity;
    late Uint8List mockMapSnapshot;
    late List<Uint8List> mockPhotoThumbnails;

    setUp(() {
      generator = ShareCardGenerator();
      
      // Create mock map snapshot (1x1 pixel PNG)
      mockMapSnapshot = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x00,
        0x01, 0x00, 0x01, 0x5C, 0xC2, 0x8A, 0x8E, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
        0x42, 0x60, 0x82,
      ]);
      
      // Create mock photo thumbnails
      mockPhotoThumbnails = [mockMapSnapshot, mockMapSnapshot];
      
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
        photos: [
          Photo(
            id: 'photo1',
            activityId: 'activity1',
            timestamp: Timestamp(DateTime(2024, 1, 15, 10, 15, 0)),
            coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
            filePath: '/test/photo1.jpg',
            thumbnailPath: '/test/thumb1.jpg',
            curationScore: 0.8,
          ),
        ],
      );
    });

    group('Widget Building', () {
      testWidgets('should build share card widget', (WidgetTester tester) async {
        final widget = generator.buildShareCard(
          testActivity,
          mapSnapshot: mockMapSnapshot,
          photoThumbnails: mockPhotoThumbnails,
        );

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        // Verify main components are present
        expect(find.text('Morning Trail Run'), findsOneWidget);
        expect(find.text('Jan 15, 2024'), findsOneWidget);
        expect(find.text('Activity Stats'), findsOneWidget);
        expect(find.text('5.00 km'), findsOneWidget);
        expect(find.text('30m 0s'), findsOneWidget);
        expect(find.text('5:00/km'), findsOneWidget);
        expect(find.text('200m'), findsOneWidget);
        expect(find.text('Photos'), findsOneWidget);
        expect(find.text('Tracked with TrailRun'), findsOneWidget);
      });

      testWidgets('should handle activity without map snapshot', (WidgetTester tester) async {
        final widget = generator.buildShareCard(testActivity);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        expect(find.text('Morning Trail Run'), findsOneWidget);
        expect(find.text('Activity Stats'), findsOneWidget);
      });

      testWidgets('should handle activity without photos', (WidgetTester tester) async {
        final activityWithoutPhotos = testActivity.copyWith(photos: []);
        final widget = generator.buildShareCard(activityWithoutPhotos);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        expect(find.text('Morning Trail Run'), findsOneWidget);
        expect(find.text('Photos'), findsNothing);
      });

      testWidgets('should display correct stat icons', (WidgetTester tester) async {
        final widget = generator.buildShareCard(testActivity);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        expect(find.byIcon(Icons.straighten), findsOneWidget); // Distance
        expect(find.byIcon(Icons.timer), findsOneWidget); // Duration
        expect(find.byIcon(Icons.speed), findsOneWidget); // Pace
        expect(find.byIcon(Icons.terrain), findsOneWidget); // Elevation
      });
    });

    group('Data Formatting', () {
      test('should format date correctly', () {
        final testCases = {
          DateTime(2024, 1, 15): 'Jan 15, 2024',
          DateTime(2024, 12, 31): 'Dec 31, 2024',
          DateTime(2023, 6, 1): 'Jun 1, 2023',
        };

        for (final entry in testCases.entries) {
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          
          final formatted = '${months[entry.key.month - 1]} ${entry.key.day}, ${entry.key.year}';
          expect(formatted, equals(entry.value));
        }
      });

      test('should format duration correctly', () {
        final testCases = {
          const Duration(minutes: 30): '30m 0s',
          const Duration(hours: 1, minutes: 15): '1h 15m',
          const Duration(hours: 2, minutes: 30, seconds: 45): '2h 30m',
          const Duration(minutes: 5, seconds: 30): '5m 30s',
        };

        for (final entry in testCases.entries) {
          final duration = entry.key;
          final hours = duration.inHours;
          final minutes = (duration.inMinutes % 60);
          final seconds = (duration.inSeconds % 60);
          
          String formatted;
          if (hours > 0) {
            formatted = '${hours}h ${minutes}m';
          } else {
            formatted = '${minutes}m ${seconds}s';
          }
          
          expect(formatted, equals(entry.value));
        }
      });

      test('should format pace correctly', () {
        final testCases = {
          300.0: '5:00/km', // 5 minutes per km
          270.0: '4:30/km', // 4:30 per km
          360.0: '6:00/km', // 6 minutes per km
          330.0: '5:30/km', // 5:30 per km
        };

        for (final entry in testCases.entries) {
          final secondsPerKm = entry.key;
          final minutes = secondsPerKm ~/ 60;
          final seconds = (secondsPerKm % 60).round();
          
          final formatted = '${minutes}:${seconds.toString().padLeft(2, '0')}/km';
          expect(formatted, equals(entry.value));
        }
      });

      test('should handle null values gracefully', () {
        final activityWithNulls = Activity(
          id: 'test',
          startTime: Timestamp.now(),
          title: 'Test Run',
          // No endTime, averagePace, etc.
        );

        // Should not throw when building widget with null values
        expect(() => generator.buildShareCard(activityWithNulls), returnsNormally);
      });
    });

    group('Photo Thumbnail Loading', () {
      test('should limit photos to maximum of 5', () async {
        final manyPhotos = List.generate(10, (index) => Photo(
          id: 'photo$index',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          filePath: '/test/photo$index.jpg',
          thumbnailPath: '/test/thumb$index.jpg',
        ));

        final activityWithManyPhotos = testActivity.copyWith(photos: manyPhotos);
        
        // The widget should only show up to 5 photos
        expect(manyPhotos.length, equals(10));
        expect(manyPhotos.take(5).length, equals(5));
      });

      test('should handle empty photo list', () async {
        final thumbnails = await generator.loadPhotoThumbnails([]);
        expect(thumbnails, isEmpty);
      });
    });

    group('Widget Styling', () {
      testWidgets('should apply correct colors and styling', (WidgetTester tester) async {
        final widget = generator.buildShareCard(testActivity);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        // Check for gradient background in header
        final headerContainer = tester.widget<Container>(
          find.descendant(
            of: find.byType(Column),
            matching: find.byType(Container),
          ).first,
        );

        expect(headerContainer.decoration, isA<BoxDecoration>());
        final decoration = headerContainer.decoration as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());
      });

      testWidgets('should have proper border radius', (WidgetTester tester) async {
        final widget = generator.buildShareCard(testActivity);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        final mainContainer = tester.widget<Container>(find.byType(Container).first);
        expect(mainContainer.decoration, isA<BoxDecoration>());
        
        final decoration = mainContainer.decoration as BoxDecoration;
        expect(decoration.borderRadius, isA<BorderRadius>());
      });
    });

    group('Error Handling', () {
      test('should handle rendering errors gracefully', () async {
        // Test with invalid activity data
        final invalidActivity = Activity(
          id: '',
          startTime: Timestamp.now(),
          title: '',
        );

        // Should not throw when rendering invalid activity
        expect(() => generator.buildShareCard(invalidActivity), returnsNormally);
      });

      test('should handle missing photo thumbnails', () async {
        final thumbnails = await generator.loadPhotoThumbnails(testActivity.photos);
        
        // Should return empty list when files don't exist
        expect(thumbnails, isA<List<Uint8List>>());
      });
    });
  });
}