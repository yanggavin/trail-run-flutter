import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../data/repositories/photo_repository_impl.dart';
import '../../data/database/database_provider.dart';
import '../../data/services/photo_service.dart';
import '../../data/services/photo_provider.dart' as service_provider;

/// Photo state
class PhotoState {
  const PhotoState({
    this.photos = const [],
    this.isLoading = false,
    this.isCapturing = false,
    this.selectedPhoto,
    this.error,
  });

  final List<Photo> photos;
  final bool isLoading;
  final bool isCapturing;
  final Photo? selectedPhoto;
  final String? error;

  PhotoState copyWith({
    List<Photo>? photos,
    bool? isLoading,
    bool? isCapturing,
    Photo? selectedPhoto,
    String? error,
  }) {
    return PhotoState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isCapturing: isCapturing ?? this.isCapturing,
      selectedPhoto: selectedPhoto ?? this.selectedPhoto,
      error: error ?? this.error,
    );
  }
}

/// Photo state notifier
class PhotoNotifier extends StateNotifier<PhotoState> {
  PhotoNotifier(this._photoRepository, this._photoService) : super(const PhotoState());

  final PhotoRepository _photoRepository;
  final PhotoService _photoService;

  Future<void> loadPhotosForActivity(String activityId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final photos = await _photoRepository.getPhotosForActivity(activityId);
      state = state.copyWith(
        photos: photos,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Photo?> capturePhoto(String activityId) async {
    state = state.copyWith(isCapturing: true, error: null);
    
    try {
      final photo = await _photoService.capturePhoto(activityId);
      
      // Add to current photos list
      final updatedPhotos = [...state.photos, photo];
      
      state = state.copyWith(
        photos: updatedPhotos,
        isCapturing: false,
      );
      
      return photo;
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await _photoRepository.deletePhoto(photoId);
      
      // Remove from current photos list
      final updatedPhotos = state.photos
          .where((photo) => photo.id != photoId)
          .toList();
      
      state = state.copyWith(photos: updatedPhotos);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePhoto(Photo photo) async {
    try {
      await _photoRepository.updatePhoto(photo);
      
      // Update in current photos list
      final updatedPhotos = state.photos.map((p) {
        return p.id == photo.id ? photo : p;
      }).toList();
      
      state = state.copyWith(photos: updatedPhotos);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void selectPhoto(Photo? photo) {
    state = state.copyWith(selectedPhoto: photo);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearPhotos() {
    state = state.copyWith(photos: []);
  }
}

/// Provider for photo repository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return PhotoRepositoryImpl(database: database);
});

/// Provider for photo service
final photoServiceProvider = Provider<PhotoService>((ref) {
  return service_provider.PhotoProvider.getInstance();
});

/// Provider for photo state
final photoProvider = StateNotifierProvider<PhotoNotifier, PhotoState>((ref) {
  final photoRepository = ref.watch(photoRepositoryProvider);
  final photoService = ref.watch(photoServiceProvider);
  return PhotoNotifier(photoRepository, photoService);
});

/// Provider for photos of current activity
final currentActivityPhotosProvider = Provider<List<Photo>>((ref) {
  return ref.watch(photoProvider).photos;
});

/// Provider for selected photo
final selectedPhotoProvider = Provider<Photo?>((ref) {
  return ref.watch(photoProvider).selectedPhoto;
});

/// Provider for photo capture state
final isCapturingPhotoProvider = Provider<bool>((ref) {
  return ref.watch(photoProvider).isCapturing;
});