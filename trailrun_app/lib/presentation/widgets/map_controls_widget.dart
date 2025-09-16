import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Interactive map controls for zoom, pan, and other map operations
class MapControlsWidget extends StatelessWidget {
  const MapControlsWidget({
    super.key,
    required this.mapController,
    this.onFitBounds,
    this.onSnapshot,
    this.showFitBounds = true,
    this.showSnapshot = true,
    this.showZoomControls = true,
  });

  final MapController mapController;
  final VoidCallback? onFitBounds;
  final VoidCallback? onSnapshot;
  final bool showFitBounds;
  final bool showSnapshot;
  final bool showZoomControls;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Zoom controls
          if (showZoomControls) ...[
            _buildControlButton(
              icon: Icons.add,
              onPressed: () => _zoomIn(),
              tooltip: 'Zoom In',
            ),
            const SizedBox(height: 8),
            _buildControlButton(
              icon: Icons.remove,
              onPressed: () => _zoomOut(),
              tooltip: 'Zoom Out',
            ),
            const SizedBox(height: 16),
          ],
          
          // Fit bounds control
          if (showFitBounds && onFitBounds != null) ...[
            _buildControlButton(
              icon: Icons.fit_screen,
              onPressed: onFitBounds,
              tooltip: 'Fit to Route',
            ),
            const SizedBox(height: 8),
          ],
          
          // Snapshot control
          if (showSnapshot && onSnapshot != null)
            _buildControlButton(
              icon: Icons.camera_alt,
              onPressed: onSnapshot,
              tooltip: 'Take Snapshot',
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.grey[700]),
          onPressed: onPressed,
          splashRadius: 20,
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentZoom = mapController.camera.zoom;
    mapController.move(mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = mapController.camera.zoom;
    mapController.move(mapController.camera.center, currentZoom - 1);
  }
}