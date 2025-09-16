import 'dart:async';

import '../../domain/models/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/value_objects/coordinates.dart';
import 'camera_service.dart';
import 'photo_service.dart';

/// Manager for photo operations during activity tracking
class PhotoManager {
  const PhotoManager({
    required this.photoRepository,
    required this.cameraService,
  });

  final PhotoRepository photoRepository;
  final CameraService cameraService;

  /// Initialize photo manager
  Future<void> initialize() async {
    await cameraService.initialize();
  }

  /// Capture photo during active tracking session
  Future<Photo> capturePhotoForActivity({
    required String activityId,
    Coordinates? currentLocation,
  }) async {
    try {
      // Capture photo with camera service
      final photo = await cameraService.capturePhotoForActivity(
        activityId: activityId,
        currentLocation: currentLocation,
      );

      // Save photo to repository
      final savedPhoto = await photoRepository.createPhoto(photo);

      // Calculate and update curation score asynchronously
      _updateCurationScoreAsync(savedPhoto.id, savedPhoto.filePath);

      return savedPhoto;
    } catch (e) {
      throw PhotoManagerException('Failed to capture photo for activity: $e');
    }
  }

  /// Get photos for an activity
  Future<List<Photo>> getPhotosForActivity(String activityId) async {
    try {
      return await photoRepository.getPhotosForActivity(activityId);
    } catch (e) {
      throw PhotoManagerException('Failed to get photos for activity: $e');
    }
  }

  /// Watch photos for an activity (stream)
  Stream<List<Photo>> watchPhotosForActivity(String activityId) {
    try {
      return photoRepository.watchPhotosForActivity(activityId);
    } catch (e) {
      throw PhotoManagerException('Failed to watch photos for activity: $e');
    }
  }

  /// Get cover photo candidates for an activity
  Future<List<Photo>> getCoverCandidates(String activityId) async {
    try {
      return await photoRepository.getCoverCandidates(activityId);
    } catch (e) {
      throw PhotoManagerException('Failed to get cover candidates: $e');
    }
  }

  /// Update photo caption
  Future<void> updatePhotoCaption(String photoId, String? caption) async {
    try {
      final photo = await photoRepository.getPhoto(photoId);
      if (photo == null) {
        throw PhotoManagerException('Photo not found: $photoId');
      }

      final updatedPhoto = photo.copyWith(caption: caption);
      await photoRepository.updatePhoto(updatedPhoto);
    } catch (e) {
      throw PhotoManagerException('Failed to update photo caption: $e');
    }
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId) async {
    try {
      await photoRepository.deletePhoto(photoId);
    } catch (e) {
      throw PhotoManagerException('Failed to delete photo: $e');
    }
  }

  /// Delete all photos for an activity
  Future<void> deletePhotosForActivity(String activityId) async {
    try {
      await photoRepository.deletePhotosForActivity(activityId);
    } catch (e) {
      throw PhotoManagerException('Failed to delete photos for activity: $e');
    }
  }

  /// Strip EXIF data from photo for privacy
  Future<void> stripExifData(String photoId) async {
    try {
      await photoRepository.stripExifData(photoId);
    } catch (e) {
      throw PhotoManagerException('Failed to strip EXIF data: $e');
    }
  }

  /// Strip EXIF data from all photos in an activity
  Future<void> stripExifDataForActivity(String activityId) async {
    try {
      final photos = await getPhotosForActivity(activityId);
      
      for (final photo in photos) {
        if (photo.hasExifData) {
          await stripExifData(photo.id);
        }
      }
    } catch (e) {
      throw PhotoManagerException('Failed to strip EXIF data for activity: $e');
    }
  }

  /// Get photo file bytes
  Future<List<int>?> getPhotoBytes(String photoId) async {
    try {
      final photo = await photoRepository.getPhoto(photoId);
      if (photo == null) return null;

      return await photoRepository.getPhotoBytes(photo.filePath);
    } catch (e) {
      throw PhotoManagerException('Failed to get photo bytes: $e');
    }
  }

  /// Check if photo file exists
  Future<bool> photoExists(String photoId) async {
    try {
      final photo = await photoRepository.getPhoto(photoId);
      if (photo == null) return false;

      return await photoRepository.photoFileExists(photo.filePath);
    } catch (e) {
      return false;
    }
  }

  /// Get photos within time range
  Future<List<Photo>> getPhotosInTimeRange({
    required String activityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final allPhotos = await getPhotosForActivity(activityId);
      
      return allPhotos.where((photo) {
        final photoTime = photo.timestamp.dateTime;
        return photoTime.isAfter(startTime) && photoTime.isBefore(endTime);
      }).toList();
    } catch (e) {
      throw PhotoManagerException('Failed to get photos in time range: $e');
    }
  }

  /// Get geotagged photos for an activity
  Future<List<Photo>> getGeotaggedPhotos(String activityId) async {
    try {
      final photos = await getPhotosForActivity(activityId);
      return photos.where((photo) => photo.hasLocation).toList();
    } catch (e) {
      throw PhotoManagerException('Failed to get geotagged photos: $e');
    }
  }

  /// Get photo storage statistics
  Future<PhotoStorageStats> getStorageStats() async {
    try {
      return await photoRepository.getStorageStats();
    } catch (e) {
      throw PhotoManagerException('Failed to get storage stats: $e');
    }
  }

  /// Cleanup orphaned photo files
  Future<int> cleanupOrphanedFiles() async {
    try {
      return await photoRepository.cleanupOrphanedFiles();
    } catch (e) {
      throw PhotoManagerException('Failed to cleanup orphaned files: $e');
    }
  }

  /// Update curation score asynchronously
  Future<void> _updateCurationScoreAsync(String photoId, String filePath) async {
    try {
      final score = await PhotoService.calculateCurationScore(filePath);
      await photoRepository.updateCurationScore(photoId, score);
    } catch (e) {
      print('Warning: Failed to update curation score for photo $photoId: $e');
    }
  }

  /// Batch process photos for curation scores
  Future<void> updateCurationScores(String activityId) async {
    try {
      final photos = await getPhotosForActivity(activityId);
      
      for (final photo in photos) {
        await _updateCurationScoreAsync(photo.id, photo.filePath);
      }
    } catch (e) {
      throw PhotoManagerException('Failed to update curation scores: $e');
    }
  }

  /// Get best photo for activity cover
  Future<Photo?> getBestCoverPhoto(String activityId) async {
    try {
      final candidates = await getCoverCandidates(activityId);
      if (candidates.isEmpty) {
        // If no high-scoring photos, get the best available
        final allPhotos = await getPhotosForActivity(activityId);
        if (allPhotos.isEmpty) return null;
        
        allPhotos.sort((a, b) => b.curationScore.compareTo(a.curationScore));
        return allPhotos.first;
      }
      
      return candidates.first; // Already sorted by score
    } catch (e) {
      throw PhotoManagerException('Failed to get best cover photo: $e');
    }
  }

  /// Dispose photo manager resources
  Future<void> dispose() async {
    await cameraService.dispose();
  }
}

/// Exception thrown by PhotoManager operations
class PhotoManagerException implements Exception {
  const PhotoManagerException(this.message);
  
  final String message;
  
  @override
  String toString() => 'PhotoManagerException: $message';
}