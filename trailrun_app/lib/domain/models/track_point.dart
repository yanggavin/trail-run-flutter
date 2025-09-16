import '../enums/location_source.dart';
import '../value_objects/coordinates.dart';
import '../value_objects/timestamp.dart';

/// Individual GPS tracking point with location and metadata
class TrackPoint {
  const TrackPoint({
    required this.id,
    required this.activityId,
    required this.timestamp,
    required this.coordinates,
    required this.accuracy,
    required this.source,
    required this.sequence,
  });

  /// Unique identifier for this track point
  final String id;

  /// ID of the activity this point belongs to
  final String activityId;

  /// When this point was recorded
  final Timestamp timestamp;

  /// GPS coordinates of this point
  final Coordinates coordinates;

  /// GPS accuracy in meters (smaller is better)
  final double accuracy;

  /// Source of the location data
  final LocationSource source;

  /// Sequential order within the activity (0-based)
  final int sequence;

  /// Calculate distance to another track point
  double distanceTo(TrackPoint other) {
    return coordinates.distanceTo(other.coordinates);
  }

  /// Calculate time difference to another track point
  Duration timeDifference(TrackPoint other) {
    return timestamp.difference(other.timestamp);
  }

  /// Calculate speed between this point and another (m/s)
  double speedTo(TrackPoint other) {
    final double distance = distanceTo(other);
    final Duration timeDiff = timeDifference(other);
    final double seconds = timeDiff.inMilliseconds / 1000.0;
    
    if (seconds == 0) return 0.0;
    return distance / seconds;
  }

  /// Create a copy with updated values
  TrackPoint copyWith({
    String? id,
    String? activityId,
    Timestamp? timestamp,
    Coordinates? coordinates,
    double? accuracy,
    LocationSource? source,
    int? sequence,
  }) {
    return TrackPoint(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timestamp: timestamp ?? this.timestamp,
      coordinates: coordinates ?? this.coordinates,
      accuracy: accuracy ?? this.accuracy,
      source: source ?? this.source,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activityId == other.activityId &&
          timestamp == other.timestamp &&
          coordinates == other.coordinates &&
          accuracy == other.accuracy &&
          source == other.source &&
          sequence == other.sequence;

  @override
  int get hashCode => Object.hash(
        id,
        activityId,
        timestamp,
        coordinates,
        accuracy,
        source,
        sequence,
      );

  @override
  String toString() => 'TrackPoint(id: $id, sequence: $sequence, coordinates: $coordinates, accuracy: ${accuracy}m)';
}