import 'package:drift/drift.dart';

/// Database table for storing activity records
@DataClassName('ActivityEntity')
class ActivitiesTable extends Table {
  @override
  String get tableName => 'activities';

  /// Unique identifier for the activity
  TextColumn get id => text()();

  /// When the activity started (milliseconds since epoch)
  IntColumn get startTime => integer().named('start_time')();

  /// When the activity ended (milliseconds since epoch, null if in progress)
  IntColumn get endTime => integer().named('end_time').nullable()();

  /// Total distance covered in meters
  RealColumn get distanceMeters => real().named('distance_meters').withDefault(const Constant(0.0))();

  /// Total duration in seconds (calculated from start/end time)
  IntColumn get durationSeconds => integer().named('duration_seconds').withDefault(const Constant(0))();

  /// Total elevation gained in meters
  RealColumn get elevationGainMeters => real().named('elevation_gain_meters').withDefault(const Constant(0.0))();

  /// Total elevation lost in meters
  RealColumn get elevationLossMeters => real().named('elevation_loss_meters').withDefault(const Constant(0.0))();

  /// Average pace in seconds per kilometer
  RealColumn get averagePaceSecondsPerKm => real().named('average_pace_seconds_per_km').nullable()();

  /// User-provided title for the activity
  TextColumn get title => text()();

  /// Optional user notes about the activity
  TextColumn get notes => text().nullable()();

  /// Privacy level (0=private, 1=friends, 2=public)
  IntColumn get privacyLevel => integer().named('privacy_level').withDefault(const Constant(0))();

  /// ID of the photo to use as cover image
  TextColumn get coverPhotoId => text().named('cover_photo_id').nullable()();

  /// Current synchronization state (0=local, 1=pending, 2=syncing, 3=synced, 4=failed, 5=conflict)
  IntColumn get syncState => integer().named('sync_state').withDefault(const Constant(0))();

  /// When this record was created (milliseconds since epoch)
  IntColumn get createdAt => integer().named('created_at')();

  /// When this record was last updated (milliseconds since epoch)
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (start_time > 0)',
    'CHECK (end_time IS NULL OR end_time >= start_time)',
    'CHECK (distance_meters >= 0)',
    'CHECK (duration_seconds >= 0)',
    'CHECK (elevation_gain_meters >= 0)',
    'CHECK (elevation_loss_meters >= 0)',
    'CHECK (average_pace_seconds_per_km IS NULL OR average_pace_seconds_per_km > 0)',
    'CHECK (privacy_level IN (0, 1, 2))',
    'CHECK (sync_state IN (0, 1, 2, 3, 4, 5))',
    'CHECK (created_at > 0)',
    'CHECK (updated_at > 0)',
  ];
}