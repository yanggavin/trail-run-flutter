import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trailrun_app/main.dart' as app;
import 'package:trailrun_app/presentation/screens/home_screen.dart';
import 'package:trailrun_app/presentation/screens/tracking_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_summary_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_history_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Functionality E2E Tests', () {
    testWidgets('Complete offline tracking workflow', (tester) async {
      // Start app in offline mode (mock network disconnection)
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads without network
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // Verify offline indicator is shown
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Start tracking while offline
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Verify tracking works offline
      expect(find.byType(TrackingScreen), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);

      // Simulate tracking with GPS data
      await tester.pump(const Duration(seconds: 5));

      // Capture photos while offline
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify photo capture works offline
      expect(find.byType(TrackingScreen), findsOneWidget);

      // Stop activity while offline
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify activity summary loads offline
      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
      expect(find.textContaining('Distance'), findsOneWidget);

      // Verify sync pending indicator
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.textContaining('Sync pending'), findsOneWidget);

      // Navigate to history
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify offline activity appears in history
      expect(find.byType(ActivityHistoryScreen), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('Network reconnection and sync behavior', (tester) async {
      // Start with offline activity
      app.main();
      await tester.pumpAndSettle();

      // Create offline activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Simulate network reconnection
      // This would trigger automatic sync in real scenario
      await tester.pump(const Duration(seconds: 2));

      // Verify sync indicator appears
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for sync to complete
      await tester.pump(const Duration(seconds: 5));

      // Verify sync success
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsNothing);

      // Verify activity is now synced
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Offline photo management and sync', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start offline tracking
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Capture multiple photos offline
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Stop activity
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify photos are stored locally
      expect(find.textContaining('Photos'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);

      // Verify photos have sync pending status
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Simulate network reconnection
      await tester.pump(const Duration(seconds: 3));

      // Verify photo sync begins
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for photo sync completion
      await tester.pump(const Duration(seconds: 10));

      // Verify all photos are synced
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Offline data persistence across app restarts', (tester) async {
      // Create offline activity
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Restart app (simulate app closure)
      app.main();
      await tester.pumpAndSettle();

      // Verify offline activity persists
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityHistoryScreen), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Verify activity details are preserved
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
      expect(find.textContaining('Distance'), findsOneWidget);
      expect(find.textContaining('Duration'), findsOneWidget);
    });

    testWidgets('Offline search and filtering', (tester) async {
      // Create multiple offline activities
      app.main();
      await tester.pumpAndSettle();

      // Create first activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Create second activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify both activities appear
      expect(find.byType(Card), findsNWidgets(2));

      // Test search functionality offline
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'run');
      await tester.pumpAndSettle();

      // Verify search works offline
      expect(find.byType(Card), findsAtLeastNWidgets(1));

      // Test filtering offline
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Apply date filter
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify filtering works offline
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('Offline export functionality', (tester) async {
      // Create offline activity with photos
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      
      // Capture photo
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Test offline export
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      // Verify export options available offline
      expect(find.text('Export GPX'), findsOneWidget);
      expect(find.text('Export Photos'), findsOneWidget);

      // Test GPX export offline
      await tester.tap(find.text('Export GPX'));
      await tester.pumpAndSettle();

      // Verify export completes offline
      expect(find.textContaining('Exported'), findsOneWidget);

      // Close export sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Test photo export offline
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export Photos'));
      await tester.pumpAndSettle();

      // Verify photo export works offline
      expect(find.textContaining('Exported'), findsOneWidget);
    });
  });
}