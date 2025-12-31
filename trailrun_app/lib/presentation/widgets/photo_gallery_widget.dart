import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/photo.dart';
import '../../data/services/share_export_provider.dart';

/// Widget displaying a grid or horizontal list of photos
class PhotoGalleryWidget extends StatelessWidget {
  const PhotoGalleryWidget({
    super.key,
    required this.photos,
    required this.onPhotoTap,
    this.scrollDirection = Axis.vertical,
    this.crossAxisCount = 2,
    this.maxPhotos,
    this.aspectRatio = 1.0,
    this.spacing = 8.0,
  });

  final List<Photo> photos;
  final Function(Photo) onPhotoTap;
  final Axis scrollDirection;
  final int crossAxisCount;
  final int? maxPhotos;
  final double aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No photos captured',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final displayPhotos = maxPhotos != null 
        ? photos.take(maxPhotos!).toList()
        : photos;

    if (scrollDirection == Axis.horizontal) {
      return _buildHorizontalGallery(displayPhotos);
    } else {
      return _buildGridGallery(displayPhotos);
    }
  }

  Widget _buildHorizontalGallery(List<Photo> displayPhotos) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: spacing),
      itemCount: displayPhotos.length,
      itemBuilder: (context, index) {
        final photo = displayPhotos[index];
        return Container(
          width: 100,
          margin: EdgeInsets.only(right: spacing),
          child: _PhotoThumbnail(
            photo: photo,
            onTap: () => onPhotoTap(photo),
            aspectRatio: aspectRatio,
          ),
        );
      },
    );
  }

  Widget _buildGridGallery(List<Photo> displayPhotos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: displayPhotos.length,
      itemBuilder: (context, index) {
        final photo = displayPhotos[index];
        return _PhotoThumbnail(
          photo: photo,
          onTap: () => onPhotoTap(photo),
          aspectRatio: aspectRatio,
        );
      },
    );
  }
}

/// Individual photo thumbnail widget
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
    required this.aspectRatio,
  });

  final Photo photo;
  final VoidCallback onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo image
              _buildPhotoImage(),
              
              // Location indicator
              if (photo.hasLocation)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              
              // Caption indicator
              if (photo.caption?.isNotEmpty == true)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoImage() {
    // Try to load thumbnail first, then full image
    final imagePath = photo.thumbnailPath ?? photo.filePath;
    
    if (imagePath.startsWith('http')) {
      // Network image
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      // Local file image
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder();
          },
        );
      } else {
        return _buildErrorPlaceholder();
      }
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            'Image not found',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Full-screen photo gallery screen
class PhotoGalleryScreen extends ConsumerStatefulWidget {
  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    required this.activityTitle,
    this.initialPhotoIndex = 0,
  });

  final List<Photo> photos;
  final String activityTitle;
  final int initialPhotoIndex;

  @override
  ConsumerState<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends ConsumerState<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPhotoIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.activityTitle),
        ),
        body: const Center(
          child: Text('No photos to display'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showPhotoInfo,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _sharePhoto,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return InteractiveViewer(
            child: Center(
              child: _buildFullSizeImage(photo),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _currentIndex > 0 ? _previousPhoto : null,
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.photos.length,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _currentIndex < widget.photos.length - 1 ? _nextPhoto : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSizeImage(Photo photo) {
    final imagePath = photo.filePath;
    
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'Image file not found',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }
    }
  }

  void _previousPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPhoto() {
    if (_currentIndex < widget.photos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showPhotoInfo() {
    final photo = widget.photos[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Captured: ${photo.timestamp.dateTime.toString()}'),
            if (photo.coordinates != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${photo.coordinates!.latitude.toStringAsFixed(6)}, ${photo.coordinates!.longitude.toStringAsFixed(6)}'),
            ],
            if (photo.caption?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Caption: ${photo.caption}'),
            ],
            const SizedBox(height: 8),
            Text('File: ${photo.filePath.split('/').last}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePhoto() async {
    final photo = widget.photos[_currentIndex];
    final shareService = ref.read(shareExportServiceProvider);
    
    try {
      await shareService.sharePhoto(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}