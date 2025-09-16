import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/map_service.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../../domain/models/track_point.dart';

/// Interactive map widget for displaying activity routes and photos
class ActivityMapWidget extends StatefulWidget {
  const ActivityMapWidget({
    super.key,
    required this.activity,
    this.onPhotoTap,
    this.showPhotos = true,
    this.showRoute = true,
    this.routeColor = Colors.blue,
    this.routeWidth = 3.0,
    this.enableInteraction = true,
    this.initialZoom = 15.0,
    this.maxZoom = 18.0,
    this.minZoom = 3.0,
  });

  final Activity activity;
  final Function(Photo)? onPhotoTap;
  final bool showPhotos;
  final bool showRoute;
  final Color routeColor;
  final double routeWidth;
  final bool enableInteraction;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;

  @override
  State<ActivityMapWidget> createState() => _ActivityMapWidgetState();
}

class _ActivityMapWidgetState extends State<ActivityMapWidget> {
  late final MapController _mapController;
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Fit bounds after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToBounds();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitToBounds() {
    if (widget.activity.trackPoints.isEmpty) return;
    
    final bounds = MapService.calculateBounds(widget.activity.trackPoints);
    if (bounds != null) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(20),
        ),
      );
    }
  }

  void _onPhotoMarkerTap(Photo photo) {
    widget.onPhotoTap?.call(photo);
  }

  @override
  Widget build(BuildContext context) {
    final trackPoints = widget.activity.trackPointsSortedBySequence;
    final photos = widget.activity.photos.where((p) => p.hasLocation).toList();

    return RepaintBoundary(
      key: _mapKey,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialZoom: widget.initialZoom,
          maxZoom: widget.maxZoom,
          minZoom: widget.minZoom,
          interactionOptions: InteractionOptions(
            flags: widget.enableInteraction 
                ? InteractiveFlag.all 
                : InteractiveFlag.none,
          ),
        ),
        children: [
          // Tile layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.trailrun.trailrun_app',
            maxZoom: widget.maxZoom,
          ),
          
          // Route polyline
          if (widget.showRoute && trackPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                MapService.createOptimizedPolyline(
                  trackPoints,
                  color: widget.routeColor,
                  strokeWidth: widget.routeWidth,
                ),
              ],
            ),
          
          // Photo markers
          if (widget.showPhotos && photos.isNotEmpty)
            MarkerLayer(
              markers: _createPhotoMarkers(photos),
            ),
          
          // Start/End markers
          if (trackPoints.isNotEmpty)
            MarkerLayer(
              markers: [
                // Start marker
                Marker(
                  point: MapService.trackPointToLatLng(trackPoints.first),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // End marker (if activity is completed)
                if (trackPoints.length > 1 && widget.activity.isCompleted)
                  Marker(
                    point: MapService.trackPointToLatLng(trackPoints.last),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  List<Marker> _createPhotoMarkers(List<Photo> photos) {
    return photos.map((photo) {
      final latLng = MapService.photoToLatLng(photo);
      if (latLng == null) return null;

      return Marker(
        point: latLng,
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => _onPhotoMarkerTap(photo),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.blue,
              size: 16,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  /// Generate map snapshot for sharing
  Future<Uint8List?> generateSnapshot() async {
    return MapService.generateMapSnapshot(_mapKey);
  }

  /// Fit map to show all track points
  void fitToBounds() {
    _fitToBounds();
  }

  /// Get current map controller
  MapController get mapController => _mapController;
}