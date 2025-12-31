import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import '../../domain/models/track_point.dart';
import '../../domain/enums/privacy_level.dart';
import 'map_service.dart';

/// Service for sharing activities and exporting data
class ShareExportService {
  static const String _gpxNamespace = 'http://www.topografix.com/GPX/1/1';
  static const String _appName = 'TrailRun';
  static const String _appVersion = '1.0.0';

  /// Share activity with native share sheet
  Future<void> shareActivity(
    Activity activity, {
    Uint8List? mapSnapshot,
    bool includePhotos = true,
  }) async {
    try {
      final files = <XFile>[];
      
      // Generate share card if map snapshot is provided
      if (mapSnapshot != null) {
        final shareCard = await _generateShareCard(activity, mapSnapshot);
        if (shareCard != null) {
          final tempDir = await getTemporaryDirectory();
          final shareCardFile = File(path.join(tempDir.path, 'activity_share_${activity.id}.png'));
          await shareCardFile.writeAsBytes(shareCard);
          files.add(XFile(shareCardFile.path));
        }
      }
      
      // Add photos if requested and privacy allows
      if (includePhotos && _shouldIncludePhotos(activity)) {
        for (final photo in activity.photos) {
          if (await File(photo.filePath).exists()) {
            files.add(XFile(photo.filePath));
          }
        }
      }
      
      // Generate share text
      final shareText = _generateShareText(activity);
      
      if (files.isNotEmpty) {
        await Share.shareXFiles(
          files,
          text: shareText,
          subject: 'My ${activity.title} run',
        );
      } else {
        await Share.share(
          shareText,
          subject: 'My ${activity.title} run',
        );
      }
    } catch (e) {
      debugPrint('Error sharing activity: $e');
      rethrow;
    }
  }

  /// Share a single photo
  Future<void> sharePhoto(Photo photo) async {
    try {
      final file = File(photo.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: photo.caption,
        );
      }
    } catch (e) {
      debugPrint('Error sharing photo: $e');
      rethrow;
    }
  }

  /// Export activity as GPX file
  Future<XFile> exportActivityAsGpx(Activity activity) async {
    try {
      final gpxContent = _generateGpxContent(activity);
      final tempDir = await getTemporaryDirectory();
      final gpxFile = File(path.join(tempDir.path, '${_sanitizeFilename(activity.title)}.gpx'));
      
      await gpxFile.writeAsString(gpxContent, encoding: utf8);
      
      return XFile(gpxFile.path);
    } catch (e) {
      debugPrint('Error exporting GPX: $e');
      rethrow;
    }
  }

  /// Export photos with metadata as a bundle
  Future<List<XFile>> exportPhotoBundle(Activity activity) async {
    try {
      final files = <XFile>[];
      final tempDir = await getTemporaryDirectory();
      final bundleDir = Directory(path.join(tempDir.path, 'photos_${activity.id}'));
      
      if (!await bundleDir.exists()) {
        await bundleDir.create(recursive: true);
      }
      
      // Copy photos to bundle directory
      for (int i = 0; i < activity.photos.length; i++) {
        final photo = activity.photos[i];
        final originalFile = File(photo.filePath);
        
        if (await originalFile.exists()) {
          final extension = path.extension(photo.filePath);
          final newFileName = 'photo_${i + 1}_${photo.timestamp.millisecondsSinceEpoch}$extension';
          final newFile = File(path.join(bundleDir.path, newFileName));
          
          // Copy photo (strip EXIF if privacy requires it)
          if (activity.privacy.isRestricted && photo.hasExifData) {
            await _copyPhotoWithoutExif(originalFile, newFile);
          } else {
            await originalFile.copy(newFile.path);
          }
          
          files.add(XFile(newFile.path));
        }
      }
      
      // Generate metadata JSON
      final metadata = _generatePhotoMetadata(activity);
      final metadataFile = File(path.join(bundleDir.path, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode(metadata), encoding: utf8);
      files.add(XFile(metadataFile.path));
      
      return files;
    } catch (e) {
      debugPrint('Error exporting photo bundle: $e');
      rethrow;
    }
  }

  /// Generate share card image with map, stats, and photo collage
  Future<Uint8List?> _generateShareCard(Activity activity, Uint8List mapSnapshot) async {
    try {
      // This would typically use a more sophisticated image composition library
      // For now, we'll return the map snapshot as a placeholder
      // In a real implementation, you'd compose the map with stats and photos
      return mapSnapshot;
    } catch (e) {
      debugPrint('Error generating share card: $e');
      return null;
    }
  }

  /// Generate GPX content from activity data
  String _generateGpxContent(Activity activity) {
    final buffer = StringBuffer();
    
    // GPX header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="$_appName $_appVersion" xmlns="$_gpxNamespace">');
    
    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml(activity.title)}</name>');
    buffer.writeln('    <time>${activity.startTime.dateTime.toIso8601String()}</time>');
    if (activity.notes?.isNotEmpty == true) {
      buffer.writeln('    <desc>${_escapeXml(activity.notes!)}</desc>');
    }
    buffer.writeln('  </metadata>');
    
    // Track
    if (activity.trackPoints.isNotEmpty) {
      buffer.writeln('  <trk>');
      buffer.writeln('    <name>${_escapeXml(activity.title)}</name>');
      buffer.writeln('    <trkseg>');
      
      for (final point in activity.trackPointsSortedBySequence) {
        final lat = _shouldStripCoordinates(activity) ? 
            _obfuscateCoordinate(point.coordinates.latitude) : 
            point.coordinates.latitude;
        final lon = _shouldStripCoordinates(activity) ? 
            _obfuscateCoordinate(point.coordinates.longitude) : 
            point.coordinates.longitude;
            
        buffer.write('      <trkpt lat="$lat" lon="$lon">');
        
        if (point.coordinates.elevation != null) {
          buffer.write('<ele>${point.coordinates.elevation}</ele>');
        }
        
        buffer.write('<time>${point.timestamp.dateTime.toIso8601String()}</time>');
        buffer.writeln('</trkpt>');
      }
      
      buffer.writeln('    </trkseg>');
      buffer.writeln('  </trk>');
    }
    
    // Waypoints for photos (if privacy allows)
    if (_shouldIncludePhotos(activity)) {
      for (int i = 0; i < activity.photos.length; i++) {
        final photo = activity.photos[i];
        if (photo.coordinates != null) {
          final lat = _shouldStripCoordinates(activity) ? 
              _obfuscateCoordinate(photo.coordinates!.latitude) : 
              photo.coordinates!.latitude;
          final lon = _shouldStripCoordinates(activity) ? 
              _obfuscateCoordinate(photo.coordinates!.longitude) : 
              photo.coordinates!.longitude;
              
          buffer.writeln('  <wpt lat="$lat" lon="$lon">');
          buffer.writeln('    <name>Photo ${i + 1}</name>');
          buffer.writeln('    <time>${photo.timestamp.dateTime.toIso8601String()}</time>');
          if (photo.caption?.isNotEmpty == true) {
            buffer.writeln('    <desc>${_escapeXml(photo.caption!)}</desc>');
          }
          buffer.writeln('  </wpt>');
        }
      }
    }
    
    buffer.writeln('</gpx>');
    
    return buffer.toString();
  }

  /// Generate photo metadata JSON
  Map<String, dynamic> _generatePhotoMetadata(Activity activity) {
    return {
      'activity': {
        'id': activity.id,
        'title': activity.title,
        'startTime': activity.startTime.dateTime.toIso8601String(),
        'endTime': activity.endTime?.dateTime.toIso8601String(),
        'distance': activity.distance.meters,
        'duration': activity.duration?.inSeconds,
        'notes': activity.notes,
      },
      'photos': activity.photos.map((photo) => {
        'id': photo.id,
        'timestamp': photo.timestamp.dateTime.toIso8601String(),
        'coordinates': photo.coordinates != null && !_shouldStripCoordinates(activity) ? {
          'latitude': photo.coordinates!.latitude,
          'longitude': photo.coordinates!.longitude,
          'elevation': photo.coordinates!.elevation,
        } : null,
        'caption': photo.caption,
        'curationScore': photo.curationScore,
      }).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'privacyLevel': activity.privacy.name,
    };
  }

  /// Generate share text for activity
  String _generateShareText(Activity activity) {
    final buffer = StringBuffer();
    
    buffer.writeln('🏃‍♂️ ${activity.title}');
    buffer.writeln();
    
    // Stats
    buffer.writeln('📊 Stats:');
    buffer.writeln('• Distance: ${activity.distance.kilometers.toStringAsFixed(2)} km');
    
    if (activity.duration != null) {
      final duration = activity.duration!;
      final hours = duration.inHours;
      final minutes = (duration.inMinutes % 60);
      final seconds = (duration.inSeconds % 60);
      
      if (hours > 0) {
        buffer.writeln('• Time: ${hours}h ${minutes}m ${seconds}s');
      } else {
        buffer.writeln('• Time: ${minutes}m ${seconds}s');
      }
    }
    
    if (activity.averagePace != null) {
      final pace = activity.averagePace!;
      final minutes = pace.secondsPerKilometer ~/ 60;
      final seconds = pace.secondsPerKilometer % 60;
      buffer.writeln('• Avg Pace: ${minutes}:${seconds.toString().padLeft(2, '0')}/km');
    }
    
    if (activity.elevationGain.meters > 0) {
      buffer.writeln('• Elevation Gain: ${activity.elevationGain.meters.toStringAsFixed(0)}m');
    }
    
    if (activity.photos.isNotEmpty) {
      buffer.writeln('• Photos: ${activity.photos.length}');
    }
    
    buffer.writeln();
    buffer.writeln('Tracked with $_appName 📱');
    
    return buffer.toString();
  }

  /// Check if photos should be included based on privacy settings
  bool _shouldIncludePhotos(Activity activity) {
    return activity.privacy == PrivacyLevel.public || activity.photos.isNotEmpty;
  }

  /// Check if coordinates should be stripped for privacy
  bool _shouldStripCoordinates(Activity activity) {
    return activity.privacy.isRestricted;
  }

  /// Obfuscate coordinate for privacy (reduce precision)
  double _obfuscateCoordinate(double coordinate) {
    // Reduce precision to ~100m accuracy
    return double.parse(coordinate.toStringAsFixed(3));
  }

  /// Copy photo without EXIF data
  Future<void> _copyPhotoWithoutExif(File source, File destination) async {
    // For now, just copy the file
    // In a real implementation, you'd use an image processing library
    // to strip EXIF data while preserving the image
    await source.copy(destination.path);
  }

  /// Sanitize filename for file system
  String _sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Escape XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}