import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/errors/app_errors.dart';
import 'platform_permission_service.dart';
import 'location_service.dart';
import 'camera_service.dart';

/// Service that provides graceful degradation when permissions are denied
/// or services are unavailable
class GracefulDegradationService {
  GracefulDegradationService({
    PlatformPermissionService? permissionService,
    required this.locationService,
    required this.cameraService,
  }) : permissionService = permissionService ?? PlatformPermissionService();

  final PlatformPermissionService permissionService;
  final LocationService locationService;
  final CameraService cameraService;

  /// Gets the current app capability status
  Future<AppCapabilities> getAppCapabilities() async {
    final capabilities = AppCapabilities();
    
    try {
      // Check location capabilities
      final locationPermission = await Geolocator.checkPermission();
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      capabilities.canTrackLocation = locationPermission == LocationPermission.always ||
                                    locationPermission == LocationPermission.whileInUse;
      capabilities.canTrackInBackground = locationPermission == LocationPermission.always;
      capabilities.locationServiceEnabled = isLocationServiceEnabled;
      
      // Check camera capabilities
      capabilities.canTakePhotos = await PlatformPermissionService.hasCameraPermission();
      
      // Check storage capabilities
      capabilities.canSaveData = await PlatformPermissionService.hasStoragePermission();
      
      // Determine overall functionality level
      capabilities.functionalityLevel = _determineFunctionalityLevel(capabilities);
      
      // Generate user-friendly explanations
      capabilities.limitations = _generateLimitations(capabilities);
      capabilities.recommendations = _generateRecommendations(capabilities);
      
    } catch (error) {
      debugPrint('Error checking app capabilities: $error');
      capabilities.functionalityLevel = FunctionalityLevel.limited;
      capabilities.limitations = ['Unable to check app permissions and capabilities.'];
      capabilities.recommendations = ['Please restart the app and try again.'];
    }
    
    return capabilities;
  }

  /// Provides alternative functionality when core features are unavailable
  Future<AlternativeFunctionality> getAlternativeFunctionality() async {
    final capabilities = await getAppCapabilities();
    final alternatives = AlternativeFunctionality();
    
    // Location tracking alternatives
    if (!capabilities.canTrackLocation) {
      alternatives.locationAlternatives = [
        AlternativeFeature(
          title: 'Manual Distance Entry',
          description: 'Manually enter your run distance and time',
          isAvailable: true,
          action: () async {
            // Navigate to manual entry screen
          },
        ),
        AlternativeFeature(
          title: 'Import from Other Apps',
          description: 'Import GPS data from other fitness apps',
          isAvailable: capabilities.canSaveData,
          action: () async {
            // Navigate to import screen
          },
        ),
      ];
    }
    
    // Photo alternatives
    if (!capabilities.canTakePhotos) {
      alternatives.photoAlternatives = [
        AlternativeFeature(
          title: 'Import Photos',
          description: 'Add photos from your gallery after your run',
          isAvailable: capabilities.canSaveData,
          action: () async {
            // Navigate to photo import screen
          },
        ),
        AlternativeFeature(
          title: 'Text Notes',
          description: 'Add text descriptions instead of photos',
          isAvailable: true,
          action: () async {
            // Navigate to notes screen
          },
        ),
      ];
    }
    
    // Background tracking alternatives
    if (!capabilities.canTrackInBackground) {
      alternatives.backgroundAlternatives = [
        AlternativeFeature(
          title: 'Keep Screen On',
          description: 'Keep the app open during your run',
          isAvailable: true,
          action: () async {
            // Enable screen wake lock
          },
        ),
        AlternativeFeature(
          title: 'Audio Cues',
          description: 'Get audio updates to know the app is still tracking',
          isAvailable: true,
          action: () async {
            // Enable audio cues
          },
        ),
      ];
    }
    
    return alternatives;
  }

  /// Handles permission denial gracefully with user guidance
  Future<PermissionDenialResponse> handlePermissionDenial(
    PermissionType permissionType,
    bool isPermanentlyDenied,
  ) async {
    switch (permissionType) {
      case PermissionType.location:
        return _handleLocationPermissionDenial(isPermanentlyDenied);
      case PermissionType.camera:
        return _handleCameraPermissionDenial(isPermanentlyDenied);
      case PermissionType.storage:
        return _handleStoragePermissionDenial(isPermanentlyDenied);
    }
  }

  /// Provides a degraded tracking experience without full permissions
  Future<DegradedTrackingOptions> getDegradedTrackingOptions() async {
    final capabilities = await getAppCapabilities();
    final options = DegradedTrackingOptions();
    
    if (!capabilities.canTrackLocation) {
      options.manualTracking = DegradedFeature(
        title: 'Manual Tracking',
        description: 'Use timer-based tracking without GPS',
        isRecommended: true,
        limitations: ['No route map', 'No automatic distance calculation'],
        benefits: ['Still tracks time and pace', 'Works anywhere'],
      );
    }
    
    if (!capabilities.canTrackInBackground) {
      options.foregroundOnlyTracking = DegradedFeature(
        title: 'Foreground Tracking',
        description: 'Track runs while keeping the app open',
        isRecommended: capabilities.canTrackLocation,
        limitations: ['Must keep app open', 'Higher battery usage'],
        benefits: ['Full GPS tracking', 'Real-time stats'],
      );
    }
    
    if (!capabilities.canTakePhotos) {
      options.photolessTracking = DegradedFeature(
        title: 'Run Tracking Only',
        description: 'Focus on GPS tracking without photos',
        isRecommended: capabilities.canTrackLocation,
        limitations: ['No in-run photos', 'Limited sharing options'],
        benefits: ['Full tracking features', 'Better battery life'],
      );
    }
    
    return options;
  }

  FunctionalityLevel _determineFunctionalityLevel(AppCapabilities capabilities) {
    if (capabilities.canTrackLocation && 
        capabilities.canTrackInBackground && 
        capabilities.canTakePhotos && 
        capabilities.canSaveData) {
      return FunctionalityLevel.full;
    }
    
    if (capabilities.canTrackLocation && capabilities.canSaveData) {
      return FunctionalityLevel.core;
    }
    
    if (capabilities.canSaveData) {
      return FunctionalityLevel.limited;
    }
    
    return FunctionalityLevel.minimal;
  }

  List<String> _generateLimitations(AppCapabilities capabilities) {
    final limitations = <String>[];
    
    if (!capabilities.canTrackLocation) {
      limitations.add('GPS tracking is not available');
    }
    
    if (!capabilities.canTrackInBackground) {
      limitations.add('Background tracking is not available');
    }
    
    if (!capabilities.canTakePhotos) {
      limitations.add('Camera features are not available');
    }
    
    if (!capabilities.canSaveData) {
      limitations.add('Data saving is limited');
    }
    
    return limitations;
  }

  List<String> _generateRecommendations(AppCapabilities capabilities) {
    final recommendations = <String>[];
    
    if (!capabilities.locationServiceEnabled) {
      recommendations.add('Enable location services in device settings');
    }
    
    if (!capabilities.canTrackLocation) {
      recommendations.add('Grant location permission for GPS tracking');
    }
    
    if (!capabilities.canTrackInBackground) {
      recommendations.add('Allow "Always" location access for background tracking');
    }
    
    if (!capabilities.canTakePhotos) {
      recommendations.add('Grant camera permission to take photos during runs');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('All features are available');
    }
    
    return recommendations;
  }

  PermissionDenialResponse _handleLocationPermissionDenial(bool isPermanentlyDenied) {
    return PermissionDenialResponse(
      title: 'Location Permission Required',
      message: isPermanentlyDenied
          ? 'Location permission was permanently denied. Please enable it in app settings to track your runs.'
          : 'TrailRun needs location permission to track your runs with GPS.',
      alternatives: [
        'Use manual distance entry',
        'Import GPS data from other apps',
        'Track time and notes without GPS',
      ],
      canRetry: !isPermanentlyDenied,
      settingsRequired: isPermanentlyDenied,
    );
  }

  PermissionDenialResponse _handleCameraPermissionDenial(bool isPermanentlyDenied) {
    return PermissionDenialResponse(
      title: 'Camera Permission Required',
      message: isPermanentlyDenied
          ? 'Camera permission was permanently denied. Please enable it in app settings to take photos during runs.'
          : 'TrailRun needs camera permission to take photos during your runs.',
      alternatives: [
        'Add photos from gallery after your run',
        'Use text notes instead of photos',
        'Focus on GPS tracking only',
      ],
      canRetry: !isPermanentlyDenied,
      settingsRequired: isPermanentlyDenied,
    );
  }

  PermissionDenialResponse _handleStoragePermissionDenial(bool isPermanentlyDenied) {
    return PermissionDenialResponse(
      title: 'Storage Permission Required',
      message: isPermanentlyDenied
          ? 'Storage permission was permanently denied. Please enable it in app settings to save your run data.'
          : 'TrailRun needs storage permission to save your run data and photos.',
      alternatives: [
        'Use cloud sync only (if available)',
        'Limited local data storage',
      ],
      canRetry: !isPermanentlyDenied,
      settingsRequired: isPermanentlyDenied,
    );
  }
}

/// App capabilities status
class AppCapabilities {
  bool canTrackLocation = false;
  bool canTrackInBackground = false;
  bool canTakePhotos = false;
  bool canSaveData = false;
  bool locationServiceEnabled = false;
  FunctionalityLevel functionalityLevel = FunctionalityLevel.minimal;
  List<String> limitations = [];
  List<String> recommendations = [];
}

/// Alternative functionality options
class AlternativeFunctionality {
  List<AlternativeFeature> locationAlternatives = [];
  List<AlternativeFeature> photoAlternatives = [];
  List<AlternativeFeature> backgroundAlternatives = [];
}

/// Alternative feature option
class AlternativeFeature {
  const AlternativeFeature({
    required this.title,
    required this.description,
    required this.isAvailable,
    required this.action,
  });

  final String title;
  final String description;
  final bool isAvailable;
  final Future<void> Function() action;
}

/// Degraded tracking options
class DegradedTrackingOptions {
  DegradedFeature? manualTracking;
  DegradedFeature? foregroundOnlyTracking;
  DegradedFeature? photolessTracking;
}

/// Degraded feature description
class DegradedFeature {
  const DegradedFeature({
    required this.title,
    required this.description,
    required this.isRecommended,
    required this.limitations,
    required this.benefits,
  });

  final String title;
  final String description;
  final bool isRecommended;
  final List<String> limitations;
  final List<String> benefits;
}

/// Permission denial response
class PermissionDenialResponse {
  const PermissionDenialResponse({
    required this.title,
    required this.message,
    required this.alternatives,
    required this.canRetry,
    required this.settingsRequired,
  });

  final String title;
  final String message;
  final List<String> alternatives;
  final bool canRetry;
  final bool settingsRequired;
}

enum FunctionalityLevel { minimal, limited, core, full }
enum PermissionType { location, camera, storage }
