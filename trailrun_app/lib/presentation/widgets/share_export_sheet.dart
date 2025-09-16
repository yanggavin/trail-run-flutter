import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/activity.dart';
import '../../data/services/share_export_provider.dart';
import '../../data/services/map_service.dart';

/// Bottom sheet for sharing and exporting activities
class ShareExportSheet extends ConsumerStatefulWidget {
  const ShareExportSheet({
    super.key,
    required this.activity,
    this.mapSnapshot,
  });

  final Activity activity;
  final Uint8List? mapSnapshot;

  @override
  ConsumerState<ShareExportSheet> createState() => _ShareExportSheetState();
}

class _ShareExportSheetState extends ConsumerState<ShareExportSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Share & Export',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.activity.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Share options
          _buildShareOption(
            icon: Icons.share,
            title: 'Share Activity',
            subtitle: 'Share with photos and map',
            onTap: _isLoading ? null : _shareActivity,
          ),
          
          _buildShareOption(
            icon: Icons.image,
            title: 'Share Card',
            subtitle: 'Generate and share summary card',
            onTap: _isLoading ? null : _shareCard,
          ),
          
          const Divider(height: 32),
          
          // Export options
          _buildShareOption(
            icon: Icons.download,
            title: 'Export GPX',
            subtitle: 'Download GPS track data',
            onTap: _isLoading ? null : _exportGpx,
          ),
          
          _buildShareOption(
            icon: Icons.photo_library,
            title: 'Export Photos',
            subtitle: 'Download photos with metadata',
            onTap: _isLoading ? null : _exportPhotos,
          ),
          
          const SizedBox(height: 16),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right)
          : const SizedBox.shrink(),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Future<void> _shareActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shareService = ref.read(shareExportServiceProvider);
      await shareService.shareActivity(
        widget.activity,
        mapSnapshot: widget.mapSnapshot,
        includePhotos: true,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to share activity: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shareService = ref.read(shareExportServiceProvider);
      final cardGenerator = ref.read(shareCardGeneratorProvider);
      
      // Load photo thumbnails
      final photoThumbnails = await cardGenerator.loadPhotoThumbnails(widget.activity.photos);
      
      // Generate share card
      final shareCardBytes = await cardGenerator.renderShareCard(
        widget.activity,
        mapSnapshot: widget.mapSnapshot,
        photoThumbnails: photoThumbnails,
      );
      
      if (shareCardBytes != null) {
        await shareService.shareActivity(
          widget.activity,
          mapSnapshot: shareCardBytes,
          includePhotos: false,
        );
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to generate share card';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create share card: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportGpx() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shareService = ref.read(shareExportServiceProvider);
      final gpxFile = await shareService.exportActivityAsGpx(widget.activity);
      
      await Share.shareXFiles(
        [gpxFile],
        subject: '${widget.activity.title} - GPX Track',
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to export GPX: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPhotos() async {
    if (widget.activity.photos.isEmpty) {
      setState(() {
        _errorMessage = 'No photos to export';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shareService = ref.read(shareExportServiceProvider);
      final photoFiles = await shareService.exportPhotoBundle(widget.activity);
      
      if (photoFiles.isNotEmpty) {
        await Share.shareXFiles(
          photoFiles,
          subject: '${widget.activity.title} - Photos',
        );
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage = 'No photos found to export';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to export photos: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Helper function to show the share export sheet
void showShareExportSheet(
  BuildContext context,
  Activity activity, {
  Uint8List? mapSnapshot,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareExportSheet(
      activity: activity,
      mapSnapshot: mapSnapshot,
    ),
  );
}