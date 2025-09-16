import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
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
  
  /// Create optimized polyline for large routes with advanced simplification
  static Polyline createOptimizedPolyline(List<TrackPoint> trackPoints, {
    Color color = Colors.blue,
    double strokeWidth = 3.0,
    int maxPoints = 1000,
    double tolerance = 0.0001, // Degrees for Douglas-Peucker
  }) {
    if (trackPoints.isEmpty) {
      return Polyline(points: [], color: color, strokeWidth: strokeWidth);
    }
    
    List<TrackPoint> optimizedPoints = trackPoints;
    
    // Apply multi-stage optimization for large routes
    if (trackPoints.length > maxPoints) {
      // Stage 1: Remove points with poor accuracy (if we have many points)
      if (trackPoints.length > maxPoints * 2) {
        optimizedPoints = _filterByAccuracy(trackPoints, maxAccuracy: 20.0);
      }
      
      // Stage 2: Apply Douglas-Peucker simplification
      if (optimizedPoints.length > maxPoints) {
        optimizedPoints = _douglasPeuckerSimplify(optimizedPoints, tolerance);
      }
      
      // Stage 3: Final decimation if still too many points
      if (optimizedPoints.length > maxPoints) {
        optimizedPoints = _adaptiveDecimation(optimizedPoints, maxPoints);
      }
    }
    
    final points = optimizedPoints
        .map((point) => trackPointToLatLng(point))
        .toList();
    
    return Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      useStrokeWidthInMeter: false, // Use screen pixels for better performance
    );
  }
  
  /// Filter track points by GPS accuracy
  static List<TrackPoint> _filterByAccuracy(List<TrackPoint> points, {required double maxAccuracy}) {
    return points.where((point) => point.accuracy <= maxAccuracy).toList();
  }
  
  /// Douglas-Peucker line simplification algorithm
  static List<TrackPoint> _douglasPeuckerSimplify(List<TrackPoint> points, double tolerance) {
    if (points.length <= 2) return points;
    
    return _douglasPeuckerRecursive(points, 0, points.length - 1, tolerance);
  }
  
  static List<TrackPoint> _douglasPeuckerRecursive(
    List<TrackPoint> points, 
    int startIndex, 
    int endIndex, 
    double tolerance
  ) {
    if (endIndex <= startIndex + 1) {
      return [points[startIndex], points[endIndex]];
    }
    
    // Find the point with maximum distance from the line
    double maxDistance = 0;
    int maxIndex = startIndex;
    
    final start = points[startIndex];
    final end = points[endIndex];
    
    for (int i = startIndex + 1; i < endIndex; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    
    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final leftPoints = _douglasPeuckerRecursive(points, startIndex, maxIndex, tolerance);
      final rightPoints = _douglasPeuckerRecursive(points, maxIndex, endIndex, tolerance);
      
      // Combine results (remove duplicate middle point)
      return [...leftPoints.take(leftPoints.length - 1), ...rightPoints];
    } else {
      // All points between start and end can be removed
      return [points[startIndex], points[endIndex]];
    }
  }
  
  /// Calculate perpendicular distance from point to line
  static double _perpendicularDistance(TrackPoint point, TrackPoint lineStart, TrackPoint lineEnd) {
    final x0 = point.coordinates.latitude;
    final y0 = point.coordinates.longitude;
    final x1 = lineStart.coordinates.latitude;
    final y1 = lineStart.coordinates.longitude;
    final x2 = lineEnd.coordinates.latitude;
    final y2 = lineEnd.coordinates.longitude;
    
    final numerator = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    final denominator = math.sqrt(math.pow(y2 - y1, 2) + math.pow(x2 - x1, 2));
    
    return denominator == 0 ? 0 : numerator / denominator;
  }
  
  /// Adaptive decimation that preserves important points
  static List<TrackPoint> _adaptiveDecimation(List<TrackPoint> points, int targetCount) {
    if (points.length <= targetCount) return points;
    
    final simplified = <TrackPoint>[];
    final step = points.length / (targetCount - 2).toDouble();
    
    // Always include first point
    simplified.add(points.first);
    
    // Add points at calculated intervals, but prefer points with:
    // - Direction changes
    // - Elevation changes
    // - Better GPS accuracy
    for (int i = 1; i < points.length - 1 && simplified.length < targetCount - 1; i++) {
      if (i % step.round() == 0 || _isImportantPoint(points, i)) {
        simplified.add(points[i]);
      }
    }
    
    // Always include last point
    if (points.length > 1) {
      simplified.add(points.last);
    }
    
    return simplified;
  }
  
  /// Check if a point is important and should be preserved
  static bool _isImportantPoint(List<TrackPoint> points, int index) {
    if (index <= 0 || index >= points.length - 1) return false;
    
    final prev = points[index - 1];
    final current = points[index];
    final next = points[index + 1];
    
    // Check for significant direction change
    final bearing1 = _calculateBearing(prev, current);
    final bearing2 = _calculateBearing(current, next);
    final bearingDiff = (bearing2 - bearing1).abs();
    final normalizedDiff = bearingDiff > 180 ? 360 - bearingDiff : bearingDiff;
    
    if (normalizedDiff > 30) return true; // Significant direction change
    
    // Check for significant elevation change
    if (prev.coordinates.elevation != null && 
        current.coordinates.elevation != null && 
        next.coordinates.elevation != null) {
      final elevChange1 = (current.coordinates.elevation! - prev.coordinates.elevation!).abs();
      final elevChange2 = (next.coordinates.elevation! - current.coordinates.elevation!).abs();
      
      if (elevChange1 > 5 || elevChange2 > 5) return true; // 5m elevation change
    }
    
    // Prefer points with better accuracy
    if (current.accuracy < 10) return true;
    
    return false;
  }
  
  /// Calculate bearing between two points
  static double _calculateBearing(TrackPoint from, TrackPoint to) {
    final lat1 = from.coordinates.latitude * math.pi / 180;
    final lat2 = to.coordinates.latitude * math.pi / 180;
    final deltaLng = (to.coordinates.longitude - from.coordinates.longitude) * math.pi / 180;
    
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    
    return math.atan2(y, x) * 180 / math.pi;
  }
  
  /// Create level-of-detail polylines for different zoom levels
  static Map<int, Polyline> createLODPolylines(List<TrackPoint> trackPoints, {
    Color color = Colors.blue,
    double strokeWidth = 3.0,
  }) {
    final lodPolylines = <int, Polyline>{};
    
    // Different detail levels for different zoom ranges
    final lodConfigs = {
      1: 100,   // Very low detail for zoom 1-8
      8: 500,   // Low detail for zoom 8-12
      12: 1500, // Medium detail for zoom 12-16
      16: 5000, // High detail for zoom 16+
    };
    
    for (final entry in lodConfigs.entries) {
      final zoomLevel = entry.key;
      final maxPoints = entry.value;
      
      lodPolylines[zoomLevel] = createOptimizedPolyline(
        trackPoints,
        color: color,
        strokeWidth: strokeWidth,
        maxPoints: maxPoints,
      );
    }
    
    return lodPolylines;
  }
}
    