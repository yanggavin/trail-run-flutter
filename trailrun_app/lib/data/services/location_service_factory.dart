import 'package:flutter/foundation.dart';

import '../../domain/repositories/location_repository.dart';
import 'enhanced_location_service.dart';
import 'location_service.dart';
import 'mock_location_service.dart';

/// Factory for creating location service instances
class LocationServiceFactory {
  /// Create a location service instance
  /// 
  /// In debug mode or when [useMock] is true, returns a mock implementation
  /// for testing and development. Otherwise returns the enhanced real implementation
  /// with background tracking capabilities.
  static LocationRepository create({
    bool? useMock,
    bool simulateMovement = true,
    double baseLatitude = 45.0,
    double baseLongitude = -122.0,
    double baseElevation = 100.0,
  }) {
    final shouldUseMock = useMock ?? kDebugMode;
    
    if (shouldUseMock) {
      return MockLocationService(
        simulateMovement: simulateMovement,
        baseLatitude: baseLatitude,
        baseLongitude: baseLongitude,
        baseElevation: baseElevation,
      );
    } else {
      // Use enhanced location service with background tracking capabilities
      return EnhancedLocationService();
    }
  }
}