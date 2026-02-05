import '../../domain/models/photo.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/repositories/photo_repository.dart';
import '../database/daos/photo_dao.dart';
import '../services/photo_service.dart';
import 'package:uuid/uuid.dart';

/// Implementation of PhotoRepository using local database and file storage
class PhotoRepositoryImpl implements PhotoRepository {
  const PhotoRepositoryImpl({
    required this.photoDao,
  });

  final PhotoDao photoDao;

  @override
  Future<Photo> createPhoto(Photo photo) async {
    try {
      final entity = photoDao.toEntity(photo);
      await photoDao.createPhoto(entity);
      return photo;
    } catch (e) {
      throw PhotoRepositoryException('Failed to create photo: $e');
    }
  }

  @override
  Future<Photo> updatePhoto(Photo photo) async {
    try {
      final entity = photoDao.toEntity(photo);
      final updated = await photoDao.updatePhoto(entity);
      if (!updated) {
        throw PhotoRepositoryException('Photo not found for update: ${photo.id}');
      }
      return photo;
    } catch (e) {
      throw PhotoRepositoryException('Failed to update photo: $e');
    }
  }

  @override
  Future<Photo?> getPhoto(String photoId) async {
    try {
      final entity = await photoDao.getPhotoById(photoId);
      return entity != null ? photoDao.fromEntity(entity) : null;
    } catch (e) {
      throw PhotoRepositoryException('Failed to get photo: $e');
    }
  }

  @override
  Future<List<Photo>> getPhotosForActivity(String activityId) async {
    try {
      final entities = await photoDao.getPhotosForActivity(activityId);
      return entities.map(photoDao.fromEntity).toList();
    } catch (e) {
      throw PhotoRepositoryException('Failed to get photos for activity: $e');
    }
  }

  @override
  Future<List<Photo>> getPhotosSortedByTime(String activityId) async {
    try {
      final entities = await photoDao.getPhotosForActivity(activityId);
      return entities.map(photoDao.fromEntity).toList();
    } catch (e) {
      throw PhotoRepositoryException('Failed to get photos sorted by time: $e');
    }
  }

  @override
  Future<List<Photo>> getCoverCandidates(String activityId, {double minScore = 0.7}) async {
    try {
      final entities = await photoDao.getCoverCandidatePhotos(
        activityId: activityId,
        minCurationScore: minScore,
      );
      return entities.map(photoDao.fromEntity).toList();
    } catch (e) {
      throw PhotoRepositoryException('Failed to get cover candidates: $e');
    }
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    try {
      // Get photo to find file paths
      final photo = await getPhoto(photoId);
      if (photo == null) {
        throw PhotoRepositoryException('Photo not found for deletion: $photoId');
      }

      // Delete files first
      await PhotoService.deletePhotoFiles(photo.filePath, photo.thumbnailPath);

      // Delete database record
      await photoDao.deletePhoto(photoId);
    } catch (e) {
      throw PhotoRepositoryException('Failed to delete photo: $e');
    }
  }

  @override
  Future<void> deletePhotosForActivity(String activityId) async {
    try {
      // Get all photos for the activity to delete files
      final photos = await getPhotosForActivity(activityId);
      
      // Delete all files
      for (final photo in photos) {
        await PhotoService.deletePhotoFiles(photo.filePath, photo.thumbnailPath);
      }

      // Delete database records
      await photoDao.deletePhotosForActivity(activityId);
    } catch (e) {
      throw PhotoRepositoryException('Failed to delete photos for activity: $e');
    }
  }

  @override
  Stream<List<Photo>> watchPhotosForActivity(String activityId) {
    try {
      return photoDao.watchPhotosForActivity(activityId)
          .map((entities) => entities.map(photoDao.fromEntity).toList());
    } catch (e) {
      throw PhotoRepositoryException('Failed to watch photos for activity: $e');
    }
  }

  @override
  Future<String> savePhotoFile(String activityId, List<int> imageBytes, String extension) async {
    try {
      final photoId = const Uuid().v4();
      return await PhotoService.savePhotoFile(
        activityId: activityId,
        photoId: photoId,
        imageBytes: imageBytes,
        extension: extension,
      );
    } catch (e) {
      throw PhotoRepositoryException('Failed to save photo file: $e');
    }
  }

