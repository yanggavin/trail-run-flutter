import 'dart:math' as math;

/// Immutable value object representing GPS coordinates
class Coordinates {
  const Coordinates({
    required this.latitude,
    required this.longitude,
    this.elevation,
  }) : assert(latitude >= -90 && latitude <= 90, 'Invalid latitude'),
       assert(longitude >= -180 && longitude <= 180, 'Invalid longitude');

  final double latitude;
  final double longitude;
  final double? elevation;

  /// Calculate distance to another coordinate in meters using Haversine formula
  double distanceTo(Coordinates other) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = latitude * (math.pi / 180);
    final double lat2Rad = other.latitude * (math.pi / 180);
    final double deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    final double deltaLonRad = (other.longitude - longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Calculate bearing to another coordinate in degrees
  double bearingTo(Coordinates other) {
    final double lat1Rad = latitude * (math.pi / 180);
    final double lat2Rad = other.latitude * (math.pi / 180);
    final double deltaLonRad = (other.longitude - longitude) * (math.pi / 180);

    final double y = math.sin(deltaLonRad) * math.cos(lat2Rad);
    final double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLonRad);

    final double bearingRad = math.atan2(y, x);
    return (bearingRad * (180 / math.pi) + 360) % 360;
  }

  /// Create a copy with updated values
  Coordinates copyWith({
    double? latitude,
    double? longitude,
    double? elevation,
  }) {
    return Coordinates(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          elevation == other.elevation;

  @override
  int get hashCode => Object.hash(latitude, longitude, elevation);

  @override
  String toString() => 'Coordinates($latitude, $longitude${elevation != null ? ', $elevation' : ''})';
}