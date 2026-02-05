import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/privacy_level.dart';
import '../database/database_provider.dart';
import 'privacy_service.dart';

/// Provider for privacy settings state management
final privacySettingsProvider = StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  return PrivacySettingsNotifier();
});

/// Provider for privacy service
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  final database = ref.watch(databaseProvider);
  return PrivacyService(database);
});

/// State notifier for privacy settings
class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  static const String _prefsKey = 'privacy_settings';
  
  PrivacySettingsNotifier({
    PrivacySettings? initialSettings,
    bool loadFromDisk = true,
  }) : super(initialSettings ?? const PrivacySettings(
    privacyLevel: PrivacyLevel.private, // Privacy by default
    stripExifData: true,
    shareLocation: false,
    sharePhotos: true,
    shareStats: true,
  )) {
    if (loadFromDisk) {
      _loadSettings();
    }
  }

  /// Load settings from persistent storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        state = PrivacySettings.fromJson(settingsMap);
      }
    } catch (e) {
      // Use default settings if loading fails
      print('Failed to load privacy settings: $e');
    }
  }

  /// Save settings to persistent storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(state.toJson());
      await prefs.setString(_prefsKey, settingsJson);
    } catch (e) {
      print('Failed to save privacy settings: $e');
    }
  }

  /// Update privacy level
  Future<void> updatePrivacyLevel(PrivacyLevel privacyLevel) async {
    state = state.copyWith(privacyLevel: privacyLevel);
    await _saveSettings();
  }

  /// Update EXIF stripping setting
  Future<void> updateStripExifData(bool stripExifData) async {
    state = state.copyWith(stripExifData: stripExifData);
    await _saveSettings();
  }

  /// Update location sharing setting
  Future<void> updateShareLocation(bool shareLocation) async {
    state = state.copyWith(shareLocation: shareLocation);
    await _saveSettings();
  }

  /// Update photo sharing setting
  Future<void> updateSharePhotos(bool sharePhotos) async {
    state = state.copyWith(sharePhotos: sharePhotos);
    await _saveSettings();
  }

  /// Update stats sharing setting
  Future<void> updateShareStats(bool shareStats) async {
    state = state.copyWith(shareStats: shareStats);
    await _saveSettings();
  }

  /// Reset to default privacy settings
  Future<void> resetToDefaults() async {
    state = const PrivacySettings(
      privacyLevel: PrivacyLevel.private,
      stripExifData: true,
      shareLocation: false,
      sharePhotos: true,
      shareStats: true,
    );
    await _saveSettings();
  }

  /// Update all settings at once
  Future<void> updateSettings(PrivacySettings settings) async {
    state = settings;
    await _saveSettings();
  }
}

/// Provider for database instance (assuming it exists elsewhere)