  @override
  Future<String> generateThumbnail(String photoPath, {int maxWidth = 300, int maxHeight = 300}) async {
    try {
      return await PhotoService.generateThumbnail(
        photoPath,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (e) {
      throw PhotoRepositoryException('Failed to generate thumbnail: $e');
    }
  }

  @override
  Future<void> deletePhotoFile(String filePath) async {
    try {
      await PhotoService.deletePhotoFiles(filePath, null);
    } catch (e) {
      throw PhotoRepositoryException('Failed to delete photo file: $e');
    }
  }

  @override
  Future<List<int>?> getPhotoBytes(String filePath) async {
    try {
      final bytes = await PhotoService.getPhotoBytes(filePath);
      return bytes?.toList();
    } catch (e) {
      throw PhotoRepositoryException('Failed to get photo bytes: $e');
    }
  }

  @override
  Future<bool> photoFileExists(String filePath) async {
    try {
      return await PhotoService.photoFileExists(filePath);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Photo>> getPhotosNeedingSync() async {
    try {
      final entities = await photoDao.getAllPhotos();
      final photos = entities.map(photoDao.fromEntity).toList();
      return photos.where((photo) => !photo.syncState.isSynced).toList();
    } catch (e) {
      throw PhotoRepositoryException('Failed to get photos needing sync: $e');
    }
  }

  @override
  Future<void> markPhotoSynced(String photoId) async {
    try {
      final entity = await photoDao.getPhotoById(photoId);
      if (entity == null) {
        throw PhotoRepositoryException('Photo not found: $photoId');
      }
      await photoDao.updatePhotoSyncState(photoId, SyncState.synced);
    } catch (e) {
      throw PhotoRepositoryException('Failed to mark photo as synced: $e');
    }
  }

  @override
  Future<void> markPhotoSyncFailed(String photoId, String error) async {
    try {
      final entity = await photoDao.getPhotoById(photoId);
      if (entity == null) {
        throw PhotoRepositoryException('Photo not found: $photoId');
      }
      await photoDao.updatePhotoSyncState(photoId, SyncState.failed);
    } catch (e) {
      throw PhotoRepositoryException('Failed to mark photo sync as failed: $e');
    }
  }

  @override
  Future<void> updateCurationScore(String photoId, double score) async {
    try {
      await photoDao.updatePhotoCurationScore(photoId, score);
    } catch (e) {
      throw PhotoRepositoryException('Failed to update curation score: $e');
    }
  }

  @override
  Future<void> stripExifData(String photoId) async {
    try {
      final photo = await getPhoto(photoId);
      if (photo == null) {
        throw PhotoRepositoryException('Photo not found for EXIF stripping: $photoId');
      }

      await PhotoService.stripExifData(photo.filePath);
      
      // Update database to reflect that EXIF data has been stripped
      final updatedPhoto = photo.copyWith(hasExifData: false);
      await updatePhoto(updatedPhoto);
    } catch (e) {
      throw PhotoRepositoryException('Failed to strip EXIF data: $e');
    }
  }

  @override
  Future<PhotoStorageStats> getStorageStats() async {
    try {
      final entities = await photoDao.getAllPhotos();
      final allPhotos = entities.map(photoDao.fromEntity).toList();
      
      int totalSizeBytes = 0;
      int thumbnailCount = 0;
      
      for (final photo in allPhotos) {
        final size = await PhotoService.getPhotoFileSize(photo.filePath);
        totalSizeBytes += size;
        
        if (photo.hasThumbnail) {
          thumbnailCount++;
        }
      }

      // Get orphaned files count
      final validPaths = allPhotos.map((p) => p.filePath).toList();
      final orphanedFiles = await PhotoService.cleanupOrphanedFiles(validPaths);

      return PhotoStorageStats(
        totalPhotos: allPhotos.length,
        totalSizeBytes: totalSizeBytes,
        thumbnailCount: thumbnailCount,
        orphanedFiles: orphanedFiles,
      );
    } catch (e) {
      throw PhotoRepositoryException('Failed to get storage stats: $e');
    }
  }

  @override
  Future<int> cleanupOrphanedFiles() async {
    try {
      final entities = await photoDao.getAllPhotos();
      final validPaths = entities.map((e) => e.filePath).toList();
      return await PhotoService.cleanupOrphanedFiles(validPaths);
    } catch (e) {
      throw PhotoRepositoryException('Failed to cleanup orphaned files: $e');
    }
  }
}

/// Exception thrown by PhotoRepository operations
class PhotoRepositoryException implements Exception {
  const PhotoRepositoryException(this.message);
  
  final String message;
  
  @override
  String toString() => 'PhotoRepositoryException: $message';
}
