import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'activity_tracking_service.dart';

class AutoPauseSettings {
  const AutoPauseSettings({
    required this.enabled,
    required this.speedThreshold,
    required this.timeThreshold,
    required this.resumeSpeedThreshold,
  });

  final bool enabled;
  final double speedThreshold;
  final Duration timeThreshold;
  final double resumeSpeedThreshold;

  static const AutoPauseSettings defaults = AutoPauseSettings(
    enabled: true,
    speedThreshold: 0.5,
    timeThreshold: Duration(seconds: 10),
    resumeSpeedThreshold: 1.0,
  );

  AutoPauseSettings copyWith({
    bool? enabled,
    double? speedThreshold,
    Duration? timeThreshold,
    double? resumeSpeedThreshold,
  }) {
    return AutoPauseSettings(
      enabled: enabled ?? this.enabled,
      speedThreshold: speedThreshold ?? this.speedThreshold,
      timeThreshold: timeThreshold ?? this.timeThreshold,
      resumeSpeedThreshold: resumeSpeedThreshold ?? this.resumeSpeedThreshold,
    );
  }

  AutoPauseConfig toConfig() {
    return AutoPauseConfig(
      enabled: enabled,
      speedThreshold: speedThreshold,
      timeThreshold: timeThreshold,
      resumeSpeedThreshold: resumeSpeedThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'speedThreshold': speedThreshold,
      'timeThresholdSeconds': timeThreshold.inSeconds,
      'resumeSpeedThreshold': resumeSpeedThreshold,
    };
  }

  factory AutoPauseSettings.fromJson(Map<String, dynamic> json) {
    return AutoPauseSettings(
      enabled: json['enabled'] as bool? ?? defaults.enabled,
      speedThreshold: (json['speedThreshold'] as num?)?.toDouble() ?? defaults.speedThreshold,
      timeThreshold: Duration(seconds: json['timeThresholdSeconds'] as int? ?? defaults.timeThreshold.inSeconds),
      resumeSpeedThreshold: (json['resumeSpeedThreshold'] as num?)?.toDouble() ?? defaults.resumeSpeedThreshold,
    );
  }
}

class AutoPauseSettingsService {
  static const String _prefsKey = 'auto_pause_settings';

  static Future<AutoPauseSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return AutoPauseSettings.defaults;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return AutoPauseSettings.fromJson(data);
    } catch (_) {
      return AutoPauseSettings.defaults;
    }
  }

  static Future<void> save(AutoPauseSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
  }
}
