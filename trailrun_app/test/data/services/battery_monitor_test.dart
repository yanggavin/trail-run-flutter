import 'package:flutter_test/flutter_test.dart';
import '../../../lib/data/services/battery_monitor.dart';

void main() {
  group('BatteryMonitor Tests', () {
    late BatteryMonitor batteryMonitor;

    setUp(() {
      batteryMonitor = BatteryMonitor();
    });

    tearDown(() {
      batteryMonitor.dispose();
    });

    test('should start and stop monitoring', () async {
      expect(batteryMonitor.isMonitoring, isFalse);
      
      await batteryMonitor.startMonitoring(interval: const Duration(milliseconds: 100));
      expect(batteryMonitor.isMonitoring, isTrue);
      
      batteryMonitor.stopMonitoring();
      expect(batteryMonitor.isMonitoring, isFalse);
    });

    test('should clear session data', () {
      batteryMonitor.clearSession();
      expect(batteryMonitor.readings.length, equals(0));
      
      final stats = batteryMonitor.getCurrentSessionStats();
      expect(stats, isNull);
    });

    test('should provide battery streams', () {
      expect(batteryMonitor.batteryStream, isNotNull);
      expect(batteryMonitor.statsStream, isNotNull);
    });

    test('should handle battery reading creation', () {
      final reading = BatteryReading(
        timestamp: DateTime.now(),
        level: 85,
        isCharging: false,
        temperature: 25.5,
      );
      
      expect(reading.level, equals(85));
      expect(reading.isCharging, isFalse);
      expect(reading.temperature, equals(25.5));
    });

    test('should serialize and deserialize battery readings', () {
      final originalReading = BatteryReading(
        timestamp: DateTime.parse('2023-01-01T12:00:00Z'),
        level: 75,
        isCharging: true,
        temperature: 30.0,
      );
      
      final json = originalReading.toJson();
      final deserializedReading = BatteryReading.fromJson(json);
      
      expect(deserializedReading.timestamp, equals(originalReading.timestamp));
      expect(deserializedReading.level, equals(originalReading.level));
      expect(deserializedReading.isCharging, equals(originalReading.isCharging));
      expect(deserializedReading.temperature, equals(originalReading.temperature));
    });
  });

  group('BatteryUsageStats Tests', () {
    test('should calculate efficiency correctly', () {
      final stats = BatteryUsageStats(
        sessionDuration: const Duration(hours: 2),
        batteryUsedPercent: 10,
        averageUsagePerHour: 5.0,
        readings: [],
        startLevel: 100,
        currentLevel: 90,
        isCharging: false,
      );
      
      expect(stats.efficiency, equals(BatteryEfficiency.excellent));
      
      final fairStats = BatteryUsageStats(
        sessionDuration: const Duration(hours: 1),
        batteryUsedPercent: 15,
        averageUsagePerHour: 15.0,
        readings: [],
        startLevel: 100,
        currentLevel: 85,
        isCharging: false,
      );
      
      expect(fairStats.efficiency, equals(BatteryEfficiency.fair));
    });

    test('should serialize battery usage stats', () {
      final reading = BatteryReading(
        timestamp: DateTime.parse('2023-01-01T12:00:00Z'),
        level: 90,
        isCharging: false,
      );
      
      final stats = BatteryUsageStats(
        sessionDuration: const Duration(hours: 1),
        batteryUsedPercent: 10,
        averageUsagePerHour: 10.0,
        readings: [reading],
        startLevel: 100,
        currentLevel: 90,
        isCharging: false,
        temperature: 25.0,
      );
      
      final json = stats.toJson();
      
      expect(json['sessionDuration'], equals(3600000)); // 1 hour in milliseconds
      expect(json['batteryUsedPercent'], equals(10));
      expect(json['averageUsagePerHour'], equals(10.0));
      expect(json['startLevel'], equals(100));
      expect(json['currentLevel'], equals(90));
      expect(json['isCharging'], isFalse);
      expect(json['temperature'], equals(25.0));
      expect(json['readings'], isA<List>());
      expect(json['readings'].length, equals(1));
    });
  });

  group('BatteryUsagePrediction Tests', () {
    test('should create prediction correctly', () {
      final prediction = BatteryUsagePrediction(
        currentLevel: 80,
        predictedUsage: 20.0,
        predictedRemainingLevel: 60.0,
        canCompleteActivity: true,
        timeUntilLowBattery: const Duration(hours: 3),
        usageRate: 10.0,
      );
      
      expect(prediction.currentLevel, equals(80));
      expect(prediction.predictedUsage, equals(20.0));
      expect(prediction.predictedRemainingLevel, equals(60.0));
      expect(prediction.canCompleteActivity, isTrue);
      expect(prediction.timeUntilLowBattery, equals(const Duration(hours: 3)));
      expect(prediction.usageRate, equals(10.0));
    });
  });

  group('BatteryEfficiency Tests', () {
    test('should have correct efficiency levels', () {
      expect(BatteryEfficiency.excellent.index, equals(0));
      expect(BatteryEfficiency.good.index, equals(1));
      expect(BatteryEfficiency.fair.index, equals(2));
      expect(BatteryEfficiency.poor.index, equals(3));
    });
  });
}