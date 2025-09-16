import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trailrun_app/presentation/app.dart';
import 'package:trailrun_app/presentation/screens/activity_history_screen.dart';

void main() {
  group('Activity History Integration Tests', () {
    testWidgets('Activity history screen can be navigated to and displays correctly', (tester) async {
      await tester.pumpWidget(const TrailRunApp());
      await tester.pumpAndSettle();

      // Find and tap the "View Activity History" button
      final historyButton = find.text('View Activity History');
      expect(historyButton, findsOneWidget);

      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Verify we're on the activity history screen
      expect(find.text('Activity History'), findsOneWidget);
      
      // Verify search bar is present
      expect(find.byType(TextField), findsOneWidget);
      
      // Verify filter and sort buttons are present
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);
      
      // Since there are no activities, should show empty state
      expect(find.text('No activities found'), findsOneWidget);
      expect(find.text('Start tracking your first run!'), findsOneWidget);
    });

    testWidgets('Search functionality is accessible', (tester) async {
      await tester.pumpWidget(const TrailRunApp());
      await tester.pumpAndSettle();

      // Navigate to history screen
      await tester.tap(find.text('View Activity History'));
      await tester.pumpAndSettle();

      // Find search field and enter text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test search');
      await tester.pumpAndSettle();

      // Verify search text is entered
      expect(find.text('test search'), findsOneWidget);
    });

    testWidgets('Filter sheet can be opened', (tester) async {
      await tester.pumpWidget(const TrailRunApp());
      await tester.pumpAndSettle();

      // Navigate to history screen
      await tester.tap(find.text('View Activity History'));
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify filter sheet is shown
      expect(find.text('Filter Activities'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Distance Range (km)'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Privacy Level'), findsOneWidget);
    });

    testWidgets('Sort menu can be opened', (tester) async {
      await tester.pumpWidget(const TrailRunApp());
      await tester.pumpAndSettle();

      // Navigate to history screen
      await tester.tap(find.text('View Activity History'));
      await tester.pumpAndSettle();

      // Tap sort button
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Verify sort options are shown
      expect(find.text('Newest First'), findsOneWidget);
      expect(find.text('Oldest First'), findsOneWidget);
      expect(find.text('Longest Distance'), findsOneWidget);
      expect(find.text('Shortest Distance'), findsOneWidget);
      expect(find.text('Longest Duration'), findsOneWidget);
      expect(find.text('Shortest Duration'), findsOneWidget);
    });
  });
}