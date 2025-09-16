import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/value_objects/coordinates.dart';
import '../database/database_provider.dart';
import '../repositories/photo_repository_impl.dart';
import 'camera_service.dart';
import 'photo_manager.dart';

/// Provider for PhotoRepository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PhotoRepositoryImpl(
    photoDao: database.photoDao,
  );
});

/// Provider for CameraService
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService.instance;
});

/// Provider for PhotoManager
final photoManagerProvider = Provider<PhotoManager>((ref) {
  final photoRepository = ref.watch(photoRepositoryProvider);
  final cameraService = ref.watch(cameraServiceProvider);
  
  return PhotoManager(
    photoRepository: photoRepository,
    cameraService: cameraService,
  );
});

/// Provider for photos of a specific activity
final photosForActivityProvider = StreamProvider.family<List<Photo>, String>((ref, activityId) {
  final photoManager = ref.watch(photoManagerProvider);
  return photoManager.watchPhotosForActivity(activityId);
});

/// Provider for cover photo candidates of an activity
final coverCandidatesProvider = FutureProvider.family<List<Photo>, String>((ref, activityId) {
  final photoManager = ref.watch(photoManagerProvider);
  return photoManager.getCoverCandidates(activityId);
});

/// Provider for best cover photo of an activity
final bestCoverPhotoProvider = FutureProvider.family<Photo?, String>((ref, activityId) {
  final photoManager = ref.watch(photoManagerProvider);
  return photoManager.getBestCoverPhoto(activityId);
});

/// Provider for geotagged photos of an activity
final geotaggedPhotosProvider = FutureProvider.family<List<Photo>, String>((ref, activityId) {
  final photoManager = ref.watch(photoManagerProvider);
  return photoManager.getGeotaggedPhotos(activityId);
});

/// Provider for photo storage statistics
final photoStorageStatsProvider = FutureProvider<PhotoStorageStats>((ref) {
  final photoManager = ref.watch(photoManagerProvider);
  return photoManager.getStorageStats();
});

/// Provider for camera initialization state
final cameraInitializationProvider = FutureProvider<void>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return cameraService.initialize();
});

/// Provider for camera controller state
final cameraControllerProvider = Provider<CameraController?>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return cameraService.controller;
});

/// Provider for camera capabilities
final cameraCapabilitiesProvider = Provider<CameraCapabilities?>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return cameraService.capabilities;
});

/// State notifier for photo capture operations
class PhotoCaptureNotifier extends StateNotifier<AsyncValue<Photo?>> {
  PhotoCaptureNotifier(this._photoManager) : super(const AsyncValue.data(null));

  final PhotoManager _photoManager;

  /// Capture photo for activity
  Future<void> capturePhoto({
    required String activityId,
    required Coordinates? currentLocation,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final photo = await _photoManager.capturePhotoForActivity(
        activityId: activityId,
        currentLocation: currentLocation,
      );
      state = AsyncValue.data(photo);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear capture state
  void clearState() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for photo capture operations
final photoCaptureProvider = StateNotifierProvider<PhotoCaptureNotifier, AsyncValue<Photo?>>((ref) {
  final photoManager = ref.watch(photoManagerProvider);
  return PhotoCaptureNotifier(photoManager);
});

/// State notifier for photo management operations
class PhotoManagementNotifier extends StateNotifier<AsyncValue<void>> {
  PhotoManagementNotifier(this._photoManager) : super(const AsyncValue.data(null));

  final PhotoManager _photoManager;

  /// Update photo caption
  Future<void> updateCaption(String photoId, String? caption) async {
    state = const AsyncValue.loading();
    
    try {
      await _photoManager.updatePhotoCaption(photoId, caption);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId) async {
    state = const AsyncValue.loading();
    
    try {
      await _photoManager.deletePhoto(photoId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Strip EXIF data from photo
  Future<void> stripExifData(String photoId) async {
    state = const AsyncValue.loading();
    
    try {
      await _photoManager.stripExifData(photoId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Strip EXIF data from all photos in activity
  Future<void> stripExifDataForActivity(String activityId) async {
    state = const AsyncValue.loading();
    
    try {
      await _photoManager.stripExifDataForActivity(activityId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update curation scores for activity
  Future<void> updateCurationScores(String activityId) async {
    state = const AsyncValue.loading();
    
    try {
      await _photoManager.updateCurationScores(activityId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Cleanup orphaned files
  Future<int> cleanupOrphanedFiles() async {
    state = const AsyncValue.loading();
    
    try {
      final count = await _photoManager.cleanupOrphanedFiles();
      state = const AsyncValue.data(null);
      return count;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return 0;
    }
  }
}

/// Provider for photo management operations
final photoManagementProvider = StateNotifierProvider<PhotoManagementNotifier, AsyncValue<void>>((ref) {
  final photoManager = ref.watch(photoManagerProvider);
  return PhotoManagementNotifier(photoManager);
});