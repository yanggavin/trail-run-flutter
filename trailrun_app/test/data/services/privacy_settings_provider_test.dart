import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/data/services/privacy_settings_provider.dart';
import '../../../lib/data/services/privacy_service.dart';
import '../../../lib/domain/enums/privacy_level.dart';

@GenerateMocks([SharedPreferences])
import 'privacy_settings_provider_test.mocks.dart';

void main() {
  group('PrivacySettingsProvider', () {
    late MockSharedPreferences mockPrefs;
    late ProviderContainer container;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      
      // Mock SharedPreferences.getInstance()
      SharedPreferences.setMockInitialValues({});
      
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('PrivacySettingsNotifier', () {
      test('should initialize with default privacy settings', () {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        
        final notifier = PrivacySettingsNotifier();
        final state = notifier.state;

        expect(state.privacyLevel, equals(PrivacyLevel.private));
        expect(state.stripExifData, isTrue);
        expect(state.shareLocation, isFalse);
        expect(state.sharePhotos, isTrue);
        expect(state.shareStats, isTrue);
      });

      test('should load settings from SharedPreferences', () async {
        final settingsJson = jsonEncode({
          'privacyLevel': 'public',
          'stripExifData': false,
          'shareLocation': true,
          'sharePhotos': false,
          'shareStats': true,
        });

        when(mockPrefs.getString('privacy_settings')).thenReturn(settingsJson);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        // Wait for settings to load
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.privacyLevel, equals(PrivacyLevel.public));
        expect(notifier.state.stripExifData, isFalse);
        expect(notifier.state.shareLocation, isTrue);
        expect(notifier.state.sharePhotos, isFalse);
        expect(notifier.state.shareStats, isTrue);
      });

      test('should update privacy level and save to preferences', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        await notifier.updatePrivacyLevel(PrivacyLevel.friends);

        expect(notifier.state.privacyLevel, equals(PrivacyLevel.friends));
        verify(mockPrefs.setString('privacy_settings', any)).called(1);
      });

      test('should update EXIF stripping setting', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        await notifier.updateStripExifData(false);

        expect(notifier.state.stripExifData, isFalse);
      });

      test('should update location sharing setting', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        await notifier.updateShareLocation(true);

        expect(notifier.state.shareLocation, isTrue);
      });

      test('should update photo sharing setting', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        await notifier.updateSharePhotos(false);

        expect(notifier.state.sharePhotos, isFalse);
      });

      test('should update stats sharing setting', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        await notifier.updateShareStats(false);

        expect(notifier.state.shareStats, isFalse);
      });

      test('should reset to default settings', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        // Change some settings first
        await notifier.updatePrivacyLevel(PrivacyLevel.public);
        await notifier.updateStripExifData(false);
        await notifier.updateShareLocation(true);

        // Reset to defaults
        await notifier.resetToDefaults();

        expect(notifier.state.privacyLevel, equals(PrivacyLevel.private));
        expect(notifier.state.stripExifData, isTrue);
        expect(notifier.state.shareLocation, isFalse);
        expect(notifier.state.sharePhotos, isTrue);
        expect(notifier.state.shareStats, isTrue);
      });

      test('should update all settings at once', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final notifier = PrivacySettingsNotifier();
        
        const newSettings = PrivacySettings(
          privacyLevel: PrivacyLevel.friends,
          stripExifData: false,
          shareLocation: true,
          sharePhotos: false,
          shareStats: false,
        );

        await notifier.updateSettings(newSettings);

        expect(notifier.state.privacyLevel, equals(PrivacyLevel.friends));
        expect(notifier.state.stripExifData, isFalse);
        expect(notifier.state.shareLocation, isTrue);
        expect(notifier.state.sharePhotos, isFalse);
        expect(notifier.state.shareStats, isFalse);
      });

      test('should handle SharedPreferences errors gracefully', () async {
        when(mockPrefs.getString('privacy_settings'))
            .thenThrow(Exception('SharedPreferences error'));

        final notifier = PrivacySettingsNotifier();
        
        // Should still have default settings despite error
        expect(notifier.state.privacyLevel, equals(PrivacyLevel.private));
        expect(notifier.state.stripExifData, isTrue);
      });

      test('should handle invalid JSON in SharedPreferences', () async {
        when(mockPrefs.getString('privacy_settings')).thenReturn('invalid json');

        final notifier = PrivacySettingsNotifier();
        
        // Should still have default settings despite invalid JSON
        expect(notifier.state.privacyLevel, equals(PrivacyLevel.private));
        expect(notifier.state.stripExifData, isTrue);
      });
    });

    group('Provider Integration', () {
      test('should provide privacy settings through Riverpod', () {
        final settings = container.read(privacySettingsProvider);

        expect(settings.privacyLevel, equals(PrivacyLevel.private));
        expect(settings.stripExifData, isTrue);
        expect(settings.shareLocation, isFalse);
      });

      test('should notify listeners when settings change', () async {
        var notificationCount = 0;
        
        container.listen(
          privacySettingsProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final notifier = container.read(privacySettingsProvider.notifier);
        await notifier.updatePrivacyLevel(PrivacyLevel.public);

        expect(notificationCount, equals(1));
        expect(
          container.read(privacySettingsProvider).privacyLevel,
          equals(PrivacyLevel.public),
        );
      });

      test('should maintain state across multiple reads', () async {
        final notifier = container.read(privacySettingsProvider.notifier);
        await notifier.updatePrivacyLevel(PrivacyLevel.friends);

        final settings1 = container.read(privacySettingsProvider);
        final settings2 = container.read(privacySettingsProvider);

        expect(settings1.privacyLevel, equals(PrivacyLevel.friends));
        expect(settings2.privacyLevel, equals(PrivacyLevel.friends));
        expect(identical(settings1, settings2), isTrue);
      });
    });

    group('PrivacySettings Model', () {
      test('should create with required parameters', () {
        const settings = PrivacySettings(
          privacyLevel: PrivacyLevel.public,
        );

        expect(settings.privacyLevel, equals(PrivacyLevel.public));
        expect(settings.stripExifData, isTrue); // Default
        expect(settings.shareLocation, isFalse); // Default
        expect(settings.sharePhotos, isTrue); // Default
        expect(settings.shareStats, isTrue); // Default
      });

      test('should create with all parameters', () {
        const settings = PrivacySettings(
          privacyLevel: PrivacyLevel.friends,
          stripExifData: false,
          shareLocation: true,
          sharePhotos: false,
          shareStats: false,
        );

        expect(settings.privacyLevel, equals(PrivacyLevel.friends));
        expect(settings.stripExifData, isFalse);
        expect(settings.shareLocation, isTrue);
        expect(settings.sharePhotos, isFalse);
        expect(settings.shareStats, isFalse);
      });

      test('should copy with changes', () {
        const original = PrivacySettings(
          privacyLevel: PrivacyLevel.private,
          stripExifData: true,
          shareLocation: false,
        );

        final updated = original.copyWith(
          privacyLevel: PrivacyLevel.public,
          shareLocation: true,
        );

        expect(updated.privacyLevel, equals(PrivacyLevel.public));
        expect(updated.stripExifData, isTrue); // Unchanged
        expect(updated.shareLocation, isTrue); // Changed
        expect(updated.sharePhotos, equals(original.sharePhotos)); // Unchanged
      });

      test('should serialize to JSON correctly', () {
        const settings = PrivacySettings(
          privacyLevel: PrivacyLevel.friends,
          stripExifData: false,
          shareLocation: true,
          sharePhotos: false,
          shareStats: true,
        );

        final json = settings.toJson();

        expect(json['privacyLevel'], equals('friends'));
        expect(json['stripExifData'], isFalse);
        expect(json['shareLocation'], isTrue);
        expect(json['sharePhotos'], isFalse);
        expect(json['shareStats'], isTrue);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'privacyLevel': 'public',
          'stripExifData': false,
          'shareLocation': true,
          'sharePhotos': false,
          'shareStats': true,
        };

        final settings = PrivacySettings.fromJson(json);

        expect(settings.privacyLevel, equals(PrivacyLevel.public));
        expect(settings.stripExifData, isFalse);
        expect(settings.shareLocation, isTrue);
        expect(settings.sharePhotos, isFalse);
        expect(settings.shareStats, isTrue);
      });

      test('should handle invalid privacy level in JSON', () {
        final json = {
          'privacyLevel': 'invalid_level',
          'stripExifData': true,
        };

        final settings = PrivacySettings.fromJson(json);

        expect(settings.privacyLevel, equals(PrivacyLevel.private)); // Default fallback
        expect(settings.stripExifData, isTrue);
      });

      test('should handle missing fields in JSON', () {
        final json = {
          'privacyLevel': 'public',
          // Missing other fields
        };

        final settings = PrivacySettings.fromJson(json);

        expect(settings.privacyLevel, equals(PrivacyLevel.public));
        expect(settings.stripExifData, isTrue); // Default
        expect(settings.shareLocation, isFalse); // Default
        expect(settings.sharePhotos, isTrue); // Default
        expect(settings.shareStats, isTrue); // Default
      });
    });
  });
}