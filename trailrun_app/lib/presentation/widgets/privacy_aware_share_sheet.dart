import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/activity.dart';
import '../../domain/enums/privacy_level.dart';
import '../../data/services/privacy_settings_provider.dart';
import '../../data/services/privacy_service.dart';
import 'privacy_level_selector.dart';

/// Privacy-aware share sheet that respects user privacy settings
class PrivacyAwareShareSheet extends ConsumerStatefulWidget {
  final Activity activity;
  final VoidCallback? onShare;

  const PrivacyAwareShareSheet({
    super.key,
    required this.activity,
    this.onShare,
  });

  @override
  ConsumerState<PrivacyAwareShareSheet> createState() => _PrivacyAwareShareSheetState();
}

class _PrivacyAwareShareSheetState extends ConsumerState<PrivacyAwareShareSheet> {
  late PrivacySettings _shareSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current privacy settings
    _shareSettings = ref.read(privacySettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Share Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Activity Preview
          _ActivityPreview(activity: widget.activity),
          
          const SizedBox(height: 24),
          
          // Privacy Level Selection
          Text(
            'Privacy Level for Sharing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how much detail to include when sharing this activity.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          PrivacyLevelSelector(
            selectedLevel: _shareSettings.privacyLevel,
            onChanged: (level) {
              setState(() {
                _shareSettings = _shareSettings.copyWith(privacyLevel: level);
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Share Options
          Text(
            'What to Include',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _ShareOption(
            icon: Icons.location_on,
            title: 'Location Data',
            subtitle: _getLocationSubtitle(),
            value: _shareSettings.shareLocation,
            onChanged: (value) {
              setState(() {
                _shareSettings = _shareSettings.copyWith(shareLocation: value);
              });
            },
          ),
          
          _ShareOption(
            icon: Icons.photo_camera,
            title: 'Photos',
            subtitle: 'Include photos taken during the activity',
            value: _shareSettings.sharePhotos,
            onChanged: (value) {
              setState(() {
                _shareSettings = _shareSettings.copyWith(sharePhotos: value);
              });
            },
          ),
          
          _ShareOption(
            icon: Icons.analytics,
            title: 'Statistics',
            subtitle: 'Include distance, pace, and elevation data',
            value: _shareSettings.shareStats,
            onChanged: (value) {
              setState(() {
                _shareSettings = _shareSettings.copyWith(shareStats: value);
              });
            },
          ),
          
          if (_shareSettings.sharePhotos) ...[
            const SizedBox(height: 8),
            _ShareOption(
              icon: Icons.security,
              title: 'Strip Photo Metadata',
              subtitle: 'Remove location and camera info from photos',
              value: _shareSettings.stripExifData,
              onChanged: (value) {
                setState(() {
                  _shareSettings = _shareSettings.copyWith(stripExifData: value);
                });
              },
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Share Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _handleShare,
              icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
              label: Text(_isLoading ? 'Preparing...' : 'Share Activity'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Privacy Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your privacy settings will be applied before sharing. You can change these defaults in Privacy Settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get location subtitle based on privacy level
  String _getLocationSubtitle() {
    switch (_shareSettings.privacyLevel) {
      case PrivacyLevel.private:
        return 'Location rounded to ~1km accuracy';
      case PrivacyLevel.friends:
        return 'Location rounded to ~100m accuracy';
      case PrivacyLevel.public:
        return 'Full location accuracy';
    }
  }

  /// Handle share action
  void _handleShare() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final privacyService = ref.read(privacyServiceProvider);
      
      // Apply privacy settings to the activity
      await privacyService.applyPrivacySettings(widget.activity.id, _shareSettings);
      
      // Call the share callback
      widget.onShare?.call();
      
      // Close the sheet
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare activity for sharing: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Activity preview widget
class _ActivityPreview extends StatelessWidget {
  final Activity activity;

  const _ActivityPreview({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.directions_run,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.distance.kilometers.toStringAsFixed(2)} km • ${_formatDuration(activity.duration ?? Duration.zero)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Individual share option widget
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
