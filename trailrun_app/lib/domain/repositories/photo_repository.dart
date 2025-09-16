import '../models/photo.dart';

/// Repository interface for managing photos
abstract class PhotoRepository {
  /// Create a new photo record
  Future<Photo> createPhoto(Photo photo);

  /// Update an existing photo
  Future<Photo> updatePhoto(Photo photo);

  /// Get photo by ID
  Future<Photo?> getPhoto(String photoId);

  /// Get all photos for an activity
  Future<List<Photo>> getPhotosForActivity(String activityId);

  /// Get photos sorted by timestamp
  Future<List<Photo>> getPhotosSortedByTime(String activityId);

  /// Get photos with high curation scores (cover candidates)
  Future<List<Photo>> getCoverCandidates(String activityId, {double minScore = 0.7});

  /// Delete a photo and its files
  Future<void> deletePhoto(String photoId);

  /// Delete all photos for an activity
  Future<void> deletePhotosForActivity(String activityId);

  /// Watch photos for an activity (stream)
  Stream<List<Photo>> watchPhotosForActivity(String activityId);

  /// Save photo file to storage
  Future<String> savePhotoFile(String activityId, List<int> imageBytes, String extension);

  /// Generate and save thumbnail
  Future<String> generateThumbnail(String photoPath, {int maxWidth = 300, int maxHeight = 300});

  /// Delete photo file from storage
  Future<void> deletePhotoFile(String filePath);

  /// Get photo file as bytes
  Future<List<int>?> getPhotoBytes(String filePath);

  /// Check if photo file exists
  Future<bool> photoFileExists(String filePath);

  /// Get photos that need sync
  Future<List<Photo>> getPhotosNeedingSync();

  /// Mark photo as synced
  Future<void> markPhotoSynced(String photoId);

  /// Mark photo as sync failed
  Future<void> markPhotoSyncFailed(String photoId, String error);

  /// Update photo curation score
  Future<void> updateCurationScore(String photoId, double score);

  /// Strip EXIF data from photo
  Future<void> stripExifData(String photoId);

  /// Get photo storage statistics
  Future<PhotoStorageStats> getStorageStats();

  /// Cleanup orphaned photo files
  Future<int> cleanupOrphanedFiles();
}

/// Photo storage statistics
class PhotoStorageStats {
  const PhotoStorageStats({
    required this.totalPhotos,
    required this.totalSizeBytes,
    required this.thumbnailCount,
    required this.orphanedFiles,
  });

  final int totalPhotos;
  final int totalSizeBytes;
  final int thumbnailCount;
  final int orphanedFiles;
}