import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Progressive photo loading service for efficient memory management
class ProgressivePhotoLoader {
  static final Map<String, Uint8List> _thumbnailCache = {};
  static final Map<String, Uint8List> _fullImageCache = {};
  static final Map<String, Completer<Uint8List>> _loadingCompleters = {};
  
  // Cache size limits (in bytes)
  static const int _maxThumbnailCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxFullImageCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Current cache sizes
  static int _thumbnailCacheSize = 0;
  static int _fullImageCacheSize = 0;
  
  // LRU tracking
  static final List<String> _thumbnailLRU = [];
  static final List<String> _fullImageLRU = [];
  
  /// Load thumbnail with caching and progressive loading
  static Future<Uint8List?> loadThumbnail(String filePath) async {
    final thumbnailPath = _getThumbnailPath(filePath);
    
    // Check cache first
    if (_thumbnailCache.containsKey(thumbnailPath)) {
      _updateLRU(_thumbnailLRU, thumbnailPath);
      return _thumbnailCache[thumbnailPath];
    }
    
    // Check if already loading
    if (_loadingCompleters.containsKey(thumbnailPath)) {
      return await _loadingCompleters[thumbnailPath]!.future;
    }
    
    // Start loading
    final completer = Completer<Uint8List>();
    _loadingCompleters[thumbnailPath] = completer;
    
    try {
      Uint8List? thumbnailBytes;
      
      // Try to load existing thumbnail
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        thumbnailBytes = await thumbnailFile.readAsBytes();
      } else {
        // Generate thumbnail from original
        thumbnailBytes = await _generateThumbnail(filePath);
      }
      
      if (thumbnailBytes != null) {
        _cacheThumbnail(thumbnailPath, thumbnailBytes);
        completer.complete(thumbnailBytes);
      } else {
        completer.complete(null);
      }
    } catch (e) {
      completer.completeError(e);
    } finally {
      _loadingCompleters.remove(thumbnailPath);
    }
    
    return completer.future;
  }
  
  /// Load full image with caching
  static Future<Uint8List?> loadFullImage(String filePath) async {
    // Check cache first
    if (_fullImageCache.containsKey(filePath)) {
      _updateLRU(_fullImageLRU, filePath);
      return _fullImageCache[filePath];
    }
    
    // Check if already loading
    if (_loadingCompleters.containsKey(filePath)) {
      return await _loadingCompleters[filePath]!.future;
    }
    
    // Start loading
    final completer = Completer<Uint8List>();
    _loadingCompleters[filePath] = completer;
    
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        _cacheFullImage(filePath, imageBytes);
        completer.complete(imageBytes);
      } else {
        completer.complete(null);
      }
    } catch (e) {
      completer.completeError(e);
    } finally {
      _loadingCompleters.remove(filePath);
    }
    
    return completer.future;
  }
  
  /// Generate thumbnail from original image
  static Future<Uint8List?> _generateThumbnail(String originalPath) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) return null;
      
      final imageBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return null;
      
      // Calculate thumbnail size maintaining aspect ratio
      const maxSize = 300;
      final thumbnail = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? maxSize : null,
        height: originalImage.height > originalImage.width ? maxSize : null,
      );
      
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);
      
      // Save thumbnail for future use
      final thumbnailPath = _getThumbnailPath(originalPath);
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);
      
      return Uint8List.fromList(thumbnailBytes);
    } catch (e) {
      debugPrint('Failed to generate thumbnail: $e');
      return null;
    }
  }
  
  /// Cache thumbnail with LRU eviction
  static void _cacheThumbnail(String path, Uint8List bytes) {
    final size = bytes.length;
    
    // Remove from cache if already exists
    if (_thumbnailCache.containsKey(path)) {
      _thumbnailCacheSize -= _thumbnailCache[path]!.length;
      _thumbnailLRU.remove(path);
    }
    
    // Evict old items if necessary
    while (_thumbnailCacheSize + size > _maxThumbnailCacheSize && _thumbnailLRU.isNotEmpty) {
      final oldestPath = _thumbnailLRU.removeAt(0);
      final oldBytes = _thumbnailCache.remove(oldestPath);
      if (oldBytes != null) {
        _thumbnailCacheSize -= oldBytes.length;
      }
    }
    
    // Add to cache
    _thumbnailCache[path] = bytes;
    _thumbnailCacheSize += size;
    _thumbnailLRU.add(path);
  }
  
  /// Cache full image with LRU eviction
  static void _cacheFullImage(String path, Uint8List bytes) {
    final size = bytes.length;
    
    // Remove from cache if already exists
    if (_fullImageCache.containsKey(path)) {
      _fullImageCacheSize -= _fullImageCache[path]!.length;
      _fullImageLRU.remove(path);
    }
    
    // Evict old items if necessary
    while (_fullImageCacheSize + size > _maxFullImageCacheSize && _fullImageLRU.isNotEmpty) {
      final oldestPath = _fullImageLRU.removeAt(0);
      final oldBytes = _fullImageCache.remove(oldestPath);
      if (oldBytes != null) {
        _fullImageCacheSize -= oldBytes.length;
      }
    }
    
    // Add to cache
    _fullImageCache[path] = bytes;
    _fullImageCacheSize += size;
    _fullImageLRU.add(path);
  }
  
  /// Update LRU order
  static void _updateLRU(List<String> lru, String path) {
    lru.remove(path);
    lru.add(path);
  }
  
  /// Get thumbnail path for original image path
  static String _getThumbnailPath(String originalPath) {
    return originalPath.replaceAll('.jpg', '_thumb.jpg');
  }
  
  /// Clear all caches
  static void clearCaches() {
    _thumbnailCache.clear();
    _fullImageCache.clear();
    _thumbnailLRU.clear();
    _fullImageLRU.clear();
    _thumbnailCacheSize = 0;
    _fullImageCacheSize = 0;
    _loadingCompleters.clear();
  }
  
  /// Clear thumbnail cache only
  static void clearThumbnailCache() {
    _thumbnailCache.clear();
    _thumbnailLRU.clear();
    _thumbnailCacheSize = 0;
  }
  
  /// Clear full image cache only
  static void clearFullImageCache() {
    _fullImageCache.clear();
    _fullImageLRU.clear();
    _fullImageCacheSize = 0;
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'thumbnailCacheSize': _thumbnailCacheSize,
      'fullImageCacheSize': _fullImageCacheSize,
      'thumbnailCount': _thumbnailCache.length,
      'fullImageCount': _fullImageCache.length,
      'maxThumbnailCacheSize': _maxThumbnailCacheSize,
      'maxFullImageCacheSize': _maxFullImageCacheSize,
    };
  }
  
  /// Preload thumbnails for a list of photo paths
  static Future<void> preloadThumbnails(List<String> photoPaths) async {
    final futures = photoPaths.map((path) => loadThumbnail(path));
    await Future.wait(futures, eagerError: false);
  }
  
  /// Remove specific image from caches
  static void removeFromCache(String filePath) {
    final thumbnailPath = _getThumbnailPath(filePath);
    
    // Remove thumbnail
    if (_thumbnailCache.containsKey(thumbnailPath)) {
      _thumbnailCacheSize -= _thumbnailCache[thumbnailPath]!.length;
      _thumbnailCache.remove(thumbnailPath);
      _thumbnailLRU.remove(thumbnailPath);
    }
    
    // Remove full image
    if (_fullImageCache.containsKey(filePath)) {
      _fullImageCacheSize -= _fullImageCache[filePath]!.length;
      _fullImageCache.remove(filePath);
      _fullImageLRU.remove(filePath);
    }
  }
}

/// Progressive photo widget that loads thumbnail first, then full image
class ProgressivePhotoWidget extends StatefulWidget {
  const ProgressivePhotoWidget({
    super.key,
    required this.photoPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });
  
  final String photoPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  @override
  State<ProgressivePhotoWidget> createState() => _ProgressivePhotoWidgetState();
}

class _ProgressivePhotoWidgetState extends State<ProgressivePhotoWidget> {
  Uint8List? _thumbnailBytes;
  Uint8List? _fullImageBytes;
  bool _isLoadingThumbnail = false;
  bool _isLoadingFullImage = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadImages();
  }
  
  @override
  void didUpdateWidget(ProgressivePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath) {
      _resetState();
      _loadImages();
    }
  }
  
  void _resetState() {
    _thumbnailBytes = null;
    _fullImageBytes = null;
    _isLoadingThumbnail = false;
    _isLoadingFullImage = false;
    _hasError = false;
  }
  
  Future<void> _loadImages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingThumbnail = true;
    });
    
    try {
      // Load thumbnail first
      final thumbnailBytes = await ProgressivePhotoLoader.loadThumbnail(widget.photoPath);
      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnailBytes;
          _isLoadingThumbnail = false;
          _isLoadingFullImage = true;
        });
      }
      
      // Then load full image
      final fullImageBytes = await ProgressivePhotoLoader.loadFullImage(widget.photoPath);
      if (mounted) {
        setState(() {
          _fullImageBytes = fullImageBytes;
          _isLoadingFullImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingThumbnail = false;
          _isLoadingFullImage = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        );
    }
    
    if (_fullImageBytes != null) {
      return Image.memory(
        _fullImageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    
    if (_thumbnailBytes != null) {
      return Stack(
        children: [
          Image.memory(
            _thumbnailBytes!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
          if (_isLoadingFullImage)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      );
    }
    
    if (_isLoadingThumbnail) {
      return widget.placeholder ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
    
    return widget.placeholder ?? 
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
      );
  }
}