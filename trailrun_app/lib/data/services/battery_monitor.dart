import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Battery monitoring service for tracking power consumption during activities
class BatteryMonitor {
  static final BatteryMonitor _instance = BatteryMonitor._internal();
  factory BatteryMonitor() => _instance;
  BatteryMonitor._internal();

  // Platform channel for battery info
  static const MethodChannel _channel = MethodChannel('com.trailrun.battery');

  // Monitoring state
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  
  // Battery data
  final List<BatteryReading> _readings = [];
  BatteryReading? _lastReading;
  BatteryReading? _sessionStartReading;
  
  // Stream controllers
  final StreamController<BatteryReading> _batteryController = 
      StreamController<BatteryReading>.broadcast();
  final StreamController<BatteryUsageStats> _statsController = 
      StreamController<BatteryUsageStats>.broadcast();

  // Configuration
  Duration _monitoringInterval = const Duration(minutes: 1);
  int _maxReadings = 1440; // 24 hours at 1-minute intervals

  /// Stream of battery readings
  Stream<BatteryReading> get batteryStream => _batteryController.stream;
  
  /// Stream of battery usage statistics
  Stream<BatteryUsageStats> get statsStream => _statsController.stream;

  /// Start battery monitoring
  Future<void> startMonitoring({
    Duration interval = const Duration(minutes: 1),
  }) async {
    if (_isMonitoring) return;

    _monitoringInterval = interval;
    _isMonitoring = true;
    
    // Take initial reading
    final initialReading = await _takeBatteryReading();
    if (initialReading != null) {
      _sessionStartReading = initialReading;
      _lastReading = initialReading;
      _readings.add(initialReading);
      _batteryController.add(initialReading);
    }

    // Start periodic monitoring
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) async {
      await _takeBatteryReadingAndUpdate();
    });

    debugPrint('BatteryMonitor: Started monitoring with ${interval.inMinutes}min interval');
  }

  /// Stop battery monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    debugPrint('BatteryMonitor: Stopped monitoring');
  }

  /// Get current battery level
  Future<int?> getCurrentBatteryLevel() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _channel.invokeMethod<int>('getBatteryLevel');
      }
      return null;
    } catch (e) {
      debugPrint('BatteryMonitor: Failed to get battery level: $e');
      return null;
    }
  }

  /// Get battery charging state
  Future<bool?> isCharging() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _channel.invokeMethod<bool>('isCharging');
      }
      return null;
    } catch (e) {
      debugPrint('BatteryMonitor: Failed to get charging state: $e');
      return null;
    }
  }

  /// Get battery temperature (Android only)
  Future<double?> getBatteryTemperature() async {
    try {
      if (Platform.isAndroid) {
        final temp = await _channel.invokeMethod<int>('getBatteryTemperature');
        return temp != null ? temp / 10.0 : null; // Convert from tenths of degrees
      }
      return null;
    } catch (e) {
      debugPrint('BatteryMonitor: Failed to get battery temperature: $e');
      return null;
    }
  }

  /// Get current session battery usage statistics
  BatteryUsageStats? getCurrentSessionStats() {
    if (_sessionStartReading == null || _lastReading == null) return null;

    final duration = _lastReading!.timestamp.difference(_sessionStartReading!.timestamp);
    final batteryUsed = _sessionStartReading!.level - _lastReading!.level;
    
    return BatteryUsageStats(
      sessionDuration: duration,
      batteryUsedPercent: batteryUsed,
      averageUsagePerHour: duration.inHours > 0 ? batteryUsed / duration.inHours : 0.0,
      readings: List.from(_readings),
      startLevel: _sessionStartReading!.level,
      currentLevel: _lastReading!.level,
      isCharging: _lastReading!.isCharging,
      temperature: _lastReading!.temperature,
    );
  }

  /// Get battery usage prediction
  BatteryUsagePrediction? predictBatteryUsage(Duration activityDuration) {
    final stats = getCurrentSessionStats();
    if (stats == null || stats.averageUsagePerHour <= 0) return null;

    final currentLevel = _lastReading?.level ?? 100;
    final predictedUsage = stats.averageUsagePerHour * activityDuration.inHours;
    final predictedRemainingLevel = currentLevel - predictedUsage;
    
    final canCompleteActivity = predictedRemainingLevel > 10; // 10% safety margin
    final timeUntilLowBattery = currentLevel > 20 
        ? Duration(hours: ((currentLevel - 20) / stats.averageUsagePerHour).round())
        : Duration.zero;

    return BatteryUsagePrediction(
      currentLevel: currentLevel,
      predictedUsage: predictedUsage,
      predictedRemainingLevel: predictedRemainingLevel.clamp(0, 100),
      canCompleteActivity: canCompleteActivity,
      timeUntilLowBattery: timeUntilLowBattery,
      usageRate: stats.averageUsagePerHour,
    );
  }

  /// Take a battery reading and update streams
  Future<void> _takeBatteryReadingAndUpdate() async {
    final reading = await _takeBatteryReading();
    if (reading != null) {
      _readings.add(reading);
      _lastReading = reading;

      // Limit readings to prevent memory issues
      while (_readings.length > _maxReadings) {
        _readings.removeAt(0);
      }

      _batteryController.add(reading);

      // Update statistics
      final stats = getCurrentSessionStats();
      if (stats != null) {
        _statsController.add(stats);
      }
    }
  }

  /// Take a single battery reading
  Future<BatteryReading?> _takeBatteryReading() async {
    try {
      final level = await getCurrentBatteryLevel();
      final charging = await isCharging();
      final temperature = await getBatteryTemperature();

      if (level != null) {
        return BatteryReading(
          timestamp: DateTime.now(),
          level: level,
          isCharging: charging ?? false,
          temperature: temperature,
        );
      }
    } catch (e) {
      debugPrint('BatteryMonitor: Failed to take battery reading: $e');
    }
    return null;
  }

  /// Clear session data
  void clearSession() {
    _readings.clear();
    _sessionStartReading = null;
    _lastReading = null;
  }

  /// Get all readings
  List<BatteryReading> get readings => List.unmodifiable(_readings);

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _batteryController.close();
    _statsController.close();
    _readings.clear();
  }
}

/// Single battery reading
class BatteryReading {
  const BatteryReading({
    required this.timestamp,
    required this.level,
    required this.isCharging,
    this.temperature,
  });

  final DateTime timestamp;
  final int level; // 0-100
  final bool isCharging;
  final double? temperature; // Celsius

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level,
    'isCharging': isCharging,
    'temperature': temperature,
  };

  factory BatteryReading.fromJson(Map<String, dynamic> json) => BatteryReading(
    timestamp: DateTime.parse(json['timestamp']),
    level: json['level'],
    isCharging: json['isCharging'],
    temperature: json['temperature']?.toDouble(),
  );
}

/// Battery usage statistics for a session
class BatteryUsageStats {
  const BatteryUsageStats({
    required this.sessionDuration,
    required this.batteryUsedPercent,
    required this.averageUsagePerHour,
    required this.readings,
    required this.startLevel,
    required this.currentLevel,
    required this.isCharging,
    this.temperature,
  });

  final Duration sessionDuration;
  final int batteryUsedPercent;
  final double averageUsagePerHour;
  final List<BatteryReading> readings;
  final int startLevel;
  final int currentLevel;
  final bool isCharging;
  final double? temperature;

  /// Get efficiency rating (lower usage per hour is better)
  BatteryEfficiency get efficiency {
    if (averageUsagePerHour <= 5) return BatteryEfficiency.excellent;
    if (averageUsagePerHour <= 10) return BatteryEfficiency.good;
    if (averageUsagePerHour <= 20) return BatteryEfficiency.fair;
    return BatteryEfficiency.poor;
  }

  Map<String, dynamic> toJson() => {
    'sessionDuration': sessionDuration.inMilliseconds,
    'batteryUsedPercent': batteryUsedPercent,
    'averageUsagePerHour': averageUsagePerHour,
    'startLevel': startLevel,
    'currentLevel': currentLevel,
    'isCharging': isCharging,
    'temperature': temperature,
    'readings': readings.map((r) => r.toJson()).toList(),
  };
}

/// Battery usage prediction
class BatteryUsagePrediction {
  const BatteryUsagePrediction({
    required this.currentLevel,
    required this.predictedUsage,
    required this.predictedRemainingLevel,
    required this.canCompleteActivity,
    required this.timeUntilLowBattery,
    required this.usageRate,
  });

  final int currentLevel;
  final double predictedUsage;
  final double predictedRemainingLevel;
  final bool canCompleteActivity;
  final Duration timeUntilLowBattery;
  final double usageRate; // Percent per hour
}

/// Battery efficiency levels
enum BatteryEfficiency {
  excellent, // <= 5% per hour
  good,      // <= 10% per hour
  fair,      // <= 20% per hour
  poor,      // > 20% per hour
}