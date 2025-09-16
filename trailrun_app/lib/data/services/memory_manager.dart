import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memory management service for large datasets with proper cleanup
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Memory thresholds (in MB)
  static const double _warningThreshold = 200.0;
  static const double _criticalThreshold = 300.0;
  static const double _maxMemoryUsage = 400.0;

  // Cleanup callbacks
  final List<VoidCallback> _cleanupCallbacks = [];
  final List<VoidCallback> _criticalCleanupCallbacks = [];

  // Memory monitoring
  Timer? _memoryMonitorTimer;
  double _currentMemoryUsage = 0.0;
  bool _isMonitoring = false;

  // Track large data structures
  final Map<String, int> _trackedObjects = {};
  final Map<String, DateTime> _objectTimestamps = {};

  /// Start memory monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(interval, (_) => _checkMemoryUsage());
    debugPrint('MemoryManager: Started monitoring with ${interval.inSeconds}s interval');
  }

  /// Stop memory monitoring
  void stopMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    _isMonitoring = false;
    debugPrint('MemoryManager: Stopped monitoring');
  }

  /// Register cleanup callback for normal memory pressure
  void registerCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }

  /// Register cleanup callback for critical memory pressure
  void registerCriticalCleanupCallback(VoidCallback callback) {
    _criticalCleanupCallbacks.add(callback);
  }

  /// Remove cleanup callback
  void removeCleanupCallback(VoidCallback callback) {
    _cleanupCallbacks.remove(callback);
    _criticalCleanupCallbacks.remove(callback);
  }

  /// Track a large object in memory
  void trackObject(String key, int sizeInBytes) {
    _trackedObjects[key] = sizeInBytes;
    _objectTimestamps[key] = DateTime.now();
    debugPrint('MemoryManager: Tracking object $key (${(sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
  }

  /// Untrack an object
  void untrackObject(String key) {
    final size = _trackedObjects.remove(key);
    _objectTimestamps.remove(key);
    if (size != null) {
      debugPrint('MemoryManager: Untracked object $key (${(size / 1024 / 1024).toStringAsFixed(2)} MB)');
    }
  }

  /// Get current memory usage estimate
  double getCurrentMemoryUsage() {
    return _currentMemoryUsage;
  }

  /// Get tracked objects summary
  Map<String, dynamic> getTrackedObjectsSummary() {
    final totalSize = _trackedObjects.values.fold<int>(0, (sum, size) => sum + size);
    return {
      'objectCount': _trackedObjects.length,
      'totalSizeMB': totalSize / 1024 / 1024,
      'objects': _trackedObjects.map((key, size) => MapEntry(key, {
        'sizeMB': size / 1024 / 1024,
        'age': DateTime.now().difference(_objectTimestamps[key]!).inMinutes,
      })),
    };
  }

  /// Force memory cleanup
  Future<void> forceCleanup({bool critical = false}) async {
    debugPrint('MemoryManager: Force cleanup (critical: $critical)');

    if (critical) {
      // Execute critical cleanup callbacks
      for (final callback in _criticalCleanupCallbacks) {
        try {
          callback();
        } catch (e) {
          debugPrint('MemoryManager: Critical cleanup callback failed: $e');
        }
      }
    }

    // Execute normal cleanup callbacks
    for (final callback in _cleanupCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('MemoryManager: Cleanup callback failed: $e');
      }
    }

    // Clean up old tracked objects
    _cleanupOldObjects();

    // Force garbage collection
    await _forceGarbageCollection();

    // Update memory usage
    await _updateMemoryUsage();
  }

  /// Check current memory usage and trigger cleanup if needed
  Future<void> _checkMemoryUsage() async {
    await _updateMemoryUsage();

    if (_currentMemoryUsage > _criticalThreshold) {
      debugPrint('MemoryManager: Critical memory usage: ${_currentMemoryUsage.toStringAsFixed(1)} MB');
      await forceCleanup(critical: true);
    } else if (_currentMemoryUsage > _warningThreshold) {
      debugPrint('MemoryManager: High memory usage: ${_currentMemoryUsage.toStringAsFixed(1)} MB');
      await forceCleanup(critical: false);
    }
  }

  /// Update current memory usage estimate
  Future<void> _updateMemoryUsage() async {
    try {
      // Get process memory info (platform-specific)
      if (Platform.isAndroid) {
        _currentMemoryUsage = await _getAndroidMemoryUsage();
      } else if (Platform.isIOS) {
        _currentMemoryUsage = await _getIOSMemoryUsage();
      } else {
        // Fallback: estimate from tracked objects
        final trackedSize = _trackedObjects.values.fold<int>(0, (sum, size) => sum + size);
        _currentMemoryUsage = trackedSize / 1024 / 1024;
      }
    } catch (e) {
      debugPrint('MemoryManager: Failed to get memory usage: $e');
    }
  }

  /// Get Android memory usage via platform channel
  Future<double> _getAndroidMemoryUsage() async {
    try {
      const platform = MethodChannel('com.trailrun.memory');
      final result = await platform.invokeMethod<int>('getMemoryUsage');
      return (result ?? 0) / 1024 / 1024; // Convert bytes to MB
    } catch (e) {
      return 0.0;
    }
  }

  /// Get iOS memory usage via platform channel
  Future<double> _getIOSMemoryUsage() async {
    try {
      const platform = MethodChannel('com.trailrun.memory');
      final result = await platform.invokeMethod<int>('getMemoryUsage');
      return (result ?? 0) / 1024 / 1024; // Convert bytes to MB
    } catch (e) {
      return 0.0;
    }
  }

  /// Clean up objects that are too old
  void _cleanupOldObjects() {
    final now = DateTime.now();
    final oldObjects = <String>[];

    for (final entry in _objectTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age.inMinutes > 30) { // Objects older than 30 minutes
        oldObjects.add(entry.key);
      }
    }

    for (final key in oldObjects) {
      untrackObject(key);
    }

    if (oldObjects.isNotEmpty) {
      debugPrint('MemoryManager: Cleaned up ${oldObjects.length} old objects');
    }
  }

  /// Force garbage collection
  Future<void> _forceGarbageCollection() async {
    // Multiple GC calls to ensure thorough cleanup
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      // Note: Dart doesn't expose direct GC control, but creating pressure
      // and waiting can encourage collection
    }
  }

  /// Check if memory usage is critical
  bool isCriticalMemoryUsage() {
    return _currentMemoryUsage > _criticalThreshold;
  }

  /// Check if memory usage is high
  bool isHighMemoryUsage() {
    return _currentMemoryUsage > _warningThreshold;
  }

  /// Get memory status
  MemoryStatus getMemoryStatus() {
    if (_currentMemoryUsage > _criticalThreshold) {
      return MemoryStatus.critical;
    } else if (_currentMemoryUsage > _warningThreshold) {
      return MemoryStatus.high;
    } else {
      return MemoryStatus.normal;
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _cleanupCallbacks.clear();
    _criticalCleanupCallbacks.clear();
    _trackedObjects.clear();
    _objectTimestamps.clear();
  }
}

/// Memory status levels
enum MemoryStatus {
  normal,
  high,
  critical,
}

/// Memory-aware data structure that automatically manages its size
class MemoryAwareList<T> {
  MemoryAwareList({
    required this.maxSize,
    required this.estimateItemSize,
    this.onItemEvicted,
  }) {
    _memoryManager.registerCleanupCallback(_cleanup);
  }

  final int maxSize;
  final int Function(T item) estimateItemSize;
  final void Function(T item)? onItemEvicted;

  final List<T> _items = [];
  final MemoryManager _memoryManager = MemoryManager();
  int _currentSize = 0;

  /// Add item to the list
  void add(T item) {
    final itemSize = estimateItemSize(item);
    
    // Remove old items if necessary
    while (_items.length >= maxSize || 
           (_memoryManager.isCriticalMemoryUsage() && _items.isNotEmpty)) {
      final removed = _items.removeAt(0);
      _currentSize -= estimateItemSize(removed);
      onItemEvicted?.call(removed);
    }

    _items.add(item);
    _currentSize += itemSize;
  }

  /// Get all items
  List<T> get items => List.unmodifiable(_items);

  /// Get current count
  int get length => _items.length;

  /// Get estimated size in bytes
  int get estimatedSize => _currentSize;

  /// Clear all items
  void clear() {
    for (final item in _items) {
      onItemEvicted?.call(item);
    }
    _items.clear();
    _currentSize = 0;
  }

  /// Cleanup old items based on memory pressure
  void _cleanup() {
    if (_memoryManager.isCriticalMemoryUsage()) {
      // Remove 50% of items in critical memory situation
      final removeCount = (_items.length * 0.5).round();
      for (int i = 0; i < removeCount && _items.isNotEmpty; i++) {
        final removed = _items.removeAt(0);
        _currentSize -= estimateItemSize(removed);
        onItemEvicted?.call(removed);
      }
    } else if (_memoryManager.isHighMemoryUsage()) {
      // Remove 25% of items in high memory situation
      final removeCount = (_items.length * 0.25).round();
      for (int i = 0; i < removeCount && _items.isNotEmpty; i++) {
        final removed = _items.removeAt(0);
        _currentSize -= estimateItemSize(removed);
        onItemEvicted?.call(removed);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryManager.removeCleanupCallback(_cleanup);
    clear();
  }
}