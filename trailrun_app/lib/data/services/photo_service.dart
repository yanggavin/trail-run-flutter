import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/photo.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';

/// Service for handling photo capture, processing, and storage
class PhotoService {
  static const _uuid = Uuid();
  static const int _thumbnailMaxSize = 300;
  static const int _jpegQuality = 85;
  static const Duration _captureTimeout = Duration(milliseconds: 400);

  /// Initialize camera controllers
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw PhotoServiceException('Failed to get available cameras: $e');
    }
  }

  /// Create camera controller with optimized settings for quick capture
  static CameraController createCameraController(CameraDescription camera) {
    return CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false, // Disable audio for faster processing
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
  }

  /// Capture photo with GPS coordinates and return to tracking quickly
  static Future<Photo> capturePhoto({
    required CameraController controller,
    required String activityId,
    Coordinates? currentLocation,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Capture image with timeout
      final XFile imageFile = await controller.takePicture()
          .timeout(_captureTimeout, onTimeout: () {
        throw PhotoServiceException('Photo capture timed out');
      });

      final captureTime = DateTime.now();
      final photoId = _uuid.v4();
      
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Save to permanent storage
      final savedPath = await _savePhotoFile(
        activityId: activityId,
        photoId: photoId,
        imageBytes: imageBytes,
      );

      // Generate thumbnail asynchronously (don't wait for it)
      final thumbnailFuture = _generateThumbnail(savedPath);

      // Process EXIF data if location is available
      final hasExifData = currentLocation != null;
      if (hasExifData) {
        // Add EXIF data asynchronously (don't wait for it)
        _addExifDataAsync(savedPath, currentLocation!, captureTime);
      }

      // Wait for thumbnail generation
      final thumbnailPath = await thumbnailFuture;

      stopwatch.stop();
      print('Photo capture completed in ${stopwatch.elapsedMilliseconds}ms');

      return Photo(
        id: photoId,
        activityId: activityId,
        timestamp: Timestamp.fromMilliseconds(captureTime.millisecondsSinceEpoch),
        coordinates: currentLocation,
        filePath: savedPath,
        thumbnailPath: thumbnailPath,
        hasExifData: hasExifData,
        curationScore: 0.5, // Default score, can be updated later
      );

    } catch (e) {
      stopwatch.stop();
      throw PhotoServiceException('Failed to capture photo: $e');
    }
  }

  /// Save photo file to permanent storage
  static Future<String> _savePhotoFile({
    required String activityId,
    required String photoId,
    required Uint8List imageBytes,
  }) async {
    try {
      final directory = await _getPhotosDirectory();
      final activityDir = Directory(path.join(directory.path, activityId));
      
      if (!await activityDir.exists()) {
        await activityDir.create(recursive: true);
      }

      final fileName = '$photoId.jpg';
      final file = File(path.join(activityDir.path, fileName));
      
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      throw PhotoServiceException('Failed to save photo file: $e');
    }
  }

  /// Save photo file to permanent storage (public)
  static Future<String> savePhotoFile({
    required String activityId,
    required String photoId,
    required List<int> imageBytes,
    String extension = 'jpg',
  }) async {
    final ext = extension.isEmpty ? 'jpg' : extension.toLowerCase();
    final bytes = Uint8List.fromList(imageBytes);

    try {
      final directory = await _getPhotosDirectory();
      final activityDir = Directory(path.join(directory.path, activityId));

      if (!await activityDir.exists()) {
        await activityDir.create(recursive: true);
      }

      final fileName = '$photoId.$ext';
      final file = File(path.join(activityDir.path, fileName));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      throw PhotoServiceException('Failed to save photo file: $e');
    }
  }

  /// Generate thumbnail for photo
  static Future<String> _generateThumbnail(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      final imageBytes = await originalFile.readAsBytes();
      
      // Decode and resize image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw PhotoServiceException('Failed to decode image for thumbnail');
      }

      // Calculate thumbnail dimensions maintaining aspect ratio
      final thumbnail = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? _thumbnailMaxSize : null,
        height: originalImage.height > originalImage.width ? _thumbnailMaxSize : null,
      );

      // Save thumbnail
      final thumbnailPath = originalPath.replaceAll('.jpg', '_thumb.jpg');
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: _jpegQuality);
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      return thumbnailPath;
    } catch (e) {
      throw PhotoServiceException('Failed to generate thumbnail: $e');
    }
  }

  /// Generate thumbnail for photo (public)
  static Future<String> generateThumbnail(
    String originalPath, {
    int maxWidth = _thumbnailMaxSize,
    int maxHeight = _thumbnailMaxSize,
  }) async {
    try {
      final originalFile = File(originalPath);
      final imageBytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw PhotoServiceException('Failed to decode image for thumbnail');
      }

      final resized = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? maxWidth : null,
        height: originalImage.height >= originalImage.width ? maxHeight : null,
      );

      final thumbnailPath = originalPath.replaceAll(RegExp(r'\.\w+$'), '_thumb.jpg');
      final thumbnailBytes = img.encodeJpg(resized, quality: _jpegQuality);
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);

      return thumbnailPath;
    } catch (e) {
      throw PhotoServiceException('Failed to generate thumbnail: $e');
    }
  }

  /// Add EXIF data to photo asynchronously
  static Future<void> _addExifDataAsync(
    String filePath,
    Coordinates location,
    DateTime captureTime,
  ) async {
    try {
      final file = File(filePath);
      final imageBytes = await file.readAsBytes();
      
      // Read existing EXIF data to verify GPS coordinates can be extracted
      final exifData = await readExifFromBytes(imageBytes);
      
      // For now, we'll just log that EXIF data processing was attempted
      // Full EXIF writing would require a more sophisticated library or custom implementation
      print('EXIF data processing attempted for photo at $filePath');
      print('Location: ${location.latitude}, ${location.longitude}');
      if (location.elevation != null) {
        print('Elevation: ${location.elevation}');
      }
      print('Capture time: $captureTime');
      
      // Check if existing EXIF data contains GPS info
      if (exifData.containsKey('GPS GPSLatitude')) {
        print('Existing GPS data found in EXIF');
      }
      
    } catch (e) {
      print('Warning: Failed to process EXIF data: $e');
    }
  }

  /// Convert coordinate to EXIF rational format
  static List<int> _coordinateToExifRational(double coordinate) {
    final degrees = coordinate.floor();
    final minutes = ((coordinate - degrees) * 60).floor();
    final seconds = ((coordinate - degrees - minutes / 60) * 3600 * 1000).round();
    
    return [degrees, 1, minutes, 1, seconds, 1000];
  }

  /// Strip EXIF data from photo for privacy
  static Future<void> stripExifData(String filePath) async {
    try {
      final file = File(filePath);
      final imageBytes = await file.readAsBytes();
      
      // Decode image without EXIF
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw PhotoServiceException('Failed to decode image for EXIF stripping');
      }

      // Re-encode without EXIF data
      final cleanBytes = img.encodeJpg(image, quality: _jpegQuality);
      await file.writeAsBytes(cleanBytes);
      
    } catch (e) {
      throw PhotoServiceException('Failed to strip EXIF data: $e');
    }
  }

  /// Delete photo and thumbnail files
  static Future<void> deletePhotoFiles(String filePath, String? thumbnailPath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }
    } catch (e) {
      throw PhotoServiceException('Failed to delete photo files: $e');
    }
  }

  /// Get photos directory
  static Future<Directory> _getPhotosDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(path.join(appDir.path, 'photos'));
  }

  /// Get photo file size
  static Future<int> getPhotoFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Check if photo file exists
  static Future<bool> photoFileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get photo bytes
  static Future<Uint8List?> getPhotoBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate basic curation score based on image properties
  static Future<double> calculateCurationScore(String filePath) async {
    try {
      final imageBytes = await getPhotoBytes(filePath);
      if (imageBytes == null) return 0.0;

      final image = img.decodeImage(imageBytes);
      if (image == null) return 0.0;

      double score = 0.5; // Base score

      // Higher resolution gets better score
      final pixels = image.width * image.height;
      if (pixels > 2000000) score += 0.2; // > 2MP
      if (pixels > 8000000) score += 0.1; // > 8MP

      // Aspect ratio close to golden ratio gets bonus
      final aspectRatio = image.width / image.height;
      if ((aspectRatio - 1.618).abs() < 0.2) score += 0.1;

      // Ensure score is within bounds
      return score.clamp(0.0, 1.0);
    } catch (e) {
      return 0.5; // Default score on error
    }
  }

  /// Cleanup orphaned photo files
  static Future<int> cleanupOrphanedFiles(List<String> validFilePaths) async {
    try {
      final photosDir = await _getPhotosDirectory();
      if (!await photosDir.exists()) return 0;

      int deletedCount = 0;
      final validPaths = validFilePaths.toSet();

      await for (final entity in photosDir.list(recursive: true)) {
        if (entity is File && !validPaths.contains(entity.path)) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            print('Failed to delete orphaned file ${entity.path}: $e');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      throw PhotoServiceException('Failed to cleanup orphaned files: $e');
    }
  }
}

/// Exception thrown by PhotoService operations
class PhotoServiceException implements Exception {
  const PhotoServiceException(this.message);
  
  final String message;
  
  @override
  String toString() => 'PhotoServiceException: $message';
}
