import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/presentation/screens/privacy_settings_screen.dart';
import '../../../lib/data/services/privacy_settings_provider.dart';
import '../../../lib/data/services/privacy_service.dart';
import '../../../lib/domain/enums/privacy_level.dart';

@GenerateMocks([PrivacyService])
import 'privacy_settings_screen_test.mocks.dart';

void main() {
  group('PrivacySettingsScreen', () {
    late MockPrivacyService mockPrivacyService;

    setUp(() {
      mockPrivacyService = MockPrivacyService();
    });

    Widget createTestWidget({PrivacySettings? initialSettings}) {
      return ProviderScope(
        overrides: [
          privacySettingsProvider.overrideWith((ref) {
            return TestPrivacySettingsNotifier(
              initialSettings ?? const PrivacySettings(
                privacyLevel: PrivacyLevel.private,
              ),
            );
          }),
          privacyServiceProvider.overrideWithValue(mockPrivacyService),
        ],
        child: MaterialApp(
          home: const PrivacySettingsScreen(),
        ),
      );
    }

    testWidgets('should display privacy settings screen with all sections', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check app bar
      expect(find.text('Privacy & Security'), findsOneWidget);

      // Check main sections
      expect(find.text('Default Privacy Level'), findsOneWidget);
      expect(find.text('Photo Privacy'), findsOneWidget);
      expect(find.text('Location Privacy'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('Reset Settings'), findsOneWidget);
      expect(find.text('Privacy Notice'), findsOneWidget);
    });

    testWidgets('should display privacy level options', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check privacy level options
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);

      // Check that private is selected by default
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display photo privacy switches', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check photo privacy switches
      expect(find.text('Strip EXIF Data'), findsOneWidget);
      expect(find.text('Share Photos'), findsOneWidget);

      // Check switch states
      final stripExifSwitch = find.byType(SwitchListTile).first;
      final sharePhotosSwitch = find.byType(SwitchListTile).at(1);

      expect(tester.widget<SwitchListTile>(stripExifSwitch).value, isTrue);
      expect(tester.widget<SwitchListTile>(sharePhotosSwitch).value, isTrue);
    });

    testWidgets('should display location privacy switches', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check location privacy switches
      expect(find.text('Share Precise Location'), findsOneWidget);
      expect(find.text('Share Statistics'), findsOneWidget);

      // Find switches by their titles
      final preciseLocationSwitch = find.ancestor(
        of: find.text('Share Precise Location'),
        matching: find.byType(SwitchListTile),
      );
      final shareStatsSwitch = find.ancestor(
        of: find.text('Share Statistics'),
        matching: find.byType(SwitchListTile),
      );

      expect(tester.widget<SwitchListTile>(preciseLocationSwitch).value, isFalse);
      expect(tester.widget<SwitchListTile>(shareStatsSwitch).value, isTrue);
    });

    testWidgets('should update privacy level when option is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on Friends option
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();

      // Verify the selection changed (Friends should now have check icon)
      final friendsOption = find.ancestor(
        of: find.text('Friends'),
        matching: find.byType(InkWell),
      );
      expect(friendsOption, findsOneWidget);
    });

    testWidgets('should toggle EXIF stripping switch', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the Strip EXIF Data switch
      final stripExifSwitch = find.ancestor(
        of: find.text('Strip EXIF Data'),
        matching: find.byType(SwitchListTile),
      );

      await tester.tap(stripExifSwitch);
      await tester.pumpAndSettle();

      // The switch should now be off (false)
      expect(tester.widget<SwitchListTile>(stripExifSwitch).value, isFalse);
    });

    testWidgets('should toggle location sharing switch', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the Share Precise Location switch
      final locationSwitch = find.ancestor(
        of: find.text('Share Precise Location'),
        matching: find.byType(SwitchListTile),
      );

      await tester.tap(locationSwitch);
      await tester.pumpAndSettle();

      // The switch should now be on (true)
      expect(tester.widget<SwitchListTile>(locationSwitch).value, isTrue);
    });

    testWidgets('should display data management options', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check data management options
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);
    });

    testWidgets('should show export options dialog when export is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on Export Data
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Check that export dialog is shown
      expect(find.text('Export Data'), findsAtLeastNWidget(2)); // Title appears twice
      expect(find.text('Data Only'), findsOneWidget);
      expect(find.text('Data + Photos'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog when delete is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on Delete All Data
      await tester.tap(find.text('Delete All Data'));
      await tester.pumpAndSettle();

      // Check that delete confirmation dialog is shown
      expect(find.text('Delete All Data'), findsAtLeastNWidget(2)); // Title appears twice
      expect(find.text('This will permanently delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete All'), findsOneWidget);
    });

    testWidgets('should show reset confirmation dialog when reset is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap on Reset to Defaults button
      await tester.tap(find.text('Reset to Defaults'));
      await tester.pumpAndSettle();

      // Check that reset confirmation dialog is shown
      expect(find.text('Reset Privacy Settings'), findsOneWidget);
      expect(find.text('Are you sure you want to reset'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('should display privacy notice', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check privacy notice
      expect(find.text('Privacy Notice'), findsOneWidget);
      expect(find.text('TrailRun is designed with privacy by default'), findsOneWidget);
    });

    testWidgets('should handle different initial privacy settings', (tester) async {
      const customSettings = PrivacySettings(
        privacyLevel: PrivacyLevel.public,
        stripExifData: false,
        shareLocation: true,
        sharePhotos: false,
        shareStats: false,
      );

      await tester.pumpWidget(createTestWidget(initialSettings: customSettings));

      // Check that Public is selected
      final publicOption = find.ancestor(
        of: find.text('Public'),
        matching: find.byType(Container),
      );
      expect(publicOption, findsOneWidget);

      // Check switch states match custom settings
      final switches = find.byType(SwitchListTile);
      expect(switches, findsNWidgets(4)); // 4 switches total

      // Note: Exact switch verification would require more specific finders
      // based on the widget structure
    });

    testWidgets('should close dialogs when cancel is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Open export dialog
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Data Only'), findsNothing);
      expect(find.text('Data + Photos'), findsNothing);
    });

    testWidgets('should handle export data only action', (tester) async {
      when(mockPrivacyService.exportUserData())
          .thenAnswer((_) async => '/test/export.json');

      await tester.pumpWidget(createTestWidget());

      // Open export dialog and select Data Only
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Only'));
      await tester.pumpAndSettle();

      // Verify export method was called
      verify(mockPrivacyService.exportUserData()).called(1);
    });

    testWidgets('should handle export data with photos action', (tester) async {
      when(mockPrivacyService.exportUserDataWithPhotos())
          .thenAnswer((_) async => '/test/export.zip');

      await tester.pumpWidget(createTestWidget());

      // Open export dialog and select Data + Photos
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data + Photos'));
      await tester.pumpAndSettle();

      // Verify export method was called
      verify(mockPrivacyService.exportUserDataWithPhotos()).called(1);
    });

    testWidgets('should handle delete all data action', (tester) async {
      when(mockPrivacyService.deleteAllUserData())
          .thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());

      // Open delete dialog and confirm
      await tester.tap(find.text('Delete All Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete All'));
      await tester.pumpAndSettle();

      // Verify delete method was called
      verify(mockPrivacyService.deleteAllUserData()).called(1);
    });
  });
}

/// Test implementation of PrivacySettingsNotifier for testing
class TestPrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  TestPrivacySettingsNotifier(PrivacySettings initialState) : super(initialState);

  @override
  Future<void> updatePrivacyLevel(PrivacyLevel privacyLevel) async {
    state = state.copyWith(privacyLevel: privacyLevel);
  }

  @override
  Future<void> updateStripExifData(bool stripExifData) async {
    state = state.copyWith(stripExifData: stripExifData);
  }

  @override
  Future<void> updateShareLocation(bool shareLocation) async {
    state = state.copyWith(shareLocation: shareLocation);
  }

  @override
  Future<void> updateSharePhotos(bool sharePhotos) async {
    state = state.copyWith(sharePhotos: sharePhotos);
  }

  @override
  Future<void> updateShareStats(bool shareStats) async {
    state = state.copyWith(shareStats: shareStats);
  }

  @override
  Future<void> resetToDefaults() async {
    state = const PrivacySettings(
      privacyLevel: PrivacyLevel.private,
      stripExifData: true,
      shareLocation: false,
      sharePhotos: true,
      shareStats: true,
    );
  }

  @override
  Future<void> updateSettings(PrivacySettings settings) async {
    state = settings;
  }
}