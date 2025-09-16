import 'package:drift/drift.dart';

/// Database table for storing GPS track points
@DataClassName('TrackPointEntity')
class TrackPointsTable extends Table {
  @override
  String get tableName => 'track_points';

  /// Unique identifier for the track point
  TextColumn get id => text()();

  /// ID of the activity this point belongs to
  TextColumn get activityId => text().named('activity_id')();

  /// When this point was recorded (milliseconds since epoch)
  IntColumn get timestamp => integer()();

  /// Latitude coordinate
  RealColumn get latitude => real()();

  /// Longitude coordinate
  RealColumn get longitude => real()();

  /// Elevation in meters (nullable if not available)
  RealColumn get elevation => real().nullable()();

  /// GPS accuracy in meters (smaller is better)
  RealColumn get accuracy => real()();

  /// Source of the location data (0=gps, 1=network, 2=fused, 3=manual, 4=interpolated)
  IntColumn get source => integer()();

  /// Sequential order within the activity (0-based)
  IntColumn get sequence => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (latitude >= -90 AND latitude <= 90)',
    'CHECK (longitude >= -180 AND longitude <= 180)',
    'CHECK (accuracy >= 0)',
    'CHECK (source IN (0, 1, 2, 3, 4))',
    'CHECK (sequence >= 0)',
    'CHECK (timestamp > 0)',
  ];
}

