import 'package:flutter/material.dart';
import '../../domain/models/activity.dart';
import '../../data/services/crash_recovery_service.dart';

/// Dialog for handling crash recovery scenarios
class CrashRecoveryDialog extends StatelessWidget {
  const CrashRecoveryDialog({
    super.key,
    required this.activity,
    required this.sessionData,
    required this.onRecover,
    required this.onDismiss,
  });

  final Activity activity;
  final Map<String, dynamic> sessionData;
  final VoidCallback onRecover;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: activity.duration.inSeconds);
    final distance = activity.distanceMeters / 1000; // Convert to km

    return AlertDialog(
      icon: const Icon(
        Icons.restore,
        color: Colors.orange,
        size: 32,
      ),
      title: const Text('Recover Previous Run?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'It looks like the app was closed during a tracking session. Would you like to recover your previous run?',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title.isNotEmpty ? activity.title : 'Untitled Run',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${distance.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Started ${_formatTime(activity.startTime)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose an option:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss();
          },
          child: const Text('Start Fresh'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showActivityDetails(context);
          },
          child: const Text('View Activity'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRecover();
          },
          child: const Text('Continue Run'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showActivityDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Title', activity.title.isNotEmpty ? activity.title : 'Untitled Run'),
            _buildDetailRow('Distance', '${(activity.distanceMeters / 1000).toStringAsFixed(2)} km'),
            _buildDetailRow('Duration', _formatDuration(Duration(seconds: activity.duration.inSeconds))),
            _buildDetailRow('Started', activity.startTime.toString()),
            if (activity.trackPoints.isNotEmpty)
              _buildDetailRow('GPS Points', '${activity.trackPoints.length}'),
            if (activity.photos.isNotEmpty)
              _buildDetailRow('Photos', '${activity.photos.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Shows a crash recovery dialog
  static Future<void> show(
    BuildContext context, {
    required Activity activity,
    required Map<String, dynamic> sessionData,
    required VoidCallback onRecover,
    required VoidCallback onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CrashRecoveryDialog(
        activity: activity,
        sessionData: sessionData,
        onRecover: onRecover,
        onDismiss: onDismiss,
      ),
    );
  }
}