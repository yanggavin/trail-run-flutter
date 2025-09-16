import 'package:flutter/material.dart';
import '../../domain/models/activity.dart';
import '../../domain/enums/privacy_level.dart';

/// Widget displaying key activity statistics in a card layout
class ActivityStatsWidget extends StatelessWidget {
  const ActivityStatsWidget({
    super.key,
    required this.activity,
  });

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity title and date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(activity.startTime.dateTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Privacy indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPrivacyColor(activity.privacy).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPrivacyColor(activity.privacy),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activity.privacy.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.privacy.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getPrivacyColor(activity.privacy),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Main stats grid
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${activity.distance.kilometers.toStringAsFixed(2)} km',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: _formatDuration(activity.duration),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed,
                    label: 'Avg Pace',
                    value: activity.averagePace?.formatMinutesSeconds() ?? '--:--',
                    suffix: '/km',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    label: 'Elevation',
                    value: '${activity.elevationGain.meters.toStringAsFixed(0)} m',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            // Additional stats if available
            if (activity.splits.isNotEmpty || activity.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  if (activity.splits.isNotEmpty)
                    Expanded(
                      child: _StatItem(
                        icon: Icons.timeline,
                        label: 'Splits',
                        value: '${activity.splits.length}',
                        color: Colors.teal,
                      ),
                    ),
                  if (activity.photos.isNotEmpty)
                    Expanded(
                      child: _StatItem(
                        icon: Icons.photo_camera,
                        label: 'Photos',
                        value: '${activity.photos.length}',
                        color: Colors.pink,
                      ),
                    ),
                  if (activity.splits.isNotEmpty && activity.photos.isNotEmpty)
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
            
            // Best/worst splits if available
            if (activity.splits.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.flash_on,
                      label: 'Best Split',
                      value: activity.fastestSplit?.pace.formatMinutesSeconds() ?? '--:--',
                      suffix: '/km',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.flash_off,
                      label: 'Slowest Split',
                      value: activity.slowestSplit?.pace.formatMinutesSeconds() ?? '--:--',
                      suffix: '/km',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getPrivacyColor(PrivacyLevel privacy) {
    switch (privacy) {
      case PrivacyLevel.private:
        return Colors.red;
      case PrivacyLevel.friends:
        return Colors.orange;
      case PrivacyLevel.public:
        return Colors.green;
    }
  }
}

/// Individual stat item widget
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: suffix != null
                ? [
                    TextSpan(
                      text: ' $suffix',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[600],
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}