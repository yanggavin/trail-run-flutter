import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/presentation/widgets/activity_map_widget.dart';

void main() {
  group('ActivityMapWidget', () {
    testWidgets('builds without error', (tester) async {
      final activity = Activity(
        id: 'test',
        startTime: Timestamp.now(),
        title: 'Test Activity',
        trackPoints: [],
        photos: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActivityMapWidget(
              activity: activity,
            ),
          ),
        ),
      );

      expect(find.byType(ActivityMapWidget), findsOneWidget);
    });
  });
}