import 'package:drift/drift.dart';

/// Database table for storing per-kilometer split data
@DataClassName('SplitEntity')
class SplitsTable extends Table {
  @override
  String get tableName => 'splits';

  /// Unique identifier for the split
  TextColumn get id => text()();

  /// ID of the activity this split belongs to
  TextColumn get activityId => text().named('activity_id')();

  /// Split number (1-based, e.g., 1st km, 2nd km)
  IntColumn get splitNumber => integer().named('split_number')();

  /// When this split started (milliseconds since epoch)
  IntColumn get startTime => integer().named('start_time')();

  /// When this split ended (milliseconds since epoch)
  IntColumn get endTime => integer().named('end_time')();

  /// Distance covered in this split (meters)
  RealColumn get distanceMeters => real().named('distance_meters')();

  /// Average pace for this split (seconds per kilometer)
  RealColumn get paceSecondsPerKm => real().named('pace_seconds_per_km')();

  /// Elevation gained during this split (meters)
  RealColumn get elevationGainMeters => real().named('elevation_gain_meters').withDefault(const Constant(0.0))();

  /// Elevation lost during this split (meters)
  RealColumn get elevationLossMeters => real().named('elevation_loss_meters').withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (split_number > 0)',
    'CHECK (start_time > 0)',
    'CHECK (end_time > start_time)',
    'CHECK (distance_meters > 0)',
    'CHECK (pace_seconds_per_km > 0)',
    'CHECK (elevation_gain_meters >= 0)',
    'CHECK (elevation_loss_meters >= 0)',
    'UNIQUE (activity_id, split_number)',
  ];
}

