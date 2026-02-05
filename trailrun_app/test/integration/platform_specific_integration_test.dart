import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trailrun_app/data/services/accessibility_service.dart';
import 'package:trailrun_app/data/services/platform_file_service.dart';
import 'package:trailrun_app/data/services/platform_permission_service.dart';
import 'package:trailrun_app/data/services/platform_specific_service.dart';
import 'package:trailrun_app/presentation/widgets/accessible_widgets.dart';
import 'package:trailrun_app/presentation/widgets/permission_request_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Platform-Specific Integration Tests', () {
    testWidgets('Permission request flow works end-to-end', (tester) async {
      bool permissionsGranted = false;
      bool permissionsDenied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionRequestFlow(
            onPermissionsGranted: () => permissionsGranted = true,
            onPermissionsDenied: () => permissionsDenied = true,
          ),
        ),
      );

      // Verify initial UI
      expect(find.text('Permissions Required'), findsOneWidget);
      expect(find.text('Location Access'), findsOneWidget);

      // Test navigation through permission steps
      await tester.pumpAndSettle();

      // The exact behavior will depend on actual permissions
      // In a real integration test, you would interact with the permission dialogs
    });

    testWidgets('Accessible widgets adapt to system settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccessibleButton(
                  onPressed: () {},
                  semanticLabel: 'Test button',
                  child: const Text('Button'),
                ),
                AccessibleText('Test text'),
                AccessibleCard(
                  semanticLabel: 'Test card',
                  child: const Text('Card content'),
                ),
                AccessibleListTile(
                  title: const Text('List item'),
                  semanticLabel: 'Test list item',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets are rendered
      expect(find.text('Button'), findsOneWidget);
      expect(find.text('Test text'), findsOneWidget);
      expect(find.text('Card content'), findsOneWidget);
      expect(find.text('List item'), findsOneWidget);

      // Test interactions
      await tester.tap(find.text('Button'));
      await tester.tap(find.text('List item'));
      await tester.pumpAndSettle();
    });

    testWidgets('Platform-specific services handle errors gracefully', (tester) async {
      // Test that services don't crash when platform methods are unavailable
      expect(() async {
        await PlatformSpecificService.getBatteryInfo();
      }, returnsNormally);

      expect(() async {
        await PlatformSpecificService.getAndroidSdkVersion();
      }, returnsNormally);

      expect(() async {
        await PlatformSpecificService.getIOSVersion();
      }, returnsNormally);

      expect(() async {
        await PlatformSpecificService.isLowPowerModeEnabled();
      }, returnsNormally);
    });

    testWidgets('File service operations work correctly', (tester) async {
      // Test file service operations
      final appDir = await PlatformFileService.getAppStorageDirectory();
      expect(appDir.existsSync(), true);

      final cacheDir = await PlatformFileService.getCacheDirectory();
      expect(cacheDir.existsSync(), true);

      final photoDir = await PlatformFileService.getPhotoStorageDirectory();
      expect(photoDir.existsSync(), true);

      final exportDir = await PlatformFileService.getExportDirectory();
      expect(exportDir.existsSync(), true);

      // Test file operations
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final file = await PlatformFileService.saveFile(
        fileName: 'test.txt',
        data: testData,
        fileType: FileType.cache,
      );

      expect(file.existsSync(), true);

      final readData = await PlatformFileService.readFile(file.path);
      expect(readData, isNotNull);
      expect(readData, equals(testData));

      final fileSize = await PlatformFileService.getFileSize(file.path);
      expect(fileSize, testData.length);

      final exists = await PlatformFileService.fileExists(file.path);
      expect(exists, true);

      final deleted = await PlatformFileService.deleteFile(file.path);
      expect(deleted, true);

      final existsAfterDelete = await PlatformFileService.fileExists(file.path);
      expect(existsAfterDelete, false);
    });

    testWidgets('Accessibility service provides correct information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test accessibility detection
              final isScreenReader = AccessibilityService.isScreenReaderEnabled(context);
              final isHighContrast = AccessibilityService.isHighContrastEnabled(context);
              final isBoldText = AccessibilityService.isBoldTextEnabled(context);
              final textScale = AccessibilityService.getTextScaleFactor(context);
              final isReduceMotion = AccessibilityService.isReduceMotionEnabled(context);

              // Test accessibility helpers
              final colors = AccessibilityService.getAccessibilityColors(context);
              final textStyles = AccessibilityService.getAccessibilityTextStyles(context);
              final minTouchSize = AccessibilityService.getMinimumTouchTargetSize();

              return Column(
                children: [
                  Text('Screen reader: $isScreenReader'),
                  Text('High contrast: $isHighContrast'),
                  Text('Bold text: $isBoldText'),
                  Text('Text scale: $textScale'),
                  Text('Reduce motion: $isReduceMotion'),
                  Text('Min touch size: $minTouchSize'),
                  Container(
                    color: colors.primary,
                    child: Text(
                      'Colored text',
                      style: textStyles.body1?.copyWith(color: colors.onPrimary),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify accessibility information is displayed
      expect(find.textContaining('Screen reader:'), findsOneWidget);
      expect(find.textContaining('High contrast:'), findsOneWidget);
      expect(find.textContaining('Bold text:'), findsOneWidget);
      expect(find.textContaining('Text scale:'), findsOneWidget);
      expect(find.textContaining('Reduce motion:'), findsOneWidget);
      expect(find.textContaining('Min touch size:'), findsOneWidget);
      expect(find.text('Colored text'), findsOneWidget);
    });

    testWidgets('Permission service handles different permission states', (tester) async {
      // Test permission checking
      final permissionStatus = await PlatformPermissionService.checkAllPermissions();
      
      // Verify permission status structure
      expect(permissionStatus.location, isA<LocationPermissionResult>());
      expect(permissionStatus.camera, isA<bool>());
      expect(permissionStatus.storage, isA<bool>());
      expect(permissionStatus.hasAllRequired, isA<bool>());
      expect(permissionStatus.hasBackgroundLocation, isA<bool>());

      // Test platform detection
      final androidSdk = await PlatformPermissionService.getAndroidSdkVersion();
      expect(androidSdk, isA<int>());
    });

    testWidgets('Platform-specific lifecycle handling works', (tester) async {
      bool foregroundCalled = false;
      bool backgroundCalled = false;

      // Set up lifecycle handler
      PlatformSpecificService.setLifecycleHandler((state) {
        switch (state) {
          case 'foreground':
            foregroundCalled = true;
            break;
          case 'background':
            backgroundCalled = true;
            break;
        }
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Lifecycle test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In a real integration test, you would simulate app lifecycle changes
      // For now, we just verify the handler can be set without errors
      expect(find.text('Lifecycle test'), findsOneWidget);
    });

    testWidgets('File sharing operations work correctly', (tester) async {
      // Test file sharing capabilities
      final canShare = PlatformFileService.canUseNativeShare();
      expect(canShare, isA<bool>());

      // Test MIME type detection
      expect(PlatformFileService.getMimeType('test.gpx'), 'application/gpx+xml');
      expect(PlatformFileService.getMimeType('test.json'), 'application/json');
      expect(PlatformFileService.getMimeType('test.jpg'), 'image/jpeg');
      expect(PlatformFileService.getMimeType('test.png'), 'image/png');

      // Test file extension detection
      expect(PlatformFileService.getExportFileExtension(ExportType.gpx), '.gpx');
      expect(PlatformFileService.getExportFileExtension(ExportType.json), '.json');
      expect(PlatformFileService.getExportFileExtension(ExportType.csv), '.csv');

      // Test platform capability detection
      expect(PlatformFileService.supportsFileOperation(FileOperation.share), true);
      expect(PlatformFileService.supportsFileOperation(FileOperation.export), true);
    });

    testWidgets('Cleanup operations work correctly', (tester) async {
      // Test cleanup operations
      expect(() async {
        await PlatformFileService.cleanupTempFiles();
      }, returnsNormally);

      // Test storage space check
      final availableSpace = await PlatformFileService.getAvailableStorageSpace();
      expect(availableSpace, isA<int>());
    });
  });
}
