import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/privacy_service.dart';
import '../../data/services/privacy_settings_provider.dart';

/// Widget for managing user data (export, delete)
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyService = ref.read(privacyServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Export your data or permanently delete it from this device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Export Data Section
            _DataActionTile(
              icon: Icons.download,
              title: 'Export Data',
              subtitle: 'Download all your activities, photos, and settings',
              onTap: () => _showExportOptions(context, privacyService),
            ),
            
            const SizedBox(height: 8),
            
            // Delete Data Section
            _DataActionTile(
              icon: Icons.delete_forever,
              title: 'Delete All Data',
              subtitle: 'Permanently remove all data from this device',
              isDestructive: true,
              onTap: () => _showDeleteConfirmation(context, privacyService),
            ),
          ],
        ),
      ),
    );
  }

  /// Show export options dialog
  void _showExportOptions(BuildContext context, PrivacyService privacyService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Choose how you want to export your data:'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportDataOnly(context, privacyService);
            },
            child: const Text('Data Only'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportDataWithPhotos(context, privacyService);
            },
            child: const Text('Data + Photos'),
          ),
        ],
      ),
    );
  }

  /// Export data only (JSON)
  void _exportDataOnly(BuildContext context, PrivacyService privacyService) async {
    try {
      _showLoadingDialog(context, 'Exporting data...');
      
      final exportPath = await privacyService.exportUserData();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Share the exported file
      await Share.shareXFiles([XFile(exportPath)]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Export Failed', 'Failed to export data: $e');
    }
  }

  /// Export data with photos (ZIP)
  void _exportDataWithPhotos(BuildContext context, PrivacyService privacyService) async {
    try {
      _showLoadingDialog(context, 'Exporting data and photos...');
      
      final exportPath = await privacyService.exportUserDataWithPhotos();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      // Share the exported file
      await Share.shareXFiles([XFile(exportPath)]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data and photos exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Export Failed', 'Failed to export data with photos: $e');
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, PrivacyService privacyService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your activities, photos, and settings from this device. This action cannot be undone.\n\nAre you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAllData(context, privacyService);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  /// Delete all user data
  void _deleteAllData(BuildContext context, PrivacyService privacyService) async {
    try {
      _showLoadingDialog(context, 'Deleting all data...');
      
      await privacyService.deleteAllUserData();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog(context, 'Delete Failed', 'Failed to delete data: $e');
    }
  }

  /// Show loading dialog
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Individual data action tile
class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DataActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isDestructive 
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDestructive ? colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}