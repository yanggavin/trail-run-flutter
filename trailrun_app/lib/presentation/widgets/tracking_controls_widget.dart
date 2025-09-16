import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/activity_tracking_provider.dart';

/// Widget for tracking control buttons (start, pause, resume, stop)
class TrackingControlsWidget extends StatelessWidget {
  const TrackingControlsWidget({
    super.key,
    required this.trackingState,
    required this.onStartPressed,
    required this.onPausePressed,
    required this.onResumePressed,
    required this.onStopPressed,
  });

  final ActivityTrackingState trackingState;
  final VoidCallback onStartPressed;
  final VoidCallback onPausePressed;
  final VoidCallback onResumePressed;
  final VoidCallback onStopPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action button
          _buildPrimaryButton(),
          
          const SizedBox(height: 16),
          
          // Secondary actions
          if (trackingState.isTracking) _buildSecondaryActions(),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    if (trackingState.canStart) {
      return _buildStartButton();
    } else if (trackingState.canPause) {
      return _buildPauseButton();
    } else if (trackingState.canResume) {
      return _buildResumeButton();
    } else {
      return _buildDisabledButton();
    }
  }

  Widget _buildStartButton() {
    return _buildControlButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onStartPressed();
      },
      icon: Icons.play_arrow,
      label: 'START',
      color: Colors.green,
      size: _ControlButtonSize.large,
    );
  }

  Widget _buildPauseButton() {
    return _buildControlButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onPausePressed();
      },
      icon: Icons.pause,
      label: 'PAUSE',
      color: Colors.orange,
      size: _ControlButtonSize.large,
    );
  }

  Widget _buildResumeButton() {
    return _buildControlButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onResumePressed();
      },
      icon: Icons.play_arrow,
      label: 'RESUME',
      color: Colors.green,
      size: _ControlButtonSize.large,
    );
  }

  Widget _buildDisabledButton() {
    return _buildControlButton(
      onPressed: null,
      icon: Icons.hourglass_empty,
      label: 'LOADING',
      color: Colors.grey,
      size: _ControlButtonSize.large,
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Stop button
        _buildControlButton(
          onPressed: trackingState.canStop ? () {
            HapticFeedback.heavyImpact();
            _showStopConfirmation();
          } : null,
          icon: Icons.stop,
          label: 'STOP',
          color: Colors.red,
          size: _ControlButtonSize.small,
        ),
        
        // Auto-pause toggle (if supported)
        if (trackingState.isTracking && !trackingState.isPaused)
          _buildAutoPauseToggle(),
      ],
    );
  }

  Widget _buildAutoPauseToggle() {
    return _buildControlButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        // TODO: Toggle auto-pause setting
      },
      icon: trackingState.isAutopaused ? Icons.pause_circle : Icons.pause_circle_outline,
      label: 'AUTO',
      color: trackingState.isAutopaused ? Colors.blue : Colors.grey,
      size: _ControlButtonSize.small,
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required _ControlButtonSize size,
  }) {
    final isLarge = size == _ControlButtonSize.large;
    final buttonSize = isLarge ? 80.0 : 60.0;
    final iconSize = isLarge ? 32.0 : 24.0;
    final fontSize = isLarge ? 16.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null ? color : Colors.grey.shade600,
            boxShadow: onPressed != null ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.grey,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  void _showStopConfirmation() {
    // This would typically be handled by the parent widget
    // For now, just call the stop callback directly
    onStopPressed();
  }
}

enum _ControlButtonSize { small, large }