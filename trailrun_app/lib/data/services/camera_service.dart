import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../../domain/models/photo.dart';
import '../../domain/value_objects/coordinates.dart';
import 'photo_service.dart';

/// Service for managing camera operations during activity tracking
class CameraService {
  CameraService._();
  
  static CameraService? _instance;
  static CameraService get instance => _instance ??= CameraService._();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;

  /// Initialize camera service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _cameras = await PhotoService.getAvailableCameras();
      if (_cameras!.isEmpty) {
        throw CameraServiceException('No cameras available');
      }

      // Use back camera by default for trail running
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = PhotoService.createCameraController(backCamera);
      await _controller!.initialize();
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;
      
      _isInitialized = true;
    } catch (e) {
      throw CameraServiceException('Failed to initialize camera: $e');
    }
  }

  /// Get camera controller for UI
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized && _controller?.value.isInitialized == true;

  /// Check if currently capturing
  bool get isCapturing => _isCapturing;

  /// Get available cameras
  List<CameraDescription>? get availableCameras => _cameras;

  /// Switch to different camera
  Future<void> switchCamera(CameraDescription camera) async {
    if (!_isInitialized) {
      throw CameraServiceException('Camera service not initialized');
    }

    try {
      await _controller?.dispose();
      _controller = PhotoService.createCameraController(camera);
      await _controller!.initialize();
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _currentZoomLevel = _minZoomLevel;
    } catch (e) {
      throw CameraServiceException('Failed to switch camera: $e');
    }
  }

  /// Capture photo during activity tracking
  Future<Photo> capturePhotoForActivity({
    required String activityId,
    Coordinates? currentLocation,
  }) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    if (_isCapturing) {
      throw CameraServiceException('Already capturing photo');
    }

    _isCapturing = true;
    
    try {
      // Provide haptic feedback
      await HapticFeedback.lightImpact();

      final photo = await PhotoService.capturePhoto(
        controller: _controller!,
        activityId: activityId,
        currentLocation: currentLocation,
      );

      // Provide success haptic feedback
      await HapticFeedback.selectionClick();

      return photo;
    } catch (e) {
      // Provide error haptic feedback
      await HapticFeedback.heavyImpact();
      throw CameraServiceException('Failed to capture photo: $e');
    } finally {
      _isCapturing = false;
    }
  }

  /// Start camera preview (for UI)
  Future<void> startPreview() async {
    if (!isInitialized) {
      await initialize();
    }
    // Camera preview is handled by the UI widget
  }

  /// Stop camera preview
  Future<void> stopPreview() async {
    // Preview stopping is handled by the UI widget
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      throw CameraServiceException('Failed to set flash mode: $e');
    }
  }

  /// Get current flash mode
  FlashMode get flashMode => _controller?.value.flashMode ?? FlashMode.auto;

  /// Set exposure mode
  Future<void> setExposureMode(ExposureMode mode) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      await _controller!.setExposureMode(mode);
    } catch (e) {
      throw CameraServiceException('Failed to set exposure mode: $e');
    }
  }

  /// Set focus mode
  Future<void> setFocusMode(FocusMode mode) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      await _controller!.setFocusMode(mode);
    } catch (e) {
      throw CameraServiceException('Failed to set focus mode: $e');
    }
  }

  /// Set focus point
  Future<void> setFocusPoint(Offset point) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      await _controller!.setFocusPoint(point);
    } catch (e) {
      throw CameraServiceException('Failed to set focus point: $e');
    }
  }

  /// Set exposure point
  Future<void> setExposurePoint(Offset point) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      await _controller!.setExposurePoint(point);
    } catch (e) {
      throw CameraServiceException('Failed to set exposure point: $e');
    }
  }

  /// Get camera capabilities
  CameraCapabilities? get capabilities {
    if (!isInitialized) return null;
    
    return CameraCapabilities(
      hasFlash: _controller!.value.flashMode != null,
      supportedFlashModes: [
        FlashMode.off,
        FlashMode.auto,
        FlashMode.always,
        FlashMode.torch,
      ],
      maxZoomLevel: _maxZoomLevel,
      minZoomLevel: _minZoomLevel,
    );
  }

  /// Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (!isInitialized) {
      throw CameraServiceException('Camera not initialized');
    }

    try {
      final clampedZoom = zoom.clamp(_minZoomLevel, _maxZoomLevel) as double;
      await _controller!.setZoomLevel(clampedZoom);
      _currentZoomLevel = clampedZoom;
    } catch (e) {
      throw CameraServiceException('Failed to set zoom level: $e');
    }
  }

  /// Get current zoom level
  double get zoomLevel => _currentZoomLevel;

  /// Dispose camera resources
  Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _isCapturing = false;
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  /// Pause camera (for app lifecycle management)
  Future<void> pause() async {
    // Camera pausing is handled automatically by the system
  }

  /// Resume camera (for app lifecycle management)
  Future<void> resume() async {
    if (_controller != null && !_controller!.value.isInitialized) {
      try {
        await _controller!.initialize();
      } catch (e) {
        print('Error resuming camera: $e');
      }
    }
  }
}

/// Camera capabilities information
class CameraCapabilities {
  const CameraCapabilities({
    required this.hasFlash,
    required this.supportedFlashModes,
    required this.maxZoomLevel,
    required this.minZoomLevel,
  });

  final bool hasFlash;
  final List<FlashMode> supportedFlashModes;
  final double maxZoomLevel;
  final double minZoomLevel;

  bool get supportsZoom => maxZoomLevel > minZoomLevel;
}

/// Exception thrown by CameraService operations
class CameraServiceException implements Exception {
  const CameraServiceException(this.message);
  
  final String message;
  
  @override
  String toString() => 'CameraServiceException: $message';
}
