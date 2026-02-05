/// Source of location data for track points
enum LocationSource {
  /// GPS satellite data
  gps,
  
  /// Network-based location (cell towers, WiFi)
  network,
  
  /// Fused location provider (combination of GPS and network)
  fused,
  
  /// Manual entry by user
  manual,
  
  /// Interpolated point (e.g. during auto-pause or signal loss)
  interpolated,
  
  /// Unknown or unspecified source
  unknown,
}

extension LocationSourceExtension on LocationSource {
  /// Human-readable name for the location source
  String get displayName {
    switch (this) {
      case LocationSource.gps:
        return 'GPS';
      case LocationSource.network:
        return 'Network';
      case LocationSource.fused:
        return 'Fused';
      case LocationSource.manual:
        return 'Manual';
      case LocationSource.interpolated:
        return 'Interpolated';
      case LocationSource.unknown:
        return 'Unknown';
    }
  }
  
  /// Whether this source is considered high accuracy
  bool get isHighAccuracy {
    switch (this) {
      case LocationSource.gps:
      case LocationSource.fused:
        return true;
      case LocationSource.network:
      case LocationSource.manual:
      case LocationSource.interpolated:
      case LocationSource.unknown:
        return false;
    }
  }
}