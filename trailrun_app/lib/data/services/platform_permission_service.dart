import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart' as perm;

/// Platform-specific permission handling service
class PlatformPermissionService {
  static const MethodChannel _channel = MethodChannel('com.trailrun.permissions');

  /// Request location permissions with platform-appropriate flow
  static Future<LocationPermissionResult> requestLocationPermission() async {
    if (Platform.isIOS) {
      return _requestIOSLocationPermission();
    } else if (Platform.isAndroid) {
      return _requestAndroidLocationPermission();
    }
    
    return LocationPermissionResult.denied;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await perm.Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage/photo permissions
  static Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) {
      final status = await perm.Permission.photos.request();
      return status.isGranted;
    } else {
      // Android 13+ uses granular photo permissions
      if (await _isAndroid13OrHigher()) {
        final status = await perm.Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await perm.Permission.storage.request();
        return status.isGranted;
      }
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await perm.Permission.camera.isGranted;
  }

  /// Check if storage/photo permission is granted
  static Future<bool> hasStoragePermission() async {
    return await _checkStoragePermission();
  }

  /// Check if all required permissions are granted
  static Future<PermissionStatus> checkAllPermissions() async {
    final locationResult = await _checkLocationPermission();
    final cameraGranted = await perm.Permission.camera.isGranted;
    final storageGranted = await _checkStoragePermission();

    return PermissionStatus(
      location: locationResult,
      camera: cameraGranted,
      storage: storageGranted,
    );
  }

  /// iOS-specific location permission request
  static Future<LocationPermissionResult> _requestIOSLocationPermission() async {
    try {
      // First request when-in-use permission
      var status = await perm.Permission.locationWhenInUse.request();
      
      if (!status.isGranted) {
        return LocationPermissionResult.denied;
      }

      // Then request always permission for background tracking
      status = await perm.Permission.locationAlways.request();
      
      if (status.isGranted) {
        return LocationPermissionResult.always;
      } else if (await perm.Permission.locationWhenInUse.isGranted) {
        return LocationPermissionResult.whileInUse;
      } else {
        return LocationPermissionResult.denied;
      }
    } catch (e) {
      return LocationPermissionResult.denied;
    }
  }

  /// Android-specific location permission request
  static Future<LocationPermissionResult> _requestAndroidLocationPermission() async {
    try {
      // Request fine location first
      var status = await perm.Permission.location.request();
      
      if (!status.isGranted) {
        return LocationPermissionResult.denied;
      }

      // For Android 10+ (API 29+), request background location separately
      if (await _isAndroid10OrHigher()) {
        final backgroundStatus = await perm.Permission.locationAlways.request();
        
        if (backgroundStatus.isGranted) {
          return LocationPermissionResult.always;
        } else {
          return LocationPermissionResult.whileInUse;
        }
      } else {
        return LocationPermissionResult.always;
      }
    } catch (e) {
      return LocationPermissionResult.denied;
    }
  }

  /// Check current location permission status
  static Future<LocationPermissionResult> _checkLocationPermission() async {
    if (Platform.isIOS) {
      if (await perm.Permission.locationAlways.isGranted) {
        return LocationPermissionResult.always;
      } else if (await perm.Permission.locationWhenInUse.isGranted) {
        return LocationPermissionResult.whileInUse;
      } else {
        return LocationPermissionResult.denied;
      }
    } else {
      if (await perm.Permission.locationAlways.isGranted) {
        return LocationPermissionResult.always;
      } else if (await perm.Permission.location.isGranted) {
        return LocationPermissionResult.whileInUse;
      } else {
        return LocationPermissionResult.denied;
      }
    }
  }

  /// Check storage permission status
  static Future<bool> _checkStoragePermission() async {
    if (Platform.isIOS) {
      return await perm.Permission.photos.isGranted;
    } else {
      if (await _isAndroid13OrHigher()) {
        return await perm.Permission.photos.isGranted;
      } else {
        return await perm.Permission.storage.isGranted;
      }
    }
  }

  /// Check if Android version is 10 or higher (API 29+)
  static Future<bool> _isAndroid10OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<int>('getAndroidSdkVersion');
      return (result ?? 0) >= 29;
    } catch (e) {
      return false;
    }
  }

  /// Check if Android version is 13 or higher (API 33+)
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<int>('getAndroidSdkVersion');
      return (result ?? 0) >= 33;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for manual permission configuration
  static Future<void> openAppSettings() async {
    await perm.openAppSettings();
  }

  /// Open location settings for enabling GPS services
  static Future<void> openLocationSettings() async {
    await geolocator.Geolocator.openLocationSettings();
  }

  /// Get Android SDK version (0 on non-Android or failure)
  static Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      return await _channel.invokeMethod<int>('getAndroidSdkVersion') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Show platform-appropriate permission rationale
  static Future<bool> shouldShowPermissionRationale(perm.Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }
}

/// Location permission result
enum LocationPermissionResult {
  denied,
  whileInUse,
  always,
}

/// Overall permission status
class PermissionStatus {
  final LocationPermissionResult location;
  final bool camera;
  final bool storage;

  const PermissionStatus({
    required this.location,
    required this.camera,
    required this.storage,
  });

  bool get hasAllRequired => 
    location != LocationPermissionResult.denied && camera && storage;

  bool get hasBackgroundLocation => location == LocationPermissionResult.always;
}
