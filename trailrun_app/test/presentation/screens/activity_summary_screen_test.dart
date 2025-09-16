import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trailrun_app/presentation/screens/activity_summary_screen.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/models/split.dart' as domain;
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';

void main() {
  group('ActivitySummaryScreen', () {
    late Activity testActivity;

    setUp(() {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));
      
      testActivity = Activity(
        id: 'test_activity',
        startTime: Timestamp(startTime),
        endTime: Timestamp(now),
        title: 'Test Run',
        notes: 'A test run for UI testing',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(100),
        elevationLoss: Elevation.meters(50),
        averagePace: Pace.secondsPerKilometer(300), // 5:00/km
        privacy: PrivacyLevel.private,
        syncState: SyncState.synced,
        trackPoints: [
          TrackPoint(
            id: 'tp_1',
            activityId: 'test_activity',
            timestamp: Timestamp(startTime),
            coordinates: const Coordinates(
              latitude: 37.7749,
              longitude: -122.4194,
              elevation: 100,
            ),
            accuracy: 5.0,
            source: LocationSource.gps,
            sequence: 0,
          ),
        ],
        photos: [
          Photo(
            id: 'photo_1',
            activityId: 'test_activity',
            timestamp: Timestamp(startTime.add(const Duration(minutes: 30))),
            coordinates: const Coordinates(
              latitude: 37.7750,
              longitude: -122.4195,
              elevation: 110,
            ),
            filePath: 'test_photo.jpg',
            hasExifData: true,
            curationScore: 0.8,
          ),
        ],
        splits: [
          domain.Split(
            id: 'split_1',
            activityId: 'test_activity',
            splitNumber: 1,
            startTime: Timestamp(startTime),
            endTime: Timestamp(startTime.add(const Duration(minutes: 20))),
            distance: Distance.kilometers(1.0),
            pace: Pace.secondsPerKilometer(300),
            elevationGain: Elevation.meters(20),
            elevationLoss: Elevation.meters(10),
          ),
        ],
      );
    });

    testWidgets('displays activity title and basic information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      // Verify the app bar shows the activity title
      expect(find.text('Test Run'), findsOneWidget);
      
      // Verify edit and share buttons are present
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('displays activity stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify distance is displayed
      expect(find.textContaining('5.00 km'), findsOneWidget);
      
      // Verify duration is displayed
      expect(find.textContaining('1:00'), findsOneWidget);
      
      // Verify pace is displayed
      expect(find.textContaining('05:00'), findsOneWidget);
      
      // Verify elevation is displayed
      expect(find.textContaining('100 m'), findsOneWidget);
    });

    testWidgets('displays route section', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify route section is present
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('View Full Map'), findsOneWidget);
    });

    testWidgets('displays elevation profile section when track points have elevation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify elevation profile section is present
      expect(find.text('Elevation Profile'), findsOneWidget);
    });

    testWidgets('displays splits section when splits are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify splits section is present
      expect(find.text('Splits'), findsOneWidget);
      expect(find.text('Km 1'), findsOneWidget);
    });

    testWidgets('displays photos section when photos are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify photos section is present
      expect(find.text('Photos (1)'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('displays notes section when notes are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify notes section is present
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('A test run for UI testing'), findsOneWidget);
    });

    testWidgets('opens edit dialog when edit button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ActivitySummaryScreen(activity: testActivity),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Verify edit dialog is shown
      expect(find.text('Edit Activity'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Privacy Level'), findsOneWidget);
    });
  });
}