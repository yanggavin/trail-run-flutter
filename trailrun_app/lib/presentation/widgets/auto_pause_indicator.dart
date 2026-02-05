import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_router.dart';

/// Widget displaying auto-pause status and manual override controls
class AutoPauseIndicator extends StatefulWidget {
  const AutoPauseIndicator({
    super.key,
    this.onManualOverride,
    this.canOverride = true,
  });

  final VoidCallback? onManualOverride;
  final bool canOverride;

  @override
  State<AutoPauseIndicator> createState() => _AutoPauseIndicatorState();
}

class _AutoPauseIndicatorState extends State<AutoPauseIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pause_circle,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Auto-Paused',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Movement stopped - tracking paused automatically',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.canOverride) ...[
                  const SizedBox(height: 12),
                  _buildOverrideControls(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverrideControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildOverrideButton(
          icon: Icons.play_arrow,
          label: 'Resume',
          color: Colors.green,
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onManualOverride?.call();
          },
        ),
        _buildOverrideButton(
          icon: Icons.settings,
          label: 'Settings',
          color: Colors.blue,
          onPressed: () {
            HapticFeedback.selectionClick();
            _showAutoPauseSettings(context);
          },
        ),
      ],
    );
  }

  Widget _buildOverrideButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoPauseSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle, color: Colors.orange),
            SizedBox(width: 8),
            Text('Auto-Pause Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-pause automatically stops tracking when you stop moving, helping to maintain accurate activity data.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildSettingRow(
              'Sensitivity',
              'Medium',
              'Adjust when auto-pause triggers',
            ),
            _buildSettingRow(
              'Delay',
              '10 seconds',
              'Time before auto-pause activates',
            ),
            _buildSettingRow(
              'Speed Threshold',
              '1.0 km/h',
              'Minimum speed to resume tracking',
            ),
            const SizedBox(height: 16),
            const Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Auto-pause helps exclude rest stops from your activity time\n'
              '• You can manually resume tracking at any time\n'
              '• Adjust sensitivity if auto-pause is too aggressive',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppNavigator.toAutoPauseSettings(context);
            },
            child: const Text('Adjust Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
