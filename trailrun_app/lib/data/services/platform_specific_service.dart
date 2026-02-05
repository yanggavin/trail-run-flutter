import 'dart:io';
import 'package:flutter/services.dart';

/// Platform-specific service for handling native functionality
class PlatformSpecificService {
  static const MethodChannel _locationChannel = MethodChannel('com.trailrun.location_service');
  static const MethodChannel _permissionChannel = MethodChannel('com.trailrun.permissions');
  static const MethodChannel _lifecycleChannel = MethodChannel('com.trailrun.app_lifecycle');

  // Location service methods
  static Future<void> startForegroundService(String activityId) async {
    try {
      if (Platform.isAndroid) {
        await _locationChannel.invokeMethod('startForegroundService', {
          'activityId': activityId,
        });
      } else if (Platform.isIOS) {
        await _locationChannel.invokeMethod('startBackgroundLocationUpdates', {
          'activityId': activityId,
        });
      }
    } catch (e) {
      // Handle platform method not implemented gracefully
    }
  }

  static Future<void> stopForegroundService() async {
    try {
      if (Platform.isAndroid) {
        await _locationChannel.invokeMethod('stopForegroundService');
      } else if (Platform.isIOS) {
        await _locationChannel.invokeMethod('stopBackgroundLocationUpdates');
      }
    } catch (e) {
      // Handle platform method not implemented gracefully
    }
  }

  static Future<void> pauseTracking() async {
    try {
      if (Platform.isAndroid) {
        await _locationChannel.invokeMethod('pauseTracking');
      } else if (Platform.isIOS) {
        await _locationChannel.invokeMethod('pauseBackgroundLocationUpdates');
      }
    } catch (e) {
      // Handle platform method not implemented gracefully
    }
  }

  static Future<void> resumeTracking() async {
    try {
      if (Platform.isAndroid) {
        await _locationChannel.invokeMethod('resumeTracking');
      } else if (Platform.isIOS) {
        await _locationChannel.invokeMethod('resumeBackgroundLocationUpdates');
      }
    } catch (e) {
      // Handle platform method not implemented gracefully
    }
  }

  static Future<void> updateSamplingInterval(int intervalSeconds) async {
    await _locationChannel.invokeMethod('updateSamplingInterval', {
      'intervalSeconds': intervalSeconds,
    });
  }

  static Future<void> updateServiceNotification({
    required String distance,
    required String duration,
    required String pace,
  }) async {
    if (Platform.isAndroid) {
      await _locationChannel.invokeMethod('updateServiceNotification', {
        'distance': distance,
        'duration': duration,
        'pace': pace,
      });
    }
    // iOS doesn't need notification updates as it uses system location indicator
  }

  static Future<Map<String, dynamic>> getBatteryInfo() async {
    final result = await _locationChannel.invokeMethod('getBatteryInfo');
    return Map<String, dynamic>.from(result ?? {});
  }

  // Permission methods
  static Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      final result = await _permissionChannel.invokeMethod<int>('getAndroidSdkVersion');
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<String> getIOSVersion() async {
    if (!Platform.isIOS) return '';
    
    try {
      final result = await _permissionChannel.invokeMethod<String>('getIOSVersion');
      return result ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<bool> isLowPowerModeEnabled() async {
    try {
      final result = await _permissionChannel.invokeMethod<bool>('isLowPowerModeEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getBackgroundAppRefreshStatus() async {
    if (!Platform.isIOS) return 'Unknown';

    try {
      final result = await _permissionChannel.invokeMethod<String>('getBackgroundAppRefreshStatus');
      return result ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _permissionChannel.invokeMethod('openAppSettings');
    } catch (e) {
      // Fallback to permission_handler's openAppSettings
      // This will be handled by the permission service
    }
  }

  // App lifecycle methods
  static void setLifecycleHandler(Function(String) onLifecycleChanged) {
    _lifecycleChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onForeground':
          onLifecycleChanged('foreground');
          break;
        case 'onBackground':
          onLifecycleChanged('background');
          break;
        case 'onActive':
          onLifecycleChanged('active');
          break;
        case 'onInactive':
          onLifecycleChanged('inactive');
          break;
      }
    });
  }

  // Platform-specific file operations
  static Future<String> getPlatformSpecificStoragePath() async {
    if (Platform.isIOS) {
      return 'Documents'; // iOS Documents directory
    } else {
      return 'Android/data/com.trailrun.trailrun_app/files'; // Android app-specific directory
    }
  }

  // Platform-specific sharing
  static Future<bool> canUseNativeShare() async {
    // Both platforms support native sharing through share_plus
    return true;
  }

  // Platform-specific accessibility
  static Future<bool> isAccessibilityEnabled() async {
    try {
      if (Platform.isAndroid) {
        // Android accessibility check would require additional native code
        return false; // Placeholder
      } else if (Platform.isIOS) {
        // iOS accessibility check would require additional native code
        return false; // Placeholder
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Platform-specific high contrast mode
  static Future<bool> isHighContrastEnabled() async {
    try {
      if (Platform.isAndroid) {
        // Android high contrast check would require additional native code
        return false; // Placeholder
      } else if (Platform.isIOS) {
        // iOS high contrast check would require additional native code
        return false; // Placeholder
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
