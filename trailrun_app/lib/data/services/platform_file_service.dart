import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

/// Platform-specific file storage and sharing service
class PlatformFileService {
  /// Get platform-appropriate directory for storing app files
  static Future<Directory> getAppStorageDirectory() async {
    if (Platform.isIOS) {
      // iOS: Use Documents directory for user-accessible files
      return await getApplicationDocumentsDirectory();
    } else {
      // Android: Use app-specific external storage
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        return directory;
      } else {
        // Fallback to internal storage if external is not available
        return await getApplicationDocumentsDirectory();
      }
    }
  }

  /// Get platform-appropriate directory for caching files
  static Future<Directory> getCacheDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Get platform-appropriate directory for photos
  static Future<Directory> getPhotoStorageDirectory() async {
    final appDir = await getAppStorageDirectory();
    final photoDir = Directory(path.join(appDir.path, 'photos'));
    
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    
    return photoDir;
  }

  /// Get platform-appropriate directory for exports (GPX, etc.)
  static Future<Directory> getExportDirectory() async {
    final appDir = await getAppStorageDirectory();
    final exportDir = Directory(path.join(appDir.path, 'exports'));
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }

  /// Save file to platform-appropriate location
  static Future<File> saveFile({
    required String fileName,
    required Uint8List data,
    required FileType fileType,
  }) async {
    Directory directory;
    
    switch (fileType) {
      case FileType.photo:
        directory = await getPhotoStorageDirectory();
        break;
      case FileType.export:
        directory = await getExportDirectory();
        break;
      case FileType.cache:
        directory = await getCacheDirectory();
        break;
      case FileType.document:
        directory = await getAppStorageDirectory();
        break;
    }

    final file = File(path.join(directory.path, fileName));
    return await file.writeAsBytes(data);
  }

  /// Read file from storage
  static Future<Uint8List?> readFile(String filePath) async {
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

  /// Delete file from storage
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file size
  static Future<int> getFileSize(String filePath) async {
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

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get available storage space
  static Future<int> getAvailableStorageSpace() async {
    try {
      final directory = await getAppStorageDirectory();
      final stat = await directory.stat();
      // This is a simplified implementation
      // In a real app, you might want to use platform-specific code
      return 1024 * 1024 * 1024; // Return 1GB as placeholder
    } catch (e) {
      return 0;
    }
  }

  /// Share file using platform-appropriate sharing mechanism
  static Future<ShareResult> shareFile({
    required String filePath,
    required String fileName,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ShareResult('', ShareResultStatus.unavailable);
      }

      final xFile = XFile(filePath, name: fileName);
      
      return await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      return ShareResult('', ShareResultStatus.unavailable);
    }
  }

  /// Share multiple files
  static Future<ShareResult> shareFiles({
    required List<String> filePaths,
    required List<String> fileNames,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final xFiles = <XFile>[];
      
      for (int i = 0; i < filePaths.length; i++) {
        final file = File(filePaths[i]);
        if (await file.exists()) {
          final fileName = i < fileNames.length ? fileNames[i] : path.basename(filePaths[i]);
          xFiles.add(XFile(filePaths[i], name: fileName));
        }
      }

      if (xFiles.isEmpty) {
        return ShareResult('', ShareResultStatus.unavailable);
      }

      return await Share.shareXFiles(
        xFiles,
        subject: subject,
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      return ShareResult('', ShareResultStatus.unavailable);
    }
  }

  /// Share text content
  static Future<ShareResult> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      return await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      return ShareResult('', ShareResultStatus.unavailable);
    }
  }

  /// Create a temporary file for sharing
  static Future<File> createTempFile({
    required String fileName,
    required Uint8List data,
  }) async {
    final tempDir = await getCacheDirectory();
    final tempFile = File(path.join(tempDir.path, fileName));
    return await tempFile.writeAsBytes(data);
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getCacheDirectory();
      final files = await tempDir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          
          // Delete files older than 24 hours
          if (age.inHours > 24) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Get platform-specific file extension for exports
  static String getExportFileExtension(ExportType exportType) {
    switch (exportType) {
      case ExportType.gpx:
        return '.gpx';
      case ExportType.json:
        return '.json';
      case ExportType.csv:
        return '.csv';
      case ExportType.zip:
        return '.zip';
      case ExportType.image:
        return Platform.isIOS ? '.heic' : '.jpg';
    }
  }

  /// Get MIME type for file sharing
  static String getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.gpx':
        return 'application/gpx+xml';
      case '.json':
        return 'application/json';
      case '.csv':
        return 'text/csv';
      case '.zip':
        return 'application/zip';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if platform supports specific file operations
  static bool supportsFileOperation(FileOperation operation) {
    switch (operation) {
      case FileOperation.share:
        return true; // Both platforms support sharing
      case FileOperation.export:
        return true; // Both platforms support file export
      case FileOperation.externalStorage:
        return Platform.isAndroid; // Only Android has external storage concept
      case FileOperation.documentsDirectory:
        return Platform.isIOS; // iOS has user-accessible Documents directory
    }
  }
}

enum FileType {
  photo,
  export,
  cache,
  document,
}

enum ExportType {
  gpx,
  json,
  csv,
  zip,
  image,
}

enum FileOperation {
  share,
  export,
  externalStorage,
  documentsDirectory,
}