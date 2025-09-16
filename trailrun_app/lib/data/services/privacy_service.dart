import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../../domain/models/track_point.dart';
import '../../domain/models/split.dart';
import '../../domain/enums/privacy_level.dart';
import '../../domain/value_objects/coordinates.dart';
import '../database/database.dart';

/// Service for handling privacy and security operations
class PrivacyService {
  final TrailRunDatabase _database;
  
  const PrivacyService(this._database);

  /// Strip EXIF data from a photo file for privacy
  Future<void> stripPhotoExifData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw PrivacyServiceException('Photo file not found: $filePath');
      }

      final imageBytes = await file.readAsBytes();
      
      // Decode image without EXIF
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw PrivacyServiceException('Failed to decode image for EXIF stripping');
      }

      // Re-encode without EXIF data
      final cleanBytes = img.encodeJpg(image, quality: 85);
      
      // Create backup of original if needed
      final backupPath = '${filePath}.backup';
      await file.copy(backupPath);
      
      // Write clean image
      await file.writeAsBytes(cleanBytes);
      
      // Remove backup after successful write
      await File(backupPath).delete();
      
    } catch (e) {
      throw PrivacyServiceException('Failed to strip EXIF data: $e');
    }
  }

  /// Strip EXIF data from multiple photos
  Future<void> stripMultiplePhotosExifData(List<String> filePaths) async {
    final errors = <String>[];
    
    for (final filePath in filePaths) {
      try {
        await stripPhotoExifData(filePath);
      } catch (e) {
        errors.add('$filePath: $e');
      }
    }
    
    if (errors.isNotEmpty) {
      throw PrivacyServiceException(
        'Failed to strip EXIF data from some photos:\n${errors.join('\n')}'
      );
    }
  }

  /// Check if a photo has EXIF data
  Future<bool> hasExifData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final imageBytes = await file.readAsBytes();
      final exifData = await readExifFromBytes(imageBytes);
      
      return exifData.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get EXIF data summary for a photo
  Future<Map<String, dynamic>> getExifSummary(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return {};
      
      final imageBytes = await file.readAsBytes();
      final exifData = await readExifFromBytes(imageBytes);
      
      final summary = <String, dynamic>{};
      
      // Check for GPS data
      if (exifData.containsKey('GPS GPSLatitude')) {
        summary['hasGPS'] = true;
        summary['gpsLatitude'] = exifData['GPS GPSLatitude'].toString();
        summary['gpsLongitude'] = exifData['GPS GPSLongitude'].toString();
      } else {
        summary['hasGPS'] = false;
      }
      
      // Check for timestamp
      if (exifData.containsKey('EXIF DateTime')) {
        summary['hasTimestamp'] = true;
        summary['timestamp'] = exifData['EXIF DateTime'].toString();
      } else {
        summary['hasTimestamp'] = false;
      }
      
      // Check for camera info
      if (exifData.containsKey('Image Make')) {
        summary['hasCameraInfo'] = true;
        summary['cameraMake'] = exifData['Image Make'].toString();
        summary['cameraModel'] = exifData['Image Model']?.toString();
      } else {
        summary['hasCameraInfo'] = false;
      }
      
      return summary;
    } catch (e) {
      return {};
    }
  }

  /// Delete all user data (GDPR compliance)
  Future<void> deleteAllUserData() async {
    try {
      // Delete all database data
      await _database.transaction(() async {
        await _database.syncQueueDao.deleteAll();
        await _database.splitDao.deleteAll();
        await _database.photoDao.deleteAll();
        await _database.trackPointDao.deleteAll();
        await _database.activityDao.deleteAll();
      });
      
      // Delete all photo files
      await _deleteAllPhotoFiles();
      
      // Delete any cached data
      await _deleteCachedData();
      
    } catch (e) {
      throw PrivacyServiceException('Failed to delete user data: $e');
    }
  }

  /// Delete specific activity data
  Future<void> deleteActivityData(String activityId) async {
    try {
      await _database.transaction(() async {
        // Get photos before deleting from database
        final photos = await _database.photoDao.getPhotosForActivity(activityId);
        
        // Delete from database
        await _database.syncQueueDao.deleteByEntityId(activityId);
        await _database.splitDao.deleteByActivityId(activityId);
        await _database.photoDao.deleteByActivityId(activityId);
        await _database.trackPointDao.deleteByActivityId(activityId);
        await _database.activityDao.deleteActivity(activityId);
        
        // Delete photo files
        for (final photo in photos) {
          await _deletePhotoFiles(photo.filePath, photo.thumbnailPath);
        }
      });
    } catch (e) {
      throw PrivacyServiceException('Failed to delete activity data: $e');
    }
  }

  /// Export all user data for portability (GDPR compliance)
  Future<String> exportUserData() async {
    try {
      final exportData = <String, dynamic>{};
      final timestamp = DateTime.now().toIso8601String();
      
      // Export metadata
      exportData['exportTimestamp'] = timestamp;
      exportData['version'] = '1.0';
      
      // Export activities
      final activities = await _database.activityDao.getAllActivities();
      exportData['activities'] = activities.map((a) => _activityToJson(a)).toList();
      
      // Export track points
      final trackPoints = await _database.trackPointDao.getAllTrackPoints();
      exportData['trackPoints'] = trackPoints.map((tp) => _trackPointToJson(tp)).toList();
      
      // Export photos metadata
      final photos = await _database.photoDao.getAllPhotos();
      exportData['photos'] = photos.map((p) => _photoToJson(p)).toList();
      
      // Export splits
      final splits = await _database.splitDao.getAllSplits();
      exportData['splits'] = splits.map((s) => _splitToJson(s)).toList();
      
      // Create export file
      final exportDir = await _getExportDirectory();
      final exportFile = File(path.join(
        exportDir.path, 
        'trailrun_export_${timestamp.replaceAll(':', '-')}.json'
      ));
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await exportFile.writeAsString(jsonString);
      
      return exportFile.path;
    } catch (e) {
      throw PrivacyServiceException('Failed to export user data: $e');
    }
  }

  /// Export user data with photos as ZIP archive
  Future<String> exportUserDataWithPhotos() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final exportDir = await _getExportDirectory();
      
      // Create JSON export first
      final jsonPath = await exportUserData();
      
      // Create ZIP archive
      final archive = Archive();
      
      // Add JSON data
      final jsonFile = File(jsonPath);
      final jsonBytes = await jsonFile.readAsBytes();
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
      
      // Add photos
      final photos = await _database.photoDao.getAllPhotos();
      for (final photo in photos) {
        try {
          final photoFile = File(photo.filePath);
          if (await photoFile.exists()) {
            final photoBytes = await photoFile.readAsBytes();
            final fileName = 'photos/${photo.activityId}/${path.basename(photo.filePath)}';
            archive.addFile(ArchiveFile(fileName, photoBytes.length, photoBytes));
          }
        } catch (e) {
          // Continue with other photos if one fails
          print('Failed to add photo ${photo.filePath} to export: $e');
        }
      }
      
      // Write ZIP file
      final zipPath = path.join(
        exportDir.path,
        'trailrun_export_${timestamp.replaceAll(':', '-')}.zip'
      );
      final zipFile = File(zipPath);
      final zipBytes = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipBytes!);
      
      // Clean up JSON file
      await jsonFile.delete();
      
      return zipPath;
    } catch (e) {
      throw PrivacyServiceException('Failed to export user data with photos: $e');
    }
  }

  /// Apply privacy settings to activity
  Future<void> applyPrivacySettings(String activityId, PrivacySettings settings) async {
    try {
      final activity = await _database.activityDao.getActivity(activityId);
      if (activity == null) {
        throw PrivacyServiceException('Activity not found: $activityId');
      }

      // Update activity privacy level
      await _database.activityDao.updateActivity(
        activity.copyWith(privacyLevel: settings.privacyLevel)
      );

      // Strip EXIF data from photos if requested
      if (settings.stripExifData) {
        final photos = await _database.photoDao.getPhotosForActivity(activityId);
        final photoPaths = photos.map((p) => p.filePath).toList();
        await stripMultiplePhotosExifData(photoPaths);
        
        // Update photo records to reflect EXIF stripping
        for (final photo in photos) {
          await _database.photoDao.updatePhoto(
            photo.copyWith(hasExifData: false)
          );
        }
      }
    } catch (e) {
      throw PrivacyServiceException('Failed to apply privacy settings: $e');
    }
  }

  /// Get privacy-safe coordinates (rounded for privacy)
  static Coordinates getPrivacySafeCoordinates(Coordinates original, PrivacyLevel privacyLevel) {
    switch (privacyLevel) {
      case PrivacyLevel.private:
        // Round to ~1km accuracy
        return Coordinates(
          latitude: _roundToDecimalPlaces(original.latitude, 2),
          longitude: _roundToDecimalPlaces(original.longitude, 2),
          elevation: original.elevation != null 
            ? _roundToDecimalPlaces(original.elevation!, 0)
            : null,
        );
      case PrivacyLevel.friends:
        // Round to ~100m accuracy
        return Coordinates(
          latitude: _roundToDecimalPlaces(original.latitude, 3),
          longitude: _roundToDecimalPlaces(original.longitude, 3),
          elevation: original.elevation != null 
            ? _roundToDecimalPlaces(original.elevation!, 0)
            : null,
        );
      case PrivacyLevel.public:
        // Full accuracy
        return original;
    }
  }

  /// Helper method to round to decimal places
  static double _roundToDecimalPlaces(double value, int places) {
    final factor = math.pow(10, places);
    return (value * factor).round() / factor;
  }

  /// Delete all photo files
  Future<void> _deleteAllPhotoFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(path.join(appDir.path, 'photos'));
      
      if (await photosDir.exists()) {
        await photosDir.delete(recursive: true);
      }
    } catch (e) {
      throw PrivacyServiceException('Failed to delete photo files: $e');
    }
  }

  /// Delete specific photo files
  Future<void> _deletePhotoFiles(String filePath, String? thumbnailPath) async {
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
      // Don't throw for individual file deletion failures
      print('Warning: Failed to delete photo files: $e');
    }
  }

  /// Delete cached data
  Future<void> _deleteCachedData() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity.path.contains('trailrun')) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      // Don't throw for cache deletion failures
      print('Warning: Failed to delete cached data: $e');
    }
  }

  /// Get export directory
  Future<Directory> _getExportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(appDir.path, 'exports'));
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }

  /// Convert activity to JSON
  Map<String, dynamic> _activityToJson(Activity activity) {
    return {
      'id': activity.id,
      'startTime': activity.startTime.toIso8601String(),
      'endTime': activity.endTime?.toIso8601String(),
      'distanceMeters': activity.distanceMeters,
      'durationSeconds': activity.duration.inSeconds,
      'elevationGainMeters': activity.elevationGainMeters,
      'averagePaceSecondsPerKm': activity.averagePaceSecondsPerKm,
      'title': activity.title,
      'notes': activity.notes,
      'privacyLevel': activity.privacyLevel.name,
      'coverPhotoId': activity.coverPhotoId,
    };
  }

  /// Convert track point to JSON
  Map<String, dynamic> _trackPointToJson(TrackPoint trackPoint) {
    return {
      'id': trackPoint.id,
      'activityId': trackPoint.activityId,
      'timestamp': trackPoint.timestamp.toIso8601String(),
      'latitude': trackPoint.coordinates.latitude,
      'longitude': trackPoint.coordinates.longitude,
      'elevation': trackPoint.coordinates.elevation,
      'accuracy': trackPoint.accuracy,
      'source': trackPoint.source.name,
      'sequence': trackPoint.sequence,
    };
  }

  /// Convert photo to JSON
  Map<String, dynamic> _photoToJson(Photo photo) {
    return {
      'id': photo.id,
      'activityId': photo.activityId,
      'timestamp': photo.timestamp.toIso8601String(),
      'latitude': photo.coordinates?.latitude,
      'longitude': photo.coordinates?.longitude,
      'elevation': photo.coordinates?.elevation,
      'filePath': photo.filePath,
      'thumbnailPath': photo.thumbnailPath,
      'hasExifData': photo.hasExifData,
      'curationScore': photo.curationScore,
    };
  }

  /// Convert split to JSON
  Map<String, dynamic> _splitToJson(Split split) {
    return {
      'id': split.id,
      'activityId': split.activityId,
      'splitNumber': split.splitNumber,
      'distanceMeters': split.distanceMeters,
      'durationSeconds': split.duration.inSeconds,
      'paceSecondsPerKm': split.paceSecondsPerKm,
      'elevationGainMeters': split.elevationGainMeters,
      'elevationLossMeters': split.elevationLossMeters,
    };
  }
}

/// Privacy settings for activities and photos
class PrivacySettings {
  final PrivacyLevel privacyLevel;
  final bool stripExifData;
  final bool shareLocation;
  final bool sharePhotos;
  final bool shareStats;

  const PrivacySettings({
    required this.privacyLevel,
    this.stripExifData = true,
    this.shareLocation = false,
    this.shareStats = true,
    this.sharePhotos = true,
  });

  PrivacySettings copyWith({
    PrivacyLevel? privacyLevel,
    bool? stripExifData,
    bool? shareLocation,
    bool? sharePhotos,
    bool? shareStats,
  }) {
    return PrivacySettings(
      privacyLevel: privacyLevel ?? this.privacyLevel,
      stripExifData: stripExifData ?? this.stripExifData,
      shareLocation: shareLocation ?? this.shareLocation,
      sharePhotos: sharePhotos ?? this.sharePhotos,
      shareStats: shareStats ?? this.shareStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacyLevel': privacyLevel.name,
      'stripExifData': stripExifData,
      'shareLocation': shareLocation,
      'sharePhotos': sharePhotos,
      'shareStats': shareStats,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      privacyLevel: PrivacyLevel.values.firstWhere(
        (e) => e.name == json['privacyLevel'],
        orElse: () => PrivacyLevel.private,
      ),
      stripExifData: json['stripExifData'] ?? true,
      shareLocation: json['shareLocation'] ?? false,
      sharePhotos: json['sharePhotos'] ?? true,
      shareStats: json['shareStats'] ?? true,
    );
  }
}

/// Exception thrown by PrivacyService operations
class PrivacyServiceException implements Exception {
  const PrivacyServiceException(this.message);
  
  final String message;
  
  @override
  String toString() => 'PrivacyServiceException: $message';
}