import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailrun_app/data/services/platform_specific_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformSpecificService', () {
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];
      
      // Mock location service channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trailrun.location_service'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'startForegroundService':
            case 'startBackgroundLocationUpdates':
            case 'stopForegroundService':
            case 'stopBackgroundLocationUpdates':
            case 'pauseTracking':
            case 'pauseBackgroundLocationUpdates':
            case 'resumeTracking':
            case 'resumeBackgroundLocationUpdates':
            case 'updateSamplingInterval':
            case 'updateServiceNotification':
              return null;
            case 'getBatteryInfo':
              return {
                'level': 0.75,
                'isLowPowerMode': false,
              };
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );

      // Mock permission channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trailrun.permissions'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'getAndroidSdkVersion':
              return 30;
            case 'getIOSVersion':
              return '15.0';
            case 'isLowPowerModeEnabled':
              return false;
            case 'openAppSettings':
              return true;
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trailrun.location_service'),
        null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.trailrun.permissions'),
        null,
      );
    });

    group('Location Service Methods', () {
      test('startForegroundService calls correct platform method', () async {
        const activityId = 'test-activity-123';
        
        await PlatformSpecificService.startForegroundService(activityId);
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, anyOf([
          'startForegroundService', // Android
          'startBackgroundLocationUpdates', // iOS
        ]));
        expect(methodCalls.first.arguments['activityId'], activityId);
      });

      test('stopForegroundService calls correct platform method', () async {
        await PlatformSpecificService.stopForegroundService();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, anyOf([
          'stopForegroundService', // Android
          'stopBackgroundLocationUpdates', // iOS
        ]));
      });

      test('pauseTracking calls correct platform method', () async {
        await PlatformSpecificService.pauseTracking();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, anyOf([
          'pauseTracking', // Android
          'pauseBackgroundLocationUpdates', // iOS
        ]));
      });

      test('resumeTracking calls correct platform method', () async {
        await PlatformSpecificService.resumeTracking();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, anyOf([
          'resumeTracking', // Android
          'resumeBackgroundLocationUpdates', // iOS
        ]));
      });

      test('updateSamplingInterval passes correct parameters', () async {
        const intervalSeconds = 5;
        
        await PlatformSpecificService.updateSamplingInterval(intervalSeconds);
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'updateSamplingInterval');
        expect(methodCalls.first.arguments['intervalSeconds'], intervalSeconds);
      });

      test('updateServiceNotification passes correct parameters', () async {
        const distance = '5.2 km';
        const duration = '25:30';
        const pace = '4:55/km';
        
        await PlatformSpecificService.updateServiceNotification(
          distance: distance,
          duration: duration,
          pace: pace,
        );
        
        // Should only call on Android
        if (methodCalls.isNotEmpty) {
          expect(methodCalls.first.method, 'updateServiceNotification');
          expect(methodCalls.first.arguments['distance'], distance);
          expect(methodCalls.first.arguments['duration'], duration);
          expect(methodCalls.first.arguments['pace'], pace);
        }
      });

      test('getBatteryInfo returns battery information', () async {
        final batteryInfo = await PlatformSpecificService.getBatteryInfo();
        
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'getBatteryInfo');
        expect(batteryInfo['level'], 0.75);
        expect(batteryInfo['isLowPowerMode'], false);
      });
    });

    group('Permission Methods', () {
      test('getAndroidSdkVersion returns SDK version', () async {
        final sdkVersion = await PlatformSpecificService.getAndroidSdkVersion();
        
        expect(sdkVersion, 30);
        expect(methodCalls.any((call) => call.method == 'getAndroidSdkVersion'), true);
      });

      test('getIOSVersion returns iOS version', () async {
        final iosVersion = await PlatformSpecificService.getIOSVersion();
        
        expect(iosVersion, '15.0');
        expect(methodCalls.any((call) => call.method == 'getIOSVersion'), true);
      });

      test('isLowPowerModeEnabled returns power mode status', () async {
        final isLowPowerMode = await PlatformSpecificService.isLowPowerModeEnabled();
        
        expect(isLowPowerMode, false);
        expect(methodCalls.any((call) => call.method == 'isLowPowerModeEnabled'), true);
      });

      test('openAppSettings calls platform method', () async {
        await PlatformSpecificService.openAppSettings();
        
        expect(methodCalls.any((call) => call.method == 'openAppSettings'), true);
      });
    });

    group('Platform-specific Features', () {
      test('getPlatformSpecificStoragePath returns correct path', () async {
        final storagePath = await PlatformSpecificService.getPlatformSpecificStoragePath();
        
        expect(storagePath, anyOf([
          'Documents', // iOS
          'Android/data/com.trailrun.trailrun_app/files', // Android
        ]));
      });

      test('canUseNativeShare returns true', () async {
        final canShare = await PlatformSpecificService.canUseNativeShare();
        
        expect(canShare, true);
      });

      test('isAccessibilityEnabled handles errors gracefully', () async {
        final isEnabled = await PlatformSpecificService.isAccessibilityEnabled();
        
        // Should return false as placeholder since we don't have native implementation
        expect(isEnabled, false);
      });

      test('isHighContrastEnabled handles errors gracefully', () async {
        final isEnabled = await PlatformSpecificService.isHighContrastEnabled();
        
        // Should return false as placeholder since we don't have native implementation
        expect(isEnabled, false);
      });
    });

    group('Error Handling', () {
      test('handles platform exceptions gracefully', () async {
        // Mock a method that throws an exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.trailrun.location_service'),
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'ERROR',
              message: 'Test error',
            );
          },
        );

        // Should not throw, but handle gracefully
        expect(() async {
          await PlatformSpecificService.getBatteryInfo();
        }, returnsNormally);
      });

      test('returns default values when platform calls fail', () async {
        // Mock permission channel to throw exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.trailrun.permissions'),
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'ERROR',
              message: 'Test error',
            );
          },
        );

        final sdkVersion = await PlatformSpecificService.getAndroidSdkVersion();
        final iosVersion = await PlatformSpecificService.getIOSVersion();
        final isLowPowerMode = await PlatformSpecificService.isLowPowerModeEnabled();

        expect(sdkVersion, 0);
        expect(iosVersion, '');
        expect(isLowPowerMode, false);
      });
    });
  });
}