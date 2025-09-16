import 'package:flutter/material.dart';
import '../providers/activity_tracking_provider.dart';

/// Widget displaying real-time tracking statistics
class TrackingStatsWidget extends StatelessWidget {
  const TrackingStatsWidget({
    super.key,
    required this.trackingState,
  });

  final ActivityTrackingState trackingState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary stats (large display)
          _buildPrimaryStats(),
          
          const SizedBox(height: 32),
          
          // Secondary stats (smaller display)
          _buildSecondaryStats(),
          
          const SizedBox(height: 16),
          
          // Status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildPrimaryStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Distance
        _buildStatCard(
          label: 'DISTANCE',
          value: _formatDistance(trackingState.distance),
          unit: 'km',
          color: Colors.blue,
        ),
        
        // Time
        _buildStatCard(
          label: 'TIME',
          value: _formatDuration(trackingState.elapsedTime),
          unit: '',
          color: Colors.green,
        ),
        
        // Current Pace
        _buildStatCard(
          label: 'PACE',
          value: _formatPace(trackingState.currentPace),
          unit: '/km',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSecondaryStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Average Pace
        _buildSecondaryStatItem(
          label: 'AVG PACE',
          value: _formatPace(trackingState.averagePace),
        ),
        
        // Elevation Gain
        _buildSecondaryStatItem(
          label: 'ELEVATION',
          value: '${trackingState.elevationGain.toInt()}m',
        ),
        
        // Track Points
        _buildSecondaryStatItem(
          label: 'POINTS',
          value: '${trackingState.trackPointCount}',
        ),
        
        // Photos
        _buildSecondaryStatItem(
          label: 'PHOTOS',
          value: '${trackingState.photoCount}',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryStatItem({
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (!trackingState.isTracking) {
      statusText = 'Ready to start';
      statusColor = Colors.white70;
      statusIcon = Icons.radio_button_unchecked;
    } else if (trackingState.isPaused) {
      statusText = trackingState.isAutopaused ? 'Auto-paused' : 'Paused';
      statusColor = Colors.orange;
      statusIcon = Icons.pause_circle;
    } else {
      statusText = 'Recording';
      statusColor = Colors.green;
      statusIcon = Icons.fiber_manual_record;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    final km = meters / 1000;
    if (km < 1) {
      return meters.toInt().toString();
    } else if (km < 10) {
      return km.toStringAsFixed(2);
    } else {
      return km.toStringAsFixed(1);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatPace(double secondsPerKm) {
    if (secondsPerKm <= 0 || secondsPerKm.isInfinite || secondsPerKm.isNaN) {
      return '--:--';
    }

    final minutes = (secondsPerKm / 60).floor();
    final seconds = (secondsPerKm % 60).round();

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}