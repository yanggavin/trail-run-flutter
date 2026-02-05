import 'package:drift/drift.dart';

/// Database table for storing photo metadata
@DataClassName('PhotoEntity')
class PhotosTable extends Table {
  @override
  String get tableName => 'photos';

  /// Unique identifier for the photo
  TextColumn get id => text()();

  /// ID of the activity this photo belongs to
  TextColumn get activityId => text().named('activity_id')();

  /// When this photo was captured (milliseconds since epoch)
  IntColumn get timestamp => integer()();

  /// Latitude coordinate where photo was taken (nullable if not available)
  RealColumn get latitude => real().nullable()();

  /// Longitude coordinate where photo was taken (nullable if not available)
  RealColumn get longitude => real().nullable()();

  /// Elevation where photo was taken (nullable if not available)
  RealColumn get elevation => real().nullable()();

  /// File path to the full-size photo
  TextColumn get filePath => text().named('file_path')();

  /// File path to the thumbnail (nullable if not generated)
  TextColumn get thumbnailPath => text().named('thumbnail_path').nullable()();

  /// Whether the photo contains EXIF metadata
  BoolColumn get hasExifData => boolean().named('has_exif_data').withDefault(const Constant(false))();

  /// AI-generated curation score (0.0-1.0, higher is better for highlights)
  RealColumn get curationScore => real().named('curation_score').withDefault(const Constant(0.0))();

  /// Optional user-provided caption
  TextColumn get caption => text().nullable()();

  /// Sync state of the photo (0: pending, 1: synced, 2: failed)
  IntColumn get syncState => integer().named('sync_state').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90))',
    'CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))',
    'CHECK (curation_score >= 0.0 AND curation_score <= 1.0)',
    'CHECK (timestamp > 0)',
    'CHECK (file_path != "")',
  ];
}

