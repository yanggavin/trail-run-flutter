import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../data/services/map_service.dart';
import '../../domain/models/activity.dart';

/// Compact, non-interactive map widget for activity previews
class CompactMapWidget extends StatelessWidget {
  const CompactMapWidget({
    super.key,
    required this.activity,
    this.height = 200,
    this.borderRadius = 8.0,
    this.showPhotos = true,
    this.routeColor = Colors.blue,
    this.routeWidth = 2.0,
  });

  final Activity activity;
  final double height;
  final double borderRadius;
  final bool showPhotos;
  final Color routeColor;
  final double routeWidth;

  @override
  Widget build(BuildContext context) {
    final trackPoints = activity.trackPointsSortedBySequence;
    
    if (trackPoints.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No route data available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final bounds = MapService.calculateBounds(trackPoints);
    final photos = activity.photos.where((p) => p.hasLocation).toList();

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: bounds != null
                ? CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(20),
                  )
                : null,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable all interactions
            ),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trailrun.trailrun_app',
            ),
            
            // Route polyline
            PolylineLayer(
              polylines: [
                MapService.createOptimizedPolyline(
                  trackPoints,
                  color: routeColor,
                  strokeWidth: routeWidth,
                  maxPoints: 500, // Reduce points for compact view
                ),
              ],
            ),
            
            // Photo markers (smaller for compact view)
            if (showPhotos && photos.isNotEmpty)
              MarkerLayer(
                markers: photos.map((photo) {
                  final latLng = MapService.photoToLatLng(photo);
                  if (latLng == null) return null;

                  return Marker(
                    point: latLng,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.blue,
                        size: 12,
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            
            // Start marker
            MarkerLayer(
              markers: [
                Marker(
                  point: MapService.trackPointToLatLng(trackPoints.first),
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                // End marker (if activity is completed)
                if (trackPoints.length > 1 && activity.isCompleted)
                  Marker(
                    point: MapService.trackPointToLatLng(trackPoints.last),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}