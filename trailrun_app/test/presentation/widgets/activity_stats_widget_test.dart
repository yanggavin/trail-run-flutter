import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trailrun_app/presentation/widgets/activity_stats_widget.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/models/split.dart' as domain;
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';

void main() {
  group('ActivityStatsWidget', () {
    late Activity testActivity;

    setUp(() {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1, minutes: 30));
      
      testActivity = Activity(
        id: 'test_activity',
        startTime: Timestamp(startTime),
        endTime: Timestamp(now),
        title: 'Morning Trail Run',
        notes: 'Great run!',
        distance: Distance.kilometers(10.5),
        elevationGain: Elevation.meters(250),
        elevationLoss: Elevation.meters(180),
        averagePace: Pace.secondsPerKilometer(330), // 5:30/km
        privacy: PrivacyLevel.friends,
        syncState: SyncState.synced,
        photos: [
          Photo(
            id: 'photo_1',
            activityId: 'test_activity',
            timestamp: Timestamp(startTime.add(const Duration(minutes: 30))),
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
            pace: Pace.secondsPerKilometer(300), // 5:00/km
            elevationGain: Elevation.meters(20),
            elevationLoss: Elevation.meters(10),
          ),
          domain.Split(
            id: 'split_2',
            activityId: 'test_activity',
            splitNumber: 2,
            startTime: Timestamp(startTime.add(const Duration(minutes: 20))),
            endTime: Timestamp(startTime.add(const Duration(minutes: 42))),
            distance: Distance.kilometers(1.0),
            pace: Pace.secondsPerKilometer(360), // 6:00/km
            elevationGain: Elevation.meters(25),
            elevationLoss: Elevation.meters(15),
          ),
        ],
      );
    });

    testWidgets('displays activity title and privacy level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: testActivity),
          ),
        ),
      );

      // Verify activity title is displayed
      expect(find.text('Morning Trail Run'), findsOneWidget);
      
      // Verify privacy level is displayed
      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('displays main statistics correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: testActivity),
          ),
        ),
      );

      // Verify distance
      expect(find.textContaining('10.50 km'), findsOneWidget);
      
      // Verify duration (1 hour 30 minutes)
      expect(find.textContaining('1h 30m'), findsOneWidget);
      
      // Verify average pace (5:30/km)
      expect(find.textContaining('05:30'), findsOneWidget);
      
      // Verify elevation gain
      expect(find.textContaining('250 m'), findsOneWidget);
    });

    testWidgets('displays additional stats when splits and photos are available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: testActivity),
          ),
        ),
      );

      // Verify splits count
      expect(find.textContaining('2'), findsOneWidget); // 2 splits
      
      // Verify photos count
      expect(find.textContaining('1'), findsOneWidget); // 1 photo
    });

    testWidgets('displays best and slowest splits when multiple splits exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: testActivity),
          ),
        ),
      );

      // Verify best split (5:00/km)
      expect(find.text('Best Split'), findsOneWidget);
      expect(find.textContaining('05:00'), findsOneWidget);
      
      // Verify slowest split (6:00/km)
      expect(find.text('Slowest Split'), findsOneWidget);
      expect(find.textContaining('06:00'), findsOneWidget);
    });

    testWidgets('handles activity without optional data gracefully', (WidgetTester tester) async {
      final minimalActivity = Activity(
        id: 'minimal_activity',
        startTime: Timestamp(DateTime.now().subtract(const Duration(hours: 1))),
        title: 'Minimal Run',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(50),
        elevationLoss: Elevation.meters(30),
        privacy: PrivacyLevel.private,
        syncState: SyncState.local,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: minimalActivity),
          ),
        ),
      );

      // Verify basic stats are still displayed
      expect(find.text('Minimal Run'), findsOneWidget);
      expect(find.textContaining('5.00 km'), findsOneWidget);
      expect(find.textContaining('50 m'), findsOneWidget);
      
      // Verify pace shows placeholder when not available
      expect(find.textContaining('--:--'), findsOneWidget);
    });

    testWidgets('displays correct privacy indicators', (WidgetTester tester) async {
      final privateActivity = testActivity.copyWith(privacy: PrivacyLevel.private);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityStatsWidget(activity: privateActivity),
          ),
        ),
      );

      // Verify private privacy level
      expect(find.text('Private'), findsOneWidget);
    });
  });
}