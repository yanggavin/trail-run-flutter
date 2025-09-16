import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/privacy_level.dart';
import '../../data/services/privacy_settings_provider.dart';
import '../widgets/privacy_level_selector.dart';
import '../widgets/data_management_section.dart';

/// Screen for managing privacy and security settings
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacySettings = ref.watch(privacySettingsProvider);
    final privacyNotifier = ref.read(privacySettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Level Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Default Privacy Level',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the default privacy level for new activities. You can always change this for individual activities.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrivacyLevelSelector(
                    selectedLevel: privacySettings.privacyLevel,
                    onChanged: privacyNotifier.updatePrivacyLevel,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Photo Privacy Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Photo Privacy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Strip EXIF Data'),
                    subtitle: const Text(
                      'Remove location and camera information from photos when sharing'
                    ),
                    value: privacySettings.stripExifData,
                    onChanged: privacyNotifier.updateStripExifData,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text('Share Photos'),
                    subtitle: const Text(
                      'Include photos when sharing activities'
                    ),
                    value: privacySettings.sharePhotos,
                    onChanged: privacyNotifier.updateSharePhotos,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Location Privacy Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Privacy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Share Precise Location'),
                    subtitle: const Text(
                      'Share exact GPS coordinates. When disabled, location is rounded for privacy'
                    ),
                    value: privacySettings.shareLocation,
                    onChanged: privacyNotifier.updateShareLocation,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text('Share Statistics'),
                    subtitle: const Text(
                      'Include distance, pace, and elevation data when sharing'
                    ),
                    value: privacySettings.shareStats,
                    onChanged: privacyNotifier.updateShareStats,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data Management Section
          const DataManagementSection(),
          
          const SizedBox(height: 16),
          
          // Reset Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restore,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reset Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reset all privacy settings to their default values.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showResetConfirmation(context, privacyNotifier),
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Privacy Notice
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TrailRun is designed with privacy by default. Your data is stored locally on your device with encryption. You have full control over what information is shared and can export or delete your data at any time.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog for resetting settings
  void _showResetConfirmation(BuildContext context, PrivacySettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
          'Are you sure you want to reset all privacy settings to their default values? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings reset to defaults'),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}