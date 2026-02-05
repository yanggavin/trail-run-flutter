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
        await _database.delete(_database.syncQueueTable).go();
        await _database.delete(_database.splitsTable).go();
        await _database.delete(_database.photosTable).go();
        await _database.delete(_database.trackPointsTable).go();
        await _database.delete(_database.activitiesTable).go();
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
        await (_database.delete(_database.syncQueueTable)..where((t) => t.entityId.equals(activityId))).go();
        await (_database.delete(_database.splitsTable)..where((t) => t.activityId.equals(activityId))).go();
        await _database.photoDao.deletePhotosForActivity(activityId);
        await _database.trackPointDao.deleteTrackPointsForActivity(activityId);
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
      final activityEntities = await _database.activityDao.getAllActivities();
      final activities = activityEntities.map((e) => _database.activityDao.fromEntity(e)).toList();
      exportData['activities'] = activities.map((a) => _activityToJson(a)).toList();
      
      // Export track points
      final trackPoints = <Map<String, dynamic>>[];
      for (final activity in activities) {
        final tpEntities = await _database.trackPointDao.getTrackPointsForActivity(activity.id);
        trackPoints.addAll(tpEntities.map((e) => _trackPointToJson(_database.trackPointDao.fromEntity(e))));
      }
      exportData['trackPoints'] = trackPoints;
      
      // Export photos metadata
      final photos = <Map<String, dynamic>>[];
      for (final activity in activities) {
        final photoEntities = await _database.photoDao.getPhotosForActivity(activity.id);
        photos.addAll(photoEntities.map((e) => _photoToJson(_database.photoDao.fromEntity(e))));
      }
      exportData['photos'] = photos;
      
      // Export splits
      final splits = <Map<String, dynamic>>[];
      for (final activity in activities) {
        final splitEntities = await _database.splitDao.getSplitsForActivity(activity.id);
        splits.addAll(splitEntities.map((e) => _splitToJson(_database.splitDao.fromEntity(e))));
      }
      exportData['splits'] = splits;
      
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
      final activities = await _database.activityDao.getAllActivities();
      for (final activity in activities) {
        final photos = await _database.photoDao.getPhotosForActivity(activity.id);
        for (final photoEntity in photos) {
          final photo = _database.photoDao.fromEntity(photoEntity);
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
      final activityEntity = await _database.activityDao.getActivityById(activityId);
      if (activityEntity == null) {
        throw PrivacyServiceException('Activity not found: $activityId');
      }
      
      final activity = _database.activityDao.fromEntity(activityEntity);

      // Update activity privacy level
      await _database.activityDao.updateActivity(
        _database.activityDao.toEntity(activity.copyWith(privacy: settings.privacyLevel))
      );

      // Strip EXIF data from photos if requested
      if (settings.stripExifData) {
        final photos = await _database.photoDao.getPhotosForActivity(activityId);
        final photoPaths = photos.map((p) => p.filePath).toList();
        await stripMultiplePhotosExifData(photoPaths);
        
        // Update photo records to reflect EXIF stripping
        for (final photoEntity in photos) {
          final photo = _database.photoDao.fromEntity(photoEntity);
          await _database.photoDao.updatePhoto(
            _database.photoDao.toEntity(photo.copyWith(hasExifData: false))
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
      'startTime': activity.startTime.dateTime.toIso8601String(),
      'endTime': activity.endTime?.dateTime.toIso8601String(),
      'distanceMeters': activity.distance.meters,
      'durationSeconds': activity.duration?.inSeconds,
      'elevationGainMeters': activity.elevationGain.meters,
      'averagePaceSecondsPerKm': activity.averagePace?.secondsPerKilometer,
      'title': activity.title,
      'notes': activity.notes,
      'privacyLevel': activity.privacy.name,
      'coverPhotoId': activity.coverPhotoId,
    };
  }

  /// Convert track point to JSON
  Map<String, dynamic> _trackPointToJson(TrackPoint trackPoint) {
    return {
      'id': trackPoint.id,
      'activityId': trackPoint.activityId,
      'timestamp': trackPoint.timestamp.dateTime.toIso8601String(),
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
      'timestamp': photo.timestamp.dateTime.toIso8601String(),
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
      'distanceMeters': split.distance.meters,
      'durationSeconds': split.duration.inSeconds,
      'paceSecondsPerKm': split.pace.secondsPerKilometer,
      'elevationGainMeters': split.elevationGain.meters,
      'elevationLossMeters': split.elevationLoss.meters,
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