import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import '../../../lib/data/services/progressive_photo_loader.dart';

void main() {
  group('ProgressivePhotoLoader Tests', () {
    setUp(() {
      ProgressivePhotoLoader.clearCaches();
    });

    tearDown(() {
      ProgressivePhotoLoader.clearCaches();
    });

    test('should clear all caches', () {
      ProgressivePhotoLoader.clearCaches();
      
      final stats = ProgressivePhotoLoader.getCacheStats();
      expect(stats['thumbnailCount'], equals(0));
      expect(stats['fullImageCount'], equals(0));
      expect(stats['thumbnailCacheSize'], equals(0));
      expect(stats['fullImageCacheSize'], equals(0));
    });

    test('should clear thumbnail cache only', () {
      ProgressivePhotoLoader.clearThumbnailCache();
      
      final stats = ProgressivePhotoLoader.getCacheStats();
      expect(stats['thumbnailCount'], equals(0));
      expect(stats['thumbnailCacheSize'], equals(0));
    });

    test('should clear full image cache only', () {
      ProgressivePhotoLoader.clearFullImageCache();
      
      final stats = ProgressivePhotoLoader.getCacheStats();
      expect(stats['fullImageCount'], equals(0));
      expect(stats['fullImageCacheSize'], equals(0));
    });

    test('should get cache statistics', () {
      final stats = ProgressivePhotoLoader.getCacheStats();
      
      expect(stats, containsPair('thumbnailCount', 0));
      expect(stats, containsPair('fullImageCount', 0));
      expect(stats, containsPair('thumbnailCacheSize', 0));
      expect(stats, containsPair('fullImageCacheSize', 0));
      expect(stats, containsPair('maxThumbnailCacheSize', isA<int>()));
      expect(stats, containsPair('maxFullImageCacheSize', isA<int>()));
    });

    test('should remove specific image from cache', () {
      const testPath = '/test/image.jpg';
      
      // This would normally add to cache, but since file doesn't exist,
      // we just test that the method doesn't throw
      ProgressivePhotoLoader.removeFromCache(testPath);
      
      // Verify no errors occurred
      final stats = ProgressivePhotoLoader.getCacheStats();
      expect(stats['thumbnailCount'], equals(0));
      expect(stats['fullImageCount'], equals(0));
    });

    test('should handle preload thumbnails gracefully', () async {
      final photoPaths = ['/test/photo1.jpg', '/test/photo2.jpg'];
      
      // Should complete without throwing, even though files don't exist
      await ProgressivePhotoLoader.preloadThumbnails(photoPaths);
      
      // Verify method completed
      expect(true, isTrue);
    });

    test('should handle load thumbnail for non-existent file', () async {
      const testPath = '/non/existent/file.jpg';
      
      final result = await ProgressivePhotoLoader.loadThumbnail(testPath);
      
      // Should return null for non-existent file
      expect(result, isNull);
    });

    test('should handle load full image for non-existent file', () async {
      const testPath = '/non/existent/file.jpg';
      
      final result = await ProgressivePhotoLoader.loadFullImage(testPath);
      
      // Should return null for non-existent file
      expect(result, isNull);
    });
  });

  group('ProgressivePhotoWidget Tests', () {
    testWidgets('should create widget with required parameters', (tester) async {
      const widget = ProgressivePhotoWidget(
        photoPath: '/test/photo.jpg',
        width: 100,
        height: 100,
      );
      
      expect(widget.photoPath, equals('/test/photo.jpg'));
      expect(widget.width, equals(100));
      expect(widget.height, equals(100));
      expect(widget.fit, equals(BoxFit.cover));
    });

    testWidgets('should create widget with custom parameters', (tester) async {
      const placeholder = SizedBox(width: 50, height: 50);
      const errorWidget = Icon(Icons.error);
      
      const widget = ProgressivePhotoWidget(
        photoPath: '/test/photo.jpg',
        width: 200,
        height: 150,
        fit: BoxFit.contain,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
      
      expect(widget.photoPath, equals('/test/photo.jpg'));
      expect(widget.width, equals(200));
      expect(widget.height, equals(150));
      expect(widget.fit, equals(BoxFit.contain));
      expect(widget.placeholder, equals(placeholder));
      expect(widget.errorWidget, equals(errorWidget));
    });
  });
}