import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';

/// Service for generating share cards with activity data
class ShareCardGenerator {
  static const double _cardWidth = 800.0;
  static const double _cardHeight = 1000.0;
  static const double _padding = 32.0;
  static const double _borderRadius = 16.0;

  /// Generate a share card widget that can be rendered to image
  Widget buildShareCard(
    Activity activity, {
    Uint8List? mapSnapshot,
    List<Uint8List>? photoThumbnails,
  }) {
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and date
          _buildHeader(activity),
          
          // Map section
          if (mapSnapshot != null) _buildMapSection(mapSnapshot),
          
          // Stats section
          _buildStatsSection(activity),
          
          // Photo collage section
          if (photoThumbnails != null && photoThumbnails.isNotEmpty)
            _buildPhotoCollage(photoThumbnails),
          
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  /// Build header section with title and date
  Widget _buildHeader(Activity activity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_borderRadius),
          topRight: Radius.circular(_borderRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(activity.startTime.dateTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Build map section
  Widget _buildMapSection(Uint8List mapSnapshot) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          mapSnapshot,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  /// Build stats section
  Widget _buildStatsSection(Activity activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Stats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Distance',
                '${activity.distance.kilometers.toStringAsFixed(2)} km',
                Icons.straighten,
                Colors.blue,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Duration',
                _formatDuration(activity.duration),
                Icons.timer,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Avg Pace',
                _formatPace(activity.averagePace),
                Icons.speed,
                Colors.orange,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                'Elevation',
                '${activity.elevationGain.meters.toStringAsFixed(0)}m',
                Icons.terrain,
                Colors.red,
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build photo collage section
  Widget _buildPhotoCollage(List<Uint8List> photoThumbnails) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photoThumbnails.length.clamp(0, 5), // Max 5 photos
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(right: index < photoThumbnails.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      photoThumbnails[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer section
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            'Tracked with TrailRun',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Render share card widget to image bytes
  Future<Uint8List?> renderShareCard(
    Activity activity, {
    Uint8List? mapSnapshot,
    List<Uint8List>? photoThumbnails,
    double pixelRatio = 2.0,
  }) async {
    try {
      final widget = buildShareCard(
        activity,
        mapSnapshot: mapSnapshot,
        photoThumbnails: photoThumbnails,
      );

      // Create a render object
      final repaintBoundary = RenderRepaintBoundary();
      final renderView = RenderView(
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: const ViewConfiguration(
          size: Size(_cardWidth, _cardHeight),
          devicePixelRatio: 1.0,
        ),
        window: WidgetsBinding.instance.window,
      );

      // Build the widget tree
      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());

      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: widget,
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      // Convert to image
      final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error rendering share card: $e');
      return null;
    }
  }

  /// Load photo thumbnails from file paths
  Future<List<Uint8List>> loadPhotoThumbnails(List<Photo> photos) async {
    final thumbnails = <Uint8List>[];
    
    for (final photo in photos.take(5)) { // Max 5 photos
      try {
        final file = File(photo.thumbnailPath ?? photo.filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          thumbnails.add(bytes);
        }
      } catch (e) {
        debugPrint('Error loading photo thumbnail: $e');
      }
    }
    
    return thumbnails;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format duration for display
  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60);
    final seconds = (duration.inSeconds % 60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  /// Format pace for display
  String _formatPace(dynamic pace) {
    if (pace == null) return '--';
    
    // Assuming pace has secondsPerKilometer property
    final secondsPerKm = pace.secondsPerKilometer as double;
    final minutes = secondsPerKm ~/ 60;
    final seconds = (secondsPerKm % 60).round();
    
    return '${minutes}:${seconds.toString().padLeft(2, '0')}/km';
  }
}