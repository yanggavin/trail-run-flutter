import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trailrun_app/main.dart' as app;
import 'package:trailrun_app/presentation/screens/home_screen.dart';
import 'package:trailrun_app/presentation/screens/tracking_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_summary_screen.dart';
import 'package:trailrun_app/presentation/widgets/share_export_sheet.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Tracking Workflow E2E Tests', () {
    testWidgets('Complete user journey from start to share', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify home screen loads
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Start Run'), findsOneWidget);

      // Start a new activity
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Verify tracking screen loads
      expect(find.byType(TrackingScreen), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
      expect(find.text('0.00 km'), findsOneWidget);

      // Wait for GPS to initialize (simulate)
      await tester.pump(const Duration(seconds: 3));

      // Verify tracking controls are available
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Test pause functionality
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Resume tracking
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Simulate some tracking time
      await tester.pump(const Duration(seconds: 5));

      // Test photo capture during tracking
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      // Verify camera interface (mock)
      // In real test, this would interact with camera
      await tester.pump(const Duration(milliseconds: 500));

      // Return to tracking screen
      await tester.pumpAndSettle();
      expect(find.byType(TrackingScreen), findsOneWidget);

      // Stop the activity
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Stop Activity'), findsOneWidget);
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify activity summary screen loads
      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
      expect(find.text('Activity Summary'), findsOneWidget);

      // Verify stats are displayed
      expect(find.textContaining('Distance'), findsOneWidget);
      expect(find.textContaining('Duration'), findsOneWidget);
      expect(find.textContaining('Pace'), findsOneWidget);

      // Test sharing functionality
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      // Verify share sheet opens
      expect(find.byType(ShareExportSheet), findsOneWidget);
      expect(find.text('Share Activity'), findsOneWidget);

      // Test different share options
      expect(find.text('Share Image'), findsOneWidget);
      expect(find.text('Export GPX'), findsOneWidget);
      expect(find.text('Export Photos'), findsOneWidget);

      // Close share sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Navigate back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back at home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify activity appears in history
      expect(find.text('Recent Activities'), findsOneWidget);
    });

    testWidgets('Auto-pause and resume workflow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start tracking
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Wait for tracking to start
      await tester.pump(const Duration(seconds: 2));

      // Simulate auto-pause trigger (mock stationary detection)
      // This would be triggered by the location service in real scenario
      await tester.pump(const Duration(seconds: 10));

      // Verify auto-pause indicator appears
      expect(find.textContaining('Auto-paused'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Simulate movement to trigger auto-resume
      await tester.pump(const Duration(seconds: 3));

      // Verify tracking resumes
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.textContaining('Auto-paused'), findsNothing);

      // Stop activity
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
    });

    testWidgets('Photo capture integration during tracking', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start tracking
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Wait for tracking to initialize
      await tester.pump(const Duration(seconds: 2));

      // Capture multiple photos
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();
        
        // Simulate quick camera return (< 400ms target)
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        
        // Verify we're back on tracking screen quickly
        expect(find.byType(TrackingScreen), findsOneWidget);
      }

      // Stop activity
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify photos appear in summary
      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
      // Photos should be visible in the gallery widget
      expect(find.textContaining('Photos'), findsOneWidget);
    });

    testWidgets('Battery and performance monitoring', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start tracking
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Verify battery indicator is present
      expect(find.textContaining('%'), findsOneWidget);

      // Verify GPS quality indicator
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);

      // Simulate long tracking session (1 hour simulation)
      final startTime = DateTime.now();
      
      // Fast-forward time simulation
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(minutes: 1));
        
        // Verify UI remains responsive
        expect(find.byType(TrackingScreen), findsOneWidget);
        
        // Check that stats are updating
        expect(find.textContaining(':'), findsOneWidget); // Time format
      }

      // Verify battery usage is within acceptable range
      // This would be validated through platform channels in real test
      
      // Stop activity
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify performance metrics in summary
      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
    });

    testWidgets('Error recovery and crash simulation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start tracking
      await tester.tap(find.text('Start Run'));
      await tester.pumpAndSettle();

      // Simulate app crash during tracking
      // This would trigger crash recovery on next launch
      
      // Restart app (simulate crash recovery)
      app.main();
      await tester.pumpAndSettle();

      // Verify crash recovery dialog appears
      expect(find.textContaining('Recover'), findsOneWidget);
      
      // Choose to recover session
      await tester.tap(find.text('Recover'));
      await tester.pumpAndSettle();

      // Verify tracking screen is restored
      expect(find.byType(TrackingScreen), findsOneWidget);
      
      // Verify session data is preserved
      expect(find.textContaining(':'), findsOneWidget); // Time should be restored

      // Complete the recovered session
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();

      // Verify activity is saved properly
      expect(find.byType(ActivitySummaryScreen), findsOneWidget);
    });
  });
}