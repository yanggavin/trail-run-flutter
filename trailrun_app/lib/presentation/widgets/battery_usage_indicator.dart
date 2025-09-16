import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Provider for battery usage monitoring
final batteryUsageProvider = StateNotifierProvider<BatteryUsageNotifier, BatteryUsageState>((ref) {
  return BatteryUsageNotifier();
});

/// Battery usage state
class BatteryUsageState {
  const BatteryUsageState({
    this.currentLevel,
    this.usageRate = 0.0,
    this.estimatedHoursRemaining,
    this.isCharging = false,
    this.isOptimized = true,
  });

  final int? currentLevel; // Battery percentage (0-100)
  final double usageRate; // Percentage per hour
  final double? estimatedHoursRemaining;
  final bool isCharging;
  final bool isOptimized; // Whether battery optimization is active

  BatteryUsageState copyWith({
    int? currentLevel,
    double? usageRate,
    double? estimatedHoursRemaining,
    bool? isCharging,
    bool? isOptimized,
  }) {
    return BatteryUsageState(
      currentLevel: currentLevel ?? this.currentLevel,
      usageRate: usageRate ?? this.usageRate,
      estimatedHoursRemaining: estimatedHoursRemaining ?? this.estimatedHoursRemaining,
      isCharging: isCharging ?? this.isCharging,
      isOptimized: isOptimized ?? this.isOptimized,
    );
  }
}

/// Battery usage notifier
class BatteryUsageNotifier extends StateNotifier<BatteryUsageState> {
  BatteryUsageNotifier() : super(const BatteryUsageState()) {
    _startMonitoring();
  }

  Timer? _monitoringTimer;
  int? _lastBatteryLevel;
  DateTime? _lastUpdateTime;

  void _startMonitoring() {
    // Simulate battery monitoring (in real app, would use battery_plus plugin)
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateBatteryInfo();
    });
    
    // Initial update
    _updateBatteryInfo();
  }

  void _updateBatteryInfo() {
    // Simulate battery data (in real app, would get from battery_plus)
    final now = DateTime.now();
    final currentLevel = _simulateBatteryLevel();
    final isCharging = _simulateChargingStatus();
    
    double usageRate = 0.0;
    double? estimatedHours;
    
    if (_lastBatteryLevel != null && _lastUpdateTime != null && !isCharging) {
      final timeDiff = now.difference(_lastUpdateTime!).inMinutes;
      final levelDiff = _lastBatteryLevel! - currentLevel;
      
      if (timeDiff > 0 && levelDiff > 0) {
        // Calculate usage rate per hour
        usageRate = (levelDiff / timeDiff) * 60;
        
        // Estimate remaining hours
        if (usageRate > 0) {
          estimatedHours = currentLevel / usageRate;
        }
      }
    }
    
    state = state.copyWith(
      currentLevel: currentLevel,
      usageRate: usageRate,
      estimatedHoursRemaining: estimatedHours,
      isCharging: isCharging,
      isOptimized: _isOptimizedForTracking(usageRate),
    );
    
    _lastBatteryLevel = currentLevel;
    _lastUpdateTime = now;
  }

  int _simulateBatteryLevel() {
    // Simulate battery level (in real app, would get from battery_plus)
    final baseLevel = 85;
    final variation = (DateTime.now().millisecondsSinceEpoch % 20) - 10;
    return (baseLevel + variation).clamp(0, 100);
  }

  bool _simulateChargingStatus() {
    // Simulate charging status (in real app, would get from battery_plus)
    return DateTime.now().second % 30 < 5; // Charging 1/6 of the time
  }

  bool _isOptimizedForTracking(double usageRate) {
    // Consider battery usage optimized if rate is below 6% per hour
    return usageRate <= 6.0;
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

/// Widget displaying battery usage information during tracking
class BatteryUsageIndicator extends ConsumerWidget {
  const BatteryUsageIndicator({
    super.key,
    this.showDetails = false,
  });

  final bool showDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryUsageProvider);

    return GestureDetector(
      onTap: showDetails ? null : () => _showBatteryDetails(context, batteryState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBatteryColor(batteryState).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBatteryColor(batteryState),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getBatteryIcon(batteryState),
              color: _getBatteryColor(batteryState),
              size: 16,
            ),
            const SizedBox(width: 4),
            if (showDetails) ...[
              _buildDetailedInfo(batteryState),
            ] else ...[
              _buildCompactInfo(batteryState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(BatteryUsageState batteryState) {
    final level = batteryState.currentLevel ?? 0;
    return Text(
      '${level}%',
      style: TextStyle(
        color: _getBatteryColor(batteryState),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDetailedInfo(BatteryUsageState batteryState) {
    final level = batteryState.currentLevel ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${level}%',
          style: TextStyle(
            color: _getBatteryColor(batteryState),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (batteryState.usageRate > 0)
          Text(
            '${batteryState.usageRate.toStringAsFixed(1)}%/h',
            style: TextStyle(
              color: _getBatteryColor(batteryState).withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        if (batteryState.estimatedHoursRemaining != null)
          Text(
            '${batteryState.estimatedHoursRemaining!.toStringAsFixed(1)}h left',
            style: TextStyle(
              color: _getBatteryColor(batteryState).withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Color _getBatteryColor(BatteryUsageState batteryState) {
    if (batteryState.isCharging) {
      return Colors.green;
    }

    final level = batteryState.currentLevel ?? 0;
    if (level <= 15) {
      return Colors.red;
    } else if (level <= 30) {
      return Colors.orange;
    } else if (!batteryState.isOptimized) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  IconData _getBatteryIcon(BatteryUsageState batteryState) {
    if (batteryState.isCharging) {
      return Icons.battery_charging_full;
    }

    final level = batteryState.currentLevel ?? 0;
    if (level <= 15) {
      return Icons.battery_alert;
    } else if (level <= 30) {
      return Icons.battery_2_bar;
    } else if (level <= 60) {
      return Icons.battery_4_bar;
    } else {
      return Icons.battery_full;
    }
  }

  void _showBatteryDetails(BuildContext context, BatteryUsageState batteryState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_std, color: Colors.green),
            SizedBox(width: 8),
            Text('Battery Usage'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBatteryDetailRow(
              'Current Level',
              '${batteryState.currentLevel ?? 0}%',
              _getBatteryColor(batteryState),
            ),
            _buildBatteryDetailRow(
              'Status',
              batteryState.isCharging ? 'Charging' : 'Discharging',
              batteryState.isCharging ? Colors.green : Colors.orange,
            ),
            if (batteryState.usageRate > 0)
              _buildBatteryDetailRow(
                'Usage Rate',
                '${batteryState.usageRate.toStringAsFixed(1)}%/hour',
                batteryState.isOptimized ? Colors.green : Colors.orange,
              ),
            if (batteryState.estimatedHoursRemaining != null)
              _buildBatteryDetailRow(
                'Estimated Time',
                '${batteryState.estimatedHoursRemaining!.toStringAsFixed(1)} hours',
                Colors.blue,
              ),
            _buildBatteryDetailRow(
              'Optimization',
              batteryState.isOptimized ? 'Optimized' : 'High Usage',
              batteryState.isOptimized ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildBatteryTips(batteryState),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryTips(BatteryUsageState batteryState) {
    final tips = <String>[];
    
    if (batteryState.currentLevel != null && batteryState.currentLevel! <= 20) {
      tips.add('• Consider charging before long runs');
    }
    
    if (!batteryState.isOptimized) {
      tips.add('• Reduce GPS accuracy to save battery');
      tips.add('• Close other apps running in background');
    }
    
    if (batteryState.usageRate > 8) {
      tips.add('• High battery usage detected');
      tips.add('• Check for background app refresh');
    }

    if (tips.isEmpty) {
      tips.add('• Battery usage is optimized for tracking');
      tips.add('• Target: 4-6% per hour during tracking');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            tip,
            style: const TextStyle(fontSize: 12),
          ),
        )),
      ],
    );
  }
}