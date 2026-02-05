import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../domain/errors/app_errors.dart' as domain_errors;
import 'location_service.dart' as location_service;
import 'platform_specific_service.dart';

/// Service for GPS diagnostics and troubleshooting information
class GpsDiagnosticsService {
  GpsDiagnosticsService({
    required this.locationService,
  });

  final location_service.LocationService locationService;

  /// Gets comprehensive GPS diagnostic information
  Future<GpsDiagnostics> getDiagnostics() async {
    try {
      final diagnostics = GpsDiagnostics();
      
      // Basic location service status
      diagnostics.isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      diagnostics.locationPermission = await Geolocator.checkPermission();
      
      // Device information
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        diagnostics.deviceInfo = {
          'platform': 'Android',
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        diagnostics.deviceInfo = {
          'platform': 'iOS',
          'version': iosInfo.systemVersion,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'localizedModel': iosInfo.localizedModel,
        };
      }

      // Location accuracy settings
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        diagnostics.lastKnownPosition = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp?.toIso8601String(),
        };
        
        diagnostics.gpsSignalQuality = _assessSignalQuality(position.accuracy);
        
      } catch (error) {
        diagnostics.locationError = error.toString();
      }

      // Battery optimization status (Android)
      if (Platform.isAndroid) {
        diagnostics.batteryOptimizationStatus = await _checkBatteryOptimization();
      }

      // Background app refresh status (iOS)
      if (Platform.isIOS) {
        diagnostics.backgroundAppRefreshStatus = await _checkBackgroundAppRefresh();
      }

      // Network connectivity
      diagnostics.networkConnectivity = await _checkNetworkConnectivity();
      
      // GPS satellite information (if available)
      diagnostics.satelliteInfo = await _getSatelliteInfo();
      
      diagnostics.timestamp = DateTime.now();
      
      return diagnostics;
      
    } catch (error, stackTrace) {
      debugPrint('Failed to get GPS diagnostics: $error\n$stackTrace');
      throw domain_errors.LocationError(
        type: domain_errors.LocationErrorType.signalLost,
        message: 'Failed to get GPS diagnostics: $error',
        userMessage: 'Unable to gather GPS diagnostic information.',
        recoveryActions: [
          domain_errors.RecoveryAction(
            title: 'Retry',
            description: 'Try to get diagnostics again',
            action: () async => await getDiagnostics(),
          ),
        ],
        diagnosticInfo: {
          'timestamp': DateTime.now().toIso8601String(),
          'error_type': error.runtimeType.toString(),
        },
      );
    }
  }

  /// Runs a GPS signal test and provides recommendations
  Future<GpsTestResult> runGpsTest({Duration testDuration = const Duration(minutes: 1)}) async {
    final testResult = GpsTestResult();
    testResult.startTime = DateTime.now();
    
    try {
      final positions = <Position>[];
      final accuracyReadings = <double>[];
      
      // Start location stream
      final locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      
      final subscription = locationStream.listen((position) {
        positions.add(position);
        accuracyReadings.add(position.accuracy);
      });
      
      // Run test for specified duration
      await Future.delayed(testDuration);
      await subscription.cancel();
      
      testResult.endTime = DateTime.now();
      testResult.totalReadings = positions.length;
      
      if (positions.isNotEmpty) {
        testResult.averageAccuracy = accuracyReadings.reduce((a, b) => a + b) / accuracyReadings.length;
        testResult.bestAccuracy = accuracyReadings.reduce((a, b) => a < b ? a : b);
        testResult.worstAccuracy = accuracyReadings.reduce((a, b) => a > b ? a : b);
        
        // Calculate signal stability
        final accuracyVariance = _calculateVariance(accuracyReadings);
        testResult.signalStability = accuracyVariance < 25 ? 'Stable' : 
                                   accuracyVariance < 100 ? 'Moderate' : 'Unstable';
        
        // Generate recommendations
        testResult.recommendations = _generateRecommendations(testResult);
      } else {
        testResult.recommendations = [
          'No GPS readings received. Check if location services are enabled.',
          'Try moving to an area with better sky visibility.',
          'Restart the app and try again.',
        ];
      }
      
      return testResult;
      
    } catch (error, stackTrace) {
      debugPrint('GPS test failed: $error\n$stackTrace');
      testResult.error = error.toString();
      testResult.recommendations = [
        'GPS test failed. Check location permissions.',
        'Ensure location services are enabled.',
        'Try restarting the device if problems persist.',
      ];
      return testResult;
    }
  }

  /// Gets user-friendly troubleshooting steps based on current GPS status
  Future<List<TroubleshootingStep>> getTroubleshootingSteps() async {
    final steps = <TroubleshootingStep>[];
    
    try {
      final diagnostics = await getDiagnostics();
      
      // Check location services
      if (!diagnostics.isLocationServiceEnabled) {
        steps.add(TroubleshootingStep(
          title: 'Enable Location Services',
          description: 'Location services are turned off on your device.',
          action: 'Go to Settings > Privacy & Security > Location Services and turn it on.',
          priority: TroubleshootingPriority.critical,
        ));
      }
      
      // Check permissions
      if (diagnostics.locationPermission == LocationPermission.denied ||
          diagnostics.locationPermission == LocationPermission.deniedForever) {
        steps.add(TroubleshootingStep(
          title: 'Grant Location Permission',
          description: 'TrailRun needs location permission to track your runs.',
          action: 'Go to Settings > Apps > TrailRun > Permissions and allow location access.',
          priority: TroubleshootingPriority.critical,
        ));
      }
      
      // Check GPS accuracy
      if (diagnostics.gpsSignalQuality == GpsSignalQuality.poor) {
        steps.add(TroubleshootingStep(
          title: 'Improve GPS Signal',
          description: 'GPS signal quality is poor.',
          action: 'Move to an open area away from buildings and trees. Wait a few minutes for GPS to lock on.',
          priority: TroubleshootingPriority.high,
        ));
      }
      
      // Check battery optimization (Android)
      if (Platform.isAndroid && diagnostics.batteryOptimizationStatus == 'Optimized') {
        steps.add(TroubleshootingStep(
          title: 'Disable Battery Optimization',
          description: 'Battery optimization may interfere with background location tracking.',
          action: 'Go to Settings > Battery > Battery Optimization and set TrailRun to "Not optimized".',
          priority: TroubleshootingPriority.medium,
        ));
      }
      
      // Check background app refresh (iOS)
      if (Platform.isIOS && diagnostics.backgroundAppRefreshStatus == 'Disabled') {
        steps.add(TroubleshootingStep(
          title: 'Enable Background App Refresh',
          description: 'Background App Refresh is needed for continuous tracking.',
          action: 'Go to Settings > General > Background App Refresh and enable it for TrailRun.',
          priority: TroubleshootingPriority.medium,
        ));
      }
      
      // General recommendations
      if (steps.isEmpty) {
        steps.add(TroubleshootingStep(
          title: 'GPS is Working Well',
          description: 'Your GPS setup looks good for tracking runs.',
          action: 'If you experience issues, try restarting the app or moving to a more open area.',
          priority: TroubleshootingPriority.info,
        ));
      }
      
    } catch (error) {
      steps.add(TroubleshootingStep(
        title: 'Diagnostic Error',
        description: 'Unable to check GPS status.',
        action: 'Try restarting the app. If problems persist, contact support.',
        priority: TroubleshootingPriority.high,
      ));
    }
    
    return steps;
  }

  GpsSignalQuality _assessSignalQuality(double accuracy) {
    if (accuracy <= 5) return GpsSignalQuality.excellent;
    if (accuracy <= 10) return GpsSignalQuality.good;
    if (accuracy <= 20) return GpsSignalQuality.fair;
    return GpsSignalQuality.poor;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDifferences = values.map((value) => (value - mean) * (value - mean));
    return squaredDifferences.reduce((a, b) => a + b) / values.length;
  }

  List<String> _generateRecommendations(GpsTestResult result) {
    final recommendations = <String>[];
    
    if (result.averageAccuracy > 20) {
      recommendations.add('GPS accuracy is poor. Try moving to an open area with clear sky view.');
    }
    
    if (result.signalStability == 'Unstable') {
      recommendations.add('GPS signal is unstable. Avoid areas with tall buildings or dense tree cover.');
    }
    
    if (result.totalReadings < 10) {
      recommendations.add('Few GPS readings received. Check if location services are working properly.');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('GPS performance looks good for tracking runs.');
    }
    
    return recommendations;
  }

  Future<String> _checkBatteryOptimization() async {
    try {
      if (!Platform.isAndroid) return 'Unknown';
      final isLowPower = await PlatformSpecificService.isLowPowerModeEnabled();
      return isLowPower ? 'Optimized' : 'Not optimized';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _checkBackgroundAppRefresh() async {
    try {
      if (!Platform.isIOS) return 'Unknown';
      return await PlatformSpecificService.getBackgroundAppRefreshStatus();
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<String> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty ? 'Connected' : 'Disconnected';
    } catch (e) {
      return 'Disconnected';
    }
  }

  Future<Map<String, dynamic>?> _getSatelliteInfo() async {
    // This would require platform-specific implementation to get satellite count
    // For now, return null
    return null;
  }
}

/// GPS diagnostics information
class GpsDiagnostics {
  bool isLocationServiceEnabled = false;
  LocationPermission locationPermission = LocationPermission.denied;
  Map<String, dynamic> deviceInfo = {};
  Map<String, dynamic>? lastKnownPosition;
  GpsSignalQuality gpsSignalQuality = GpsSignalQuality.unknown;
  String? locationError;
  String? batteryOptimizationStatus;
  String? backgroundAppRefreshStatus;
  String networkConnectivity = 'Unknown';
  Map<String, dynamic>? satelliteInfo;
  DateTime? timestamp;
}

/// GPS test result
class GpsTestResult {
  DateTime? startTime;
  DateTime? endTime;
  int totalReadings = 0;
  double averageAccuracy = 0;
  double bestAccuracy = 0;
  double worstAccuracy = 0;
  String signalStability = 'Unknown';
  List<String> recommendations = [];
  String? error;
}

/// Troubleshooting step
class TroubleshootingStep {
  const TroubleshootingStep({
    required this.title,
    required this.description,
    required this.action,
    required this.priority,
  });

  final String title;
  final String description;
  final String action;
  final TroubleshootingPriority priority;
}

enum GpsSignalQuality { unknown, poor, fair, good, excellent }

enum TroubleshootingPriority { info, low, medium, high, critical }
