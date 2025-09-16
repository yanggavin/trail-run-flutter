import 'package:flutter_test/flutter_test.dart';
import '../../../lib/data/services/memory_manager.dart';

void main() {
  group('MemoryManager Tests', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager();
    });

    tearDown(() {
      memoryManager.dispose();
    });

    test('should track and untrack objects correctly', () {
      // Track an object
      memoryManager.trackObject('test_object', 1024 * 1024); // 1MB
      
      final stats = memoryManager.getTrackedObjectsSummary();
      expect(stats['objectCount'], equals(1));
      expect(stats['totalSizeMB'], equals(1.0));
      
      // Untrack the object
      memoryManager.untrackObject('test_object');
      
      final statsAfter = memoryManager.getTrackedObjectsSummary();
      expect(statsAfter['objectCount'], equals(0));
      expect(statsAfter['totalSizeMB'], equals(0.0));
    });

    test('should register and execute cleanup callbacks', () async {
      bool cleanupCalled = false;
      bool criticalCleanupCalled = false;
      
      memoryManager.registerCleanupCallback(() {
        cleanupCalled = true;
      });
      
      memoryManager.registerCriticalCleanupCallback(() {
        criticalCleanupCalled = true;
      });
      
      // Test normal cleanup
      await memoryManager.forceCleanup(critical: false);
      expect(cleanupCalled, isTrue);
      expect(criticalCleanupCalled, isFalse);
      
      // Reset flags
      cleanupCalled = false;
      criticalCleanupCalled = false;
      
      // Test critical cleanup
      await memoryManager.forceCleanup(critical: true);
      expect(cleanupCalled, isTrue);
      expect(criticalCleanupCalled, isTrue);
    });

    test('should start and stop monitoring', () {
      expect(memoryManager.getCurrentMemoryUsage(), equals(0.0));
      
      memoryManager.startMonitoring(interval: const Duration(milliseconds: 100));
      // Note: In real scenario, monitoring would update memory usage
      
      memoryManager.stopMonitoring();
      // Verify monitoring stopped without errors
    });

    test('should remove cleanup callbacks', () async {
      bool cleanupCalled = false;
      
      void cleanupCallback() {
        cleanupCalled = true;
      }
      
      memoryManager.registerCleanupCallback(cleanupCallback);
      memoryManager.removeCleanupCallback(cleanupCallback);
      
      await memoryManager.forceCleanup();
      expect(cleanupCalled, isFalse);
    });

    test('should handle memory status correctly', () {
      // Initially should be normal
      expect(memoryManager.getMemoryStatus(), equals(MemoryStatus.normal));
      expect(memoryManager.isHighMemoryUsage(), isFalse);
      expect(memoryManager.isCriticalMemoryUsage(), isFalse);
    });
  });

  group('MemoryAwareList Tests', () {
    test('should limit size and evict items', () {
      final evictedItems = <String>[];
      
      final list = MemoryAwareList<String>(
        maxSize: 3,
        estimateItemSize: (item) => item.length,
        onItemEvicted: (item) => evictedItems.add(item),
      );
      
      // Add items up to max size
      list.add('item1');
      list.add('item2');
      list.add('item3');
      
      expect(list.length, equals(3));
      expect(evictedItems.length, equals(0));
      
      // Add one more item, should evict the first
      list.add('item4');
      
      expect(list.length, equals(3));
      expect(evictedItems.length, equals(1));
      expect(evictedItems.first, equals('item1'));
      
      list.dispose();
    });

    test('should calculate estimated size correctly', () {
      final list = MemoryAwareList<String>(
        maxSize: 10,
        estimateItemSize: (item) => item.length,
      );
      
      list.add('hello'); // 5 bytes
      list.add('world'); // 5 bytes
      
      expect(list.estimatedSize, equals(10));
      
      list.dispose();
    });

    test('should clear all items', () {
      final evictedItems = <String>[];
      
      final list = MemoryAwareList<String>(
        maxSize: 10,
        estimateItemSize: (item) => item.length,
        onItemEvicted: (item) => evictedItems.add(item),
      );
      
      list.add('item1');
      list.add('item2');
      list.add('item3');
      
      expect(list.length, equals(3));
      
      list.clear();
      
      expect(list.length, equals(0));
      expect(list.estimatedSize, equals(0));
      expect(evictedItems.length, equals(3));
      
      list.dispose();
    });
  });
}