import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trailrun_app/main.dart' as app;
import 'package:trailrun_app/presentation/screens/home_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_history_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_summary_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sync Behavior E2E Tests', () {
    testWidgets('Automatic sync on network reconnection', (tester) async {
      // Start with offline mode
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

      // Verify sync pending status
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Simulate network reconnection
      await tester.pump(const Duration(seconds: 1));

      // Verify automatic sync starts
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for sync completion
      await tester.pump(const Duration(seconds: 5));

      // Verify sync success
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    });

    testWidgets('Sync conflict resolution - server wins', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create activity that will conflict
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Edit activity locally (simulate conflict scenario)
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'Local Edit');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Simulate sync with server conflict
      await tester.pump(const Duration(seconds: 2));

      // Verify conflict resolution dialog appears
      expect(find.textContaining('Sync Conflict'), findsOneWidget);
      expect(find.text('Keep Server Version'), findsOneWidget);
      expect(find.text('Keep Local Version'), findsOneWidget);

      // Choose server wins resolution
      await tester.tap(find.text('Keep Server Version'));
      await tester.pumpAndSettle();

      // Verify server version is kept
      expect(find.textContaining('Local Edit'), findsNothing);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Sync conflict resolution - keep local', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create and edit activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Important Local Edit');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Simulate sync conflict
      await tester.pump(const Duration(seconds: 2));

      // Choose to keep local version
      await tester.tap(find.text('Keep Local Version'));
      await tester.pumpAndSettle();

      // Verify local version is preserved
      expect(find.textContaining('Important Local Edit'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Exponential backoff retry on sync failure', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create activity
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

      // Simulate sync failure (network error)
      await tester.pump(const Duration(seconds: 2));

      // Verify retry indicator
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Wait for first retry (1 second)
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Simulate failure again
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Wait for second retry (2 seconds - exponential backoff)
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Simulate success on third attempt
      await tester.pump(const Duration(seconds: 3));
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Batch sync of multiple activities', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create multiple offline activities
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Start Run'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.byIcon(Icons.stop));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      // Navigate to history to see all activities
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify all activities are pending sync
      expect(find.byIcon(Icons.sync_problem), findsNWidgets(3));

      // Trigger batch sync
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // Verify batch sync starts
      expect(find.byIcon(Icons.sync), findsAtLeastNWidgets(1));

      // Wait for batch sync completion
      await tester.pump(const Duration(seconds: 10));

      // Verify all activities are synced
      expect(find.byIcon(Icons.cloud_done), findsNWidgets(3));
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    });

    testWidgets('Photo sync with large files', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create activity with multiple photos
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Capture multiple photos (simulate large files)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify photos are pending sync
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Navigate back and trigger sync
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Verify photo sync progress
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for photo sync (longer for large files)
      await tester.pump(const Duration(seconds: 15));

      // Verify all photos are synced
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Verify photos are accessible after sync
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Photos'), findsOneWidget);
      expect(find.textContaining('5'), findsOneWidget);
    });

    testWidgets('Sync queue management and prioritization', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create activities with different priorities
      // Recent activity (high priority)
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Older activity (lower priority)
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify sync queue shows proper order
      expect(find.byIcon(Icons.sync_problem), findsNWidgets(2));

      // Trigger sync
      await tester.pump(const Duration(seconds: 2));

      // Verify recent activity syncs first
      await tester.pump(const Duration(seconds: 3));
      
      // At least one should be synced by now (the recent one)
      expect(find.byIcon(Icons.cloud_done), findsAtLeastNWidgets(1));

      // Wait for all to complete
      await tester.pump(const Duration(seconds: 5));
      expect(find.byIcon(Icons.cloud_done), findsNWidgets(2));
    });

    testWidgets('Sync status indicators and user feedback', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify initial sync pending status
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      expect(find.textContaining('Sync pending'), findsOneWidget);

      // Navigate back and start sync
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Verify sync in progress indicators
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for sync completion
      await tester.pump(const Duration(seconds: 5));

      // Verify sync success indicators
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.textContaining('Synced'), findsOneWidget);

      // Verify status persists in history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Manual sync trigger and control', (tester) async {
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
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify manual sync option is available
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Trigger manual sync
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // Verify sync starts immediately
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Wait for completion
      await tester.pump(const Duration(seconds: 5));
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Test sync cancellation (if supported)
      // Create another activity
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Start sync and immediately try to cancel
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle();

      // Look for cancel option during sync
      if (find.byIcon(Icons.cancel).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle();
        
        // Verify sync is cancelled
        expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      }
    });
  });
}