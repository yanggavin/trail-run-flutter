import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/data/services/accessibility_service.dart';

void main() {
  group('AccessibilityService', () {
    testWidgets('isScreenReaderEnabled returns correct value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isEnabled = AccessibilityService.isScreenReaderEnabled(context);
              return Text('Screen reader: $isEnabled');
            },
          ),
        ),
      );

      // Default should be false in test environment
      expect(find.text('Screen reader: false'), findsOneWidget);
    });

    testWidgets('isHighContrastEnabled returns correct value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isEnabled = AccessibilityService.isHighContrastEnabled(context);
              return Text('High contrast: $isEnabled');
            },
          ),
        ),
      );

      // Default should be false in test environment
      expect(find.text('High contrast: false'), findsOneWidget);
    });

    testWidgets('isBoldTextEnabled returns correct value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isEnabled = AccessibilityService.isBoldTextEnabled(context);
              return Text('Bold text: $isEnabled');
            },
          ),
        ),
      );

      // Default should be false in test environment
      expect(find.text('Bold text: false'), findsOneWidget);
    });

    testWidgets('getTextScaleFactor returns correct value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scaleFactor = AccessibilityService.getTextScaleFactor(context);
              return Text('Scale factor: $scaleFactor');
            },
          ),
        ),
      );

      // Default should be 1.0 in test environment
      expect(find.text('Scale factor: 1.0'), findsOneWidget);
    });

    testWidgets('isReduceMotionEnabled returns correct value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isEnabled = AccessibilityService.isReduceMotionEnabled(context);
              return Text('Reduce motion: $isEnabled');
            },
          ),
        ),
      );

      // Default should be false in test environment
      expect(find.text('Reduce motion: false'), findsOneWidget);
    });

    testWidgets('getAccessibilityColors returns appropriate colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final colors = AccessibilityService.getAccessibilityColors(context);
              return Container(
                color: colors.primary,
                child: Text(
                  'Test',
                  style: TextStyle(color: colors.onPrimary),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('getAccessibilityTextStyles returns appropriate styles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final textStyles = AccessibilityService.getAccessibilityTextStyles(context);
              return Column(
                children: [
                  Text('Headline 1', style: textStyles.headline1),
                  Text('Body 1', style: textStyles.body1),
                  Text('Button', style: textStyles.button),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Headline 1'), findsOneWidget);
      expect(find.text('Body 1'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('createAccessibleButton creates proper widget', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleButton(
              child: const Text('Test Button'),
              onPressed: () => buttonPressed = true,
              semanticLabel: 'Test button for accessibility',
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(buttonPressed, true);
    });

    testWidgets('createAccessibleTextField creates proper widget', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleTextField(
              controller: controller,
              labelText: 'Test Field',
              semanticLabel: 'Test text field for accessibility',
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test input');
      expect(controller.text, 'test input');
    });

    testWidgets('createAccessibleIcon creates proper widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleIcon(
              icon: Icons.star,
              semanticLabel: 'Star icon',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('createAccessibleProgressIndicator creates proper widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleProgressIndicator(
              value: 0.5,
              semanticLabel: 'Progress indicator',
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('createAccessibleListTile creates proper widget', (tester) async {
      bool tileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleListTile(
              title: const Text('Test Title'),
              subtitle: const Text('Test Subtitle'),
              onTap: () => tileTapped = true,
              semanticLabel: 'Test list tile',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.byType(ListTile));
      expect(tileTapped, true);
    });

    test('getMinimumTouchTargetSize returns correct value', () {
      final minSize = AccessibilityService.getMinimumTouchTargetSize();
      expect(minSize, 48.0);
    });

    test('isTouchTargetAccessible validates size correctly', () {
      expect(AccessibilityService.isTouchTargetAccessible(const Size(48, 48)), true);
      expect(AccessibilityService.isTouchTargetAccessible(const Size(40, 40)), false);
      expect(AccessibilityService.isTouchTargetAccessible(const Size(50, 30)), false);
    });

    testWidgets('createAccessibleGestureDetector creates proper widget', (tester) async {
      bool gestureDetected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityService.createAccessibleGestureDetector(
              child: const Text('Tap me'),
              onTap: () => gestureDetected = true,
              semanticLabel: 'Tappable area',
            ),
          ),
        ),
      );

      expect(find.text('Tap me'), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);

      await tester.tap(find.text('Tap me'));
      expect(gestureDetected, true);
    });

    testWidgets('createAccessibleTheme adapts to accessibility settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final baseTheme = Theme.of(context);
              final accessibleTheme = AccessibilityService.createAccessibleTheme(
                context: context,
                baseTheme: baseTheme,
              );
              
              return Theme(
                data: accessibleTheme,
                child: const Text('Themed text'),
              );
            },
          ),
        ),
      );

      expect(find.text('Themed text'), findsOneWidget);
    });

    group('AccessibilityColors', () {
      test('constructor sets all properties correctly', () {
        const colors = AccessibilityColors(
          primary: Colors.blue,
          onPrimary: Colors.white,
          secondary: Colors.green,
          onSecondary: Colors.black,
          surface: Colors.grey,
          onSurface: Colors.black,
          background: Colors.white,
          onBackground: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        );

        expect(colors.primary, Colors.blue);
        expect(colors.onPrimary, Colors.white);
        expect(colors.secondary, Colors.green);
        expect(colors.onSecondary, Colors.black);
        expect(colors.surface, Colors.grey);
        expect(colors.onSurface, Colors.black);
        expect(colors.background, Colors.white);
        expect(colors.onBackground, Colors.black);
        expect(colors.error, Colors.red);
        expect(colors.onError, Colors.white);
      });
    });

    group('PlatformAccessibilitySettings', () {
      test('default constructor sets correct defaults', () {
        const settings = PlatformAccessibilitySettings();

        expect(settings.isScreenReaderEnabled, false);
        expect(settings.isHighContrastEnabled, false);
        expect(settings.isBoldTextEnabled, false);
        expect(settings.isReduceMotionEnabled, false);
        expect(settings.textScaleFactor, 1.0);
      });

      test('fromMap creates correct instance', () {
        final settings = PlatformAccessibilitySettings.fromMap({
          'isScreenReaderEnabled': true,
          'isHighContrastEnabled': true,
          'isBoldTextEnabled': true,
          'isReduceMotionEnabled': true,
          'textScaleFactor': 1.5,
        });

        expect(settings.isScreenReaderEnabled, true);
        expect(settings.isHighContrastEnabled, true);
        expect(settings.isBoldTextEnabled, true);
        expect(settings.isReduceMotionEnabled, true);
        expect(settings.textScaleFactor, 1.5);
      });

      test('fromMap handles missing values', () {
        final settings = PlatformAccessibilitySettings.fromMap({});

        expect(settings.isScreenReaderEnabled, false);
        expect(settings.isHighContrastEnabled, false);
        expect(settings.isBoldTextEnabled, false);
        expect(settings.isReduceMotionEnabled, false);
        expect(settings.textScaleFactor, 1.0);
      });
    });

    test('getPlatformAccessibilitySettings handles errors gracefully', () async {
      // This test verifies that the method doesn't throw
      expect(() async {
        await AccessibilityService.getPlatformAccessibilitySettings();
      }, returnsNormally);
    });
  });
}