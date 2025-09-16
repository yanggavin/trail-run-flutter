import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../data/services/camera_service.dart';
import '../providers/location_provider.dart';
import '../providers/activity_tracking_provider.dart';

/// Widget for quick photo capture during tracking
class CameraQuickCaptureWidget extends ConsumerStatefulWidget {
  const CameraQuickCaptureWidget({
    super.key,
    required this.isTracking,
    this.onPhotoCaptured,
  });

  final bool isTracking;
  final VoidCallback? onPhotoCaptured;

  @override
  ConsumerState<CameraQuickCaptureWidget> createState() => _CameraQuickCaptureWidgetState();
}

class _CameraQuickCaptureWidgetState extends ConsumerState<CameraQuickCaptureWidget> {
  bool _isCapturing = false;
  String? _captureError;

  @override
  Widget build(BuildContext context) {
    if (!widget.isTracking) {
      return _buildDisabledState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCameraPreview(),
          const SizedBox(height: 16),
          _buildCaptureButton(),
          if (_captureError != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildDisabledState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Camera Available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking to capture photos',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final cameraService = CameraService.instance;
    
    if (!cameraService.isInitialized) {
      return _buildPreviewPlaceholder('Initializing camera...');
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: cameraService.controller!.value.aspectRatio,
          child: CameraPreview(cameraService.controller!),
        ),
      ),
    );
  }

  Widget _buildPreviewPlaceholder(String message) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _capturePhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isCapturing ? Colors.grey : Colors.white,
          border: Border.all(
            color: _isCapturing ? Colors.grey.shade600 : Colors.blue,
            width: 3,
          ),
          boxShadow: _isCapturing ? null : [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isCapturing
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : const Icon(
                Icons.camera_alt,
                color: Colors.blue,
                size: 28,
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _captureError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _captureError = null;
    });

    try {
      // Provide immediate haptic feedback
      await HapticFeedback.lightImpact();

      // Get current activity and location
      final trackingState = ref.read(activityTrackingProvider);
      final locationState = ref.read(locationProvider);

      if (trackingState.currentActivity == null) {
        throw Exception('No active tracking session');
      }

      // Capture photo with current location
      await CameraService.instance.capturePhotoForActivity(
        activityId: trackingState.currentActivity!.id,
        currentLocation: locationState.currentLocation?.coordinates,
      );

      // Success feedback
      await HapticFeedback.selectionClick();
      
      // Flash effect
      _showCaptureFlash();

      // Notify parent
      widget.onPhotoCaptured?.call();

    } catch (e) {
      // Error feedback
      await HapticFeedback.heavyImpact();
      
      setState(() {
        _captureError = _getErrorMessage(e);
      });

      // Clear error after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _captureError = null;
          });
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showCaptureFlash() {
    // Create a white overlay for flash effect
    final overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );

    Overlay.of(context).insert(overlay);

    // Remove overlay after brief flash
    Future.delayed(const Duration(milliseconds: 100), () {
      overlay.remove();
    });
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('permission')) {
      return 'Camera permission required';
    } else if (errorString.contains('not initialized')) {
      return 'Camera not ready';
    } else if (errorString.contains('already capturing')) {
      return 'Please wait...';
    } else if (errorString.contains('No active tracking')) {
      return 'Start tracking first';
    } else {
      return 'Capture failed';
    }
  }
}