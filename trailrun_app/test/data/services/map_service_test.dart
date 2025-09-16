import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailrun_app/data/services/map_service.dart';
import 'package:trailrun_app/domain/models/photo.dart';
import 'package:trailrun_app/domain/models/track_point.dart';
import 'package:trailrun_app/domain/value_objects/coordinates.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/enums/location_source.dart';

void main() {
  group('MapService', () {
    late List<TrackPoint> sampleTrackPoints;
    late List<Photo> samplePhotos;

    setUp(() {
      sampleTrackPoints = [
        TrackPoint(
          id: '1',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7749, longitude: -122.4194),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 0,
        ),
        TrackPoint(
          id: '2',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7849, longitude: -122.4094),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 1,
        ),
        TrackPoint(
          id: '3',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          coordinates: const Coordinates(latitude: 37.7949, longitude: -122.3994),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: 2,
        ),
      ];

      samplePhotos = [
        Photo(
          id: 'photo1',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo1.jpg',
          coordinates: const Coordinates(latitude: 37.7799, longitude: -122.4144),
        ),
        Photo(
          id: 'photo2',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo2.jpg',
          coordinates: const Coordinates(latitude: 37.7899, longitude: -122.4044),
        ),
        Photo(
          id: 'photo3',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          filePath: '/path/to/photo3.jpg',
          // No coordinates for this photo
        ),
      ];
    });

    group('trackPointToLatLng', () {
      test('converts TrackPoint to LatLng correctly', () {
        final trackPoint = sampleTrackPoints.first;
        final latLng = MapService.trackPointToLatLng(trackPoint);

        expect(latLng.latitude, equals(37.7749));
        expect(latLng.longitude, equals(-122.4194));
      });
    });

    group('photoToLatLng', () {
      test('converts Photo with coordinates to LatLng correctly', () {
        final photo = samplePhotos.first;
        final latLng = MapService.photoToLatLng(photo);

        expect(latLng, isNotNull);
        expect(latLng!.latitude, equals(37.7799));
        expect(latLng.longitude, equals(-122.4144));
      });

      test('returns null for Photo without coordinates', () {
        final photo = samplePhotos.last; // Photo without coordinates
        final latLng = MapService.photoToLatLng(photo);

        expect(latLng, isNull);
      });
    });

    group('createRoutePolyline', () {
      test('creates polyline from track points', () {
        final polyline = MapService.createRoutePolyline(sampleTrackPoints);

        expect(polyline.points.length, equals(3));
        expect(polyline.color, equals(Colors.blue));
        expect(polyline.strokeWidth, equals(3.0));
        
        // Check first point
        expect(polyline.points.first.latitude, equals(37.7749));
        expect(polyline.points.first.longitude, equals(-122.4194));
        
        // Check last point
        expect(polyline.points.last.latitude, equals(37.7949));
        expect(polyline.points.last.longitude, equals(-122.3994));
      });

      test('creates empty polyline for empty track points', () {
        final polyline = MapService.createRoutePolyline([]);

        expect(polyline.points, isEmpty);
        expect(polyline.color, equals(Colors.blue));
        expect(polyline.strokeWidth, equals(3.0));
      });

      test('creates polyline with custom color and width', () {
        final polyline = MapService.createRoutePolyline(
          sampleTrackPoints,
          color: Colors.red,
          strokeWidth: 5.0,
        );

        expect(polyline.color, equals(Colors.red));
        expect(polyline.strokeWidth, equals(5.0));
      });
    });

    group('createPhotoMarkers', () {
      test('creates markers for photos with coordinates', () {
        final markers = MapService.createPhotoMarkers(
          samplePhotos,
          onPhotoTap: () {},
        );

        // Should create markers only for photos with coordinates (2 out of 3)
        expect(markers.length, equals(2));
        
        // Check first marker position
        expect(markers.first.point.latitude, equals(37.7799));
        expect(markers.first.point.longitude, equals(-122.4144));
      });

      test('creates empty list for photos without coordinates', () {
        final photosWithoutCoords = [samplePhotos.last]; // Photo without coordinates
        final markers = MapService.createPhotoMarkers(
          photosWithoutCoords,
          onPhotoTap: () {},
        );

        expect(markers, isEmpty);
      });
    });

    group('calculateBounds', () {
      test('calculates bounds for track points', () {
        final bounds = MapService.calculateBounds(sampleTrackPoints);

        expect(bounds, isNotNull);
        
        // Check bounds include all points with padding
        expect(bounds!.southWest.latitude, lessThan(37.7749));
        expect(bounds.southWest.longitude, lessThan(-122.4194));
        expect(bounds.northEast.latitude, greaterThan(37.7949));
        expect(bounds.northEast.longitude, greaterThan(-122.3994));
      });

      test('returns null for empty track points', () {
        final bounds = MapService.calculateBounds([]);

        expect(bounds, isNull);
      });

      test('calculates bounds with custom padding', () {
        final bounds = MapService.calculateBounds(
          sampleTrackPoints,
          padding: 0.01,
        );

        expect(bounds, isNotNull);
        
        // With larger padding, bounds should be further from actual points
        expect(bounds!.southWest.latitude, lessThan(37.7749 - 0.005));
        expect(bounds.northEast.latitude, greaterThan(37.7949 + 0.005));
      });
    });

    group('createOptimizedPolyline', () {
      test('creates polyline without optimization for small routes', () {
        final polyline = MapService.createOptimizedPolyline(sampleTrackPoints);

        expect(polyline.points.length, equals(3));
        expect(polyline.color, equals(Colors.blue));
        expect(polyline.strokeWidth, equals(3.0));
      });

      test('optimizes large routes by reducing points', () {
        // Create a large list of track points
        final largeTrackPoints = List.generate(2000, (index) => TrackPoint(
          id: 'point_$index',
          activityId: 'activity1',
          timestamp: Timestamp.now(),
          coordinates: Coordinates(
            latitude: 37.7749 + (index * 0.0001),
            longitude: -122.4194 + (index * 0.0001),
          ),
          accuracy: 5.0,
          source: LocationSource.gps,
          sequence: index,
        ));

        final polyline = MapService.createOptimizedPolyline(
          largeTrackPoints,
          maxPoints: 1000,
        );

        // Should be optimized to maxPoints or less
        expect(polyline.points.length, lessThanOrEqualTo(1000));
        expect(polyline.points.length, greaterThan(0));
      });

      test('creates empty polyline for empty track points', () {
        final polyline = MapService.createOptimizedPolyline([]);

        expect(polyline.points, isEmpty);
      });
    });
  });
}