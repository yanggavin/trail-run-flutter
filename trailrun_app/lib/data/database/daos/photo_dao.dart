import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/photos_table.dart';
import '../../../domain/models/photo.dart';
import '../../../domain/enums/sync_state.dart';
import '../../../domain/value_objects/coordinates.dart';
import '../../../domain/value_objects/timestamp.dart';

part 'photo_dao.g.dart';

/// Data Access Object for Photo operations
@DriftAccessor(tables: [PhotosTable])
class PhotoDao extends DatabaseAccessor<TrailRunDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  /// Get all photos for an activity ordered by timestamp
  Future<List<PhotoEntity>> getPhotosForActivity(String activityId) {
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .get();
  }

  /// Get photos for activity with pagination
  Future<List<PhotoEntity>> getPhotosPaginated({
    required String activityId,
    required int limit,
    required int offset,
  }) {
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
      ..limit(limit, offset: offset))
      .get();
  }

  /// Get photo by ID
  Future<PhotoEntity?> getPhotoById(String id) {
    return (select(photosTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get photos with location data for an activity
  Future<List<PhotoEntity>> getGeotaggedPhotos(String activityId) {
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.latitude.isNotNull() & 
                     t.longitude.isNotNull())
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .get();
  }

  /// Get photos with high curation scores (suitable for covers)
  Future<List<PhotoEntity>> getCoverCandidatePhotos({
    required String activityId,
    double minCurationScore = 0.7,
  }) {
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.curationScore.isBiggerOrEqualValue(minCurationScore))
      ..orderBy([(t) => OrderingTerm.desc(t.curationScore)]))
      .get();
  }

  /// Get photos within time range for an activity
  Future<List<PhotoEntity>> getPhotosInTimeRange({
    required String activityId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final startMillis = startTime.millisecondsSinceEpoch;
    final endMillis = endTime.millisecondsSinceEpoch;
    
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.timestamp.isBetweenValues(startMillis, endMillis))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .get();
  }

  /// Get photos count for an activity
  Future<int> getPhotosCount(String activityId) async {
    final query = selectOnly(photosTable)
      ..addColumns([photosTable.id.count()])
      ..where(photosTable.activityId.equals(activityId));
    final result = await query.getSingle();
    return result.read(photosTable.id.count()) ?? 0;
  }

  /// Get total photos count (all activities)
  Future<int> getTotalPhotosCount() async {
    final query = selectOnly(photosTable)
      ..addColumns([photosTable.id.count()]);
    final result = await query.getSingle();
    return result.read(photosTable.id.count()) ?? 0;
  }

  /// Get all photos
  Future<List<PhotoEntity>> getAllPhotos() {
    return (select(photosTable)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .get();
  }

  /// Search photos by caption
  Future<List<PhotoEntity>> searchPhotosByCaption({
    required String activityId,
    required String query,
  }) {
    final searchTerm = '%$query%';
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId) & 
                     t.caption.like(searchTerm))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .get();
  }

  /// Create new photo
  Future<int> createPhoto(PhotoEntity photo) {
    return into(photosTable).insert(photo);
  }

  /// Create multiple photos in batch
  Future<void> createPhotosBatch(List<PhotoEntity> photos) {
    return batch((batch) {
      batch.insertAll(photosTable, photos);
    });
  }

  /// Update existing photo
  Future<bool> updatePhoto(PhotoEntity photo) {
    return update(photosTable).replace(photo);
  }

  /// Update photo curation score
  Future<int> updatePhotoCurationScore(String id, double curationScore) {
    return (update(photosTable)..where((t) => t.id.equals(id)))
      .write(PhotosTableCompanion(
        curationScore: Value(curationScore),
      ));
  }

  /// Update photo caption
  Future<int> updatePhotoCaption(String id, String? caption) {
    return (update(photosTable)..where((t) => t.id.equals(id)))
      .write(PhotosTableCompanion(
        caption: Value(caption),
      ));
  }

  /// Update photo sync state
  Future<int> updatePhotoSyncState(String id, SyncState syncState) {
    return (update(photosTable)..where((t) => t.id.equals(id)))
      .write(PhotosTableCompanion(
        syncState: Value(syncState.index),
      ));
  }

  /// Delete photo by ID
  Future<int> deletePhoto(String id) {
    return (delete(photosTable)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all photos for an activity
  Future<int> deletePhotosForActivity(String activityId) {
    return (delete(photosTable)..where((t) => t.activityId.equals(activityId))).go();
  }

  /// Delete photos older than specified date
  Future<int> deletePhotosOlderThan(DateTime cutoffDate) {
    final cutoffMillis = cutoffDate.millisecondsSinceEpoch;
    return (delete(photosTable)..where((t) => t.timestamp.isSmallerThanValue(cutoffMillis))).go();
  }

  /// Watch photos for an activity
  Stream<List<PhotoEntity>> watchPhotosForActivity(String activityId) {
    return (select(photosTable)
      ..where((t) => t.activityId.equals(activityId))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .watch();
  }

  /// Watch photo by ID
  Stream<PhotoEntity?> watchPhotoById(String id) {
    return (select(photosTable)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Convert domain Photo to database entity
  PhotoEntity toEntity(Photo photo) {
    return PhotoEntity(
      id: photo.id,
      activityId: photo.activityId,
      timestamp: photo.timestamp.millisecondsSinceEpoch,
      latitude: photo.coordinates?.latitude,
      longitude: photo.coordinates?.longitude,
      elevation: photo.coordinates?.elevation,
      filePath: photo.filePath,
      thumbnailPath: photo.thumbnailPath,
      hasExifData: photo.hasExifData,
      curationScore: photo.curationScore,
      caption: photo.caption,
      syncState: photo.syncState.index,
    );
  }

  /// Convert database entity to domain Photo
  Photo fromEntity(PhotoEntity entity) {
    return Photo(
      id: entity.id,
      activityId: entity.activityId,
      timestamp: Timestamp.fromMilliseconds(entity.timestamp),
      coordinates: (entity.latitude != null && entity.longitude != null)
        ? Coordinates(
            latitude: entity.latitude!,
            longitude: entity.longitude!,
            elevation: entity.elevation,
          )
        : null,
      filePath: entity.filePath,
      thumbnailPath: entity.thumbnailPath,
      hasExifData: entity.hasExifData,
      curationScore: entity.curationScore,
      caption: entity.caption,
      syncState: SyncState.values[entity.syncState],
    );
  }
}
