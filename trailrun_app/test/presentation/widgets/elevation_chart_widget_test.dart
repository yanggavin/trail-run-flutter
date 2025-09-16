import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trailrun_app/presentation/widgets/elevation_chart_widget.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';

void main() {
  group('ElevationChartWidget', () {
    testWidgets('displays no data message when track points are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ElevationChartWidget(trackPoints: []),
          ),
        ),
      );

      expect(find.text('No elevation data available'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays chart when track points have elevation data', (WidgetTester tester) async {
      final trackPoints = [
        TrackPoint(
          id: 'tp_1',
          activityId: 'test_activity',
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(
            latitude: 37.7749,
            longitude: -122.4194,
            elevation: 100,
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: 'tp_2',
          activityId: 'test_activity',
          timestamp: Timestamp(DateTime.now().add(const Duration(minutes: 1))),
          coordinates: const Coordinates(
            latitude: 37.7750,
            longitude: -122.4195,
            elevation: 120,
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevationChartWidget(trackPoints: trackPoints),
          ),
        ),
      );

      // The chart should be displayed (no error message)
      expect(find.text('No elevation data available'), findsNothing);
      expect(find.text('No valid elevation data'), findsNothing);
    });

    testWidgets('displays no valid data message when track points have no elevation', (WidgetTester tester) async {
      final trackPoints = [
        TrackPoint(
          id: 'tp_1',
          activityId: 'test_activity',
          timestamp: Timestamp(DateTime.now()),
          coordinates: const Coordinates(
            latitude: 37.7749,
            longitude: -122.4194,
            // No elevation data
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevationChartWidget(trackPoints: trackPoints),
          ),
        ),
      );

      expect(find.text('No valid elevation data'), findsOneWidget);
    });
  });
}