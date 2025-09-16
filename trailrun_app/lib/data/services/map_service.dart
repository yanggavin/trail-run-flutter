import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../../domain/models/track_point.dart';

/// Service for map-related operations including rendering and snapshot generation
class MapService {
  static const String _defaultTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _userAgent = 'TrailRun Mobile App';
  
  /// Convert TrackPoint to LatLng for flutter_map
  static LatLng trackPointToLatLng(TrackPoint point) {
    return LatLng(point.coordinates.latitude, point.coordinates.longitude);
  }
  
  /// Convert Photo to LatLng for flutter_map (if photo has coordinates)
  static LatLng? photoToLatLng(Photo photo) {
    if (photo.coordinates == null) return null;
    return LatLng(photo.coordinates!.latitude, photo.coordinates!.longitude);
  }
  
  /// Create polyline from track points
  static Polyline createRoutePolyline(List<TrackPoint> trackPoints, {
    Color color = Colors.blue,
    double strokeWidth = 3.0,
  }) {
    if (trackPoints.isEmpty) {
      return Polyline(points: [], color: color, strokeWidth: strokeWidth);
    }
    
    final points = trackPoints
        .map((point) => trackPointToLatLng(point))
        .toList();
    
    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
  
  /// Create markers for photos
  static List<Marker> createPhotoMarkers(List<Photo> photos, {
    required VoidCallback onPhotoTap,
    double markerSize = 30.0,
  }) {
    final markers = <Marker>[];
    
    for (final photo in photos) {
      final latLng = photoToLatLng(photo);
      if (latLng == null) continue;
      
      markers.add(
        Marker(
          point: latLng,
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: onPhotoTap,
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
        ),
      );
    }
    
    return markers;
  }
  
  /// Calculate bounds for a list of track points
  static LatLngBounds? calculateBounds(List<TrackPoint> trackPoints, {
    double padding = 0.001, // degrees
  }) {
    if (trackPoints.isEmpty) return null;
    
    double minLat = trackPoints.first.coordinates.latitude;
    double maxLat = trackPoints.first.coordinates.latitude;
    double minLng = trackPoints.first.coordinates.longitude;
    double maxLng = trackPoints.first.coordinates.longitude;
    
    for (final point in trackPoints) {
      minLat = minLat < point.coordinates.latitude ? minLat : point.coordinates.latitude;
      maxLat = maxLat > point.coordinates.latitude ? maxLat : point.coordinates.latitude;
      minLng = minLng < point.coordinates.longitude ? minLng : point.coordinates.longitude;
      maxLng = maxLng > point.coordinates.longitude ? maxLng : point.coordinates.longitude;
    }
    
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }
  
  /// Generate map snapshot as image bytes
  static Future<Uint8List?> generateMapSnapshot(
    GlobalKey mapKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary = 
          mapKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating map snapshot: $e');
      return null;
    }
  }
  
  /// Create optimized polyline for large routes
  static Polyline createOptimizedPolyline(List<TrackPoint> trackPoints, {
    Color color = Colors.blue,
    double strokeWidth = 3.0,
    int maxPoints = 1000,
  }) {
    if (trackPoints.isEmpty) {
      return Polyline(points: [], color: color, strokeWidth: strokeWidth);
    }
    
    List<TrackPoint> optimizedPoints = trackPoints;
    
    // Simplify route if too many points for performance
    if (trackPoints.length > maxPoints) {
      optimizedPoints = _simplifyRoute(trackPoints, maxPoints);
    }
    
    final points = optimizedPoints
        .map((point) => trackPointToLatLng(point))
        .toList();
    
    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
    );
  }
  
  /// Simplify route using Douglas-Peucker-like algorithm
  static List<TrackPoint> _simplifyRoute(List<TrackPoint> points, int targetCount) {
    if (points.length <= targetCount) return points;
    
    // Simple decimation - take every nth point plus start/end
    final step = points.length / (targetCount - 2); // Reserve space for start/end
    final simplified = <TrackPoint>[];
    
    // Always include first point
    simplified.add(points.first);
    
    // Add intermediate points
    for (int i = 1; i < points.length - 1 && simplified.length < targetCount - 1; i++) {
      if (i % step.round() == 0) {
        simplified.add(points[i]);
      }
    }
    
    // Always include last point
    if (points.length > 1) {
      simplified.add(points.last);
    }
    
    return simplified;
  }
}
    