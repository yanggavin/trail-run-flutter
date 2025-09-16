import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/services/map_service.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../widgets/activity_map_widget.dart';
import '../widgets/map_controls_widget.dart';

/// Full-screen map view for displaying activity routes and photos
class ActivityMapScreen extends StatefulWidget {
  const ActivityMapScreen({
    super.key,
    required this.activity,
    this.title,
  });

  final Activity activity;
  final String? title;

  @override
  State<ActivityMapScreen> createState() => _ActivityMapScreenState();
}

class _ActivityMapScreenState extends State<ActivityMapScreen> {
  final GlobalKey _mapWidgetKey = GlobalKey();
  bool _isGeneratingSnapshot = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? widget.activity.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMapSnapshot,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map widget
          ActivityMapWidget(
            key: _mapWidgetKey,
            activity: widget.activity,
            onPhotoTap: _onPhotoTap,
          ),
          
          // Map controls
          MapControlsWidget(
            mapController: MapController(),
            onFitBounds: _fitToBounds,
            onSnapshot: _shareMapSnapshot,
          ),
          
          // Loading indicator for snapshot generation
          if (_isGeneratingSnapshot)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Generating map snapshot...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onPhotoTap(Photo photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Captured: ${photo.timestamp.dateTime.toString()}'),
            if (photo.coordinates != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${photo.coordinates!.latitude.toStringAsFixed(6)}, ${photo.coordinates!.longitude.toStringAsFixed(6)}'),
            ],
            if (photo.caption != null) ...[
              const SizedBox(height: 8),
              Text('Caption: ${photo.caption}'),
            ],
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

  void _fitToBounds() {
    // Map bounds fitting will be handled by the map widget itself
  }

  Future<void> _shareMapSnapshot() async {
    if (_isGeneratingSnapshot) return;
    
    setState(() {
      _isGeneratingSnapshot = true;
    });

    try {
      final snapshot = await MapService.generateMapSnapshot(_mapWidgetKey);
      
      if (snapshot != null) {
        // Save to temporary file and share
        await Share.shareXFiles(
          [XFile.fromData(snapshot, name: 'route_map.png', mimeType: 'image/png')],
          text: 'Check out my trail run route!',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate map snapshot'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSnapshot = false;
        });
      }
    }
  }
}