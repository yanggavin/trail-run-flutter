import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/activity.dart';
import '../../domain/enums/privacy_level.dart';
import '../screens/activity_summary_screen.dart';

/// Rich preview card for displaying activity in list
class ActivityPreviewCard extends StatelessWidget {
  const ActivityPreviewCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onDelete,
  });

  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _navigateToSummary(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildPrivacyIcon(colorScheme),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    _buildMenuButton(context),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Date and time
              Text(
                _formatDateTime(activity.startTime.dateTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.straighten,
                    label: _formatDistance(activity.distance.kilometers),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    icon: Icons.timer,
                    label: _formatDuration(activity.duration ?? Duration.zero),
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 16),
                  if (activity.averagePace != null)
                    _buildStatItem(
                      icon: Icons.speed,
                      label: _formatPace(activity.averagePace!),
                      color: colorScheme.tertiary,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Secondary stats row
              Row(
                children: [
                  if (activity.elevationGain.meters > 0) ...[
                    _buildStatItem(
                      icon: Icons.trending_up,
                      label: '${activity.elevationGain.meters.round()}m ↗',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (activity.photos.isNotEmpty) ...[
                    _buildStatItem(
                      icon: Icons.photo_camera,
                      label: '${activity.photos.length}',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (activity.splits.isNotEmpty)
                    _buildStatItem(
                      icon: Icons.flag,
                      label: '${activity.splits.length} splits',
                      color: Colors.purple,
                    ),
                ],
              ),
              
              // Notes preview (if available)
              if (activity.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activity.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyIcon(ColorScheme colorScheme) {
    IconData icon;
    Color color;
    
    switch (activity.privacy) {
      case PrivacyLevel.private:
        icon = Icons.lock;
        color = colorScheme.error;
        break;
      case PrivacyLevel.friends:
        icon = Icons.group;
        color = colorScheme.primary;
        break;
      case PrivacyLevel.public:
        icon = Icons.public;
        color = colorScheme.secondary;
        break;
    }
    
    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'delete':
            _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToSummary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivitySummaryScreen(activity: activity),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${DateFormat.Hm().format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat.Hm().format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat.E().add_Hm().format(dateTime);
    } else {
      return DateFormat.yMd().add_Hm().format(dateTime);
    }
  }

  String _formatDistance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).round()}m';
    } else {
      return '${kilometers.toStringAsFixed(1)}km';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatPace(dynamic pace) {
    // Handle both Pace object and direct seconds
    final secondsPerKm = pace is num ? pace : pace.secondsPerKilometer;
    final minutes = (secondsPerKm / 60).floor();
    final seconds = (secondsPerKm % 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}/km';
  }
}