import '../value_objects/measurement_units.dart';
import '../value_objects/timestamp.dart';

/// Per-kilometer split data for activity analysis
class Split {
  const Split({
    required this.id,
    required this.activityId,
    required this.splitNumber,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.pace,
    required this.elevationGain,
    required this.elevationLoss,
  });

  /// Unique identifier for this split
  final String id;

  /// ID of the activity this split belongs to
  final String activityId;

  /// Split number (1-based, e.g., 1st km, 2nd km)
  final int splitNumber;

  /// When this split started
  final Timestamp startTime;

  /// When this split ended
  final Timestamp endTime;

  /// Distance covered in this split
  final Distance distance;

  /// Average pace for this split
  final Pace pace;

  /// Elevation gained during this split
  final Elevation elevationGain;

  /// Elevation lost during this split
  final Elevation elevationLoss;

  /// Duration of this split
  Duration get duration => endTime.difference(startTime);

  /// Net elevation change (positive = gain, negative = loss)
  Elevation get netElevationChange => elevationGain - elevationLoss;

  /// Check if this is a complete kilometer split
  bool get isCompleteKilometer => distance.kilometers >= 0.99;

  /// Check if this split is faster than another
  bool isFasterThan(Split other) {
    return pace.secondsPerKilometer < other.pace.secondsPerKilometer;
  }

  /// Check if this split has significant elevation change
  bool get hasSignificantElevation {
    return elevationGain.meters > 10 || elevationLoss.meters > 10;
  }

  /// Create a copy with updated values
  Split copyWith({
    String? id,
    String? activityId,
    int? splitNumber,
    Timestamp? startTime,
    Timestamp? endTime,
    Distance? distance,
    Pace? pace,
    Elevation? elevationGain,
    Elevation? elevationLoss,
  }) {
    return Split(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      splitNumber: splitNumber ?? this.splitNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      pace: pace ?? this.pace,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Split &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activityId == other.activityId &&
          splitNumber == other.splitNumber &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          distance == other.distance &&
          pace == other.pace &&
          elevationGain == other.elevationGain &&
          elevationLoss == other.elevationLoss;

  @override
  int get hashCode => Object.hash(
        id,
        activityId,
        splitNumber,
        startTime,
        endTime,
        distance,
        pace,
        elevationGain,
        elevationLoss,
      );

  @override
  String toString() => 'Split(#$splitNumber, ${distance.kilometers.toStringAsFixed(2)}km, ${pace.formatMinutesSeconds()}/km)';
}