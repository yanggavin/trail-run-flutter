# Background Location Tracking

This document explains how to use the background location tracking functionality in the TrailRun app.

## Overview

The background location tracking system allows the app to continue tracking GPS location even when the app is in the background or the screen is off. This is essential for trail running apps where users need continuous tracking throughout their run.

## Architecture

The background tracking system consists of several components:

1. **EnhancedLocationService** - Main service that coordinates foreground and background tracking
2. **BackgroundLocationManager** - Manages background-specific functionality
3. **Platform-specific implementations** - iOS and Android native code for background processing

## Key Features

- **Adaptive GPS Sampling** - Automatically adjusts GPS sampling rate (1-5 seconds) based on movement and battery level
- **Battery Optimization** - Reduces power consumption during background tracking
- **State Persistence** - Recovers tracking sessions after app crashes or restarts
- **Cross-platform Support** - Works on both iOS and Android with platform-specific optimizations
- **Lifecycle Management** - Handles app state transitions seamlessly

## Usage

### Basic Setup

```dart
import 'package:trailrun_app/data/services/enhanced_location_service.dart';
import 'package:trailrun_app/data/services/location_service_factory.dart';

// Create enhanced location service
final locationService = LocationServiceFactory.create() as EnhancedLocationService;
```

### Enable Background Tracking

```dart
// Enable background tracking for an activity
await locationService.enableBackgroundTracking(
  activityId: 'your-activity-id',
  accuracy: LocationAccuracy.balanced,
  minIntervalSeconds: 1,
  maxIntervalSeconds: 5,
);
```

### Start Location Tracking

```dart
// Request permissions first
final permission = await locationService.requestPermission();
if (permission == LocationPermissionStatus.denied) {
  // Handle permission denied
  return;
}

// Request background permission for background tracking
final backgroundPermission = await locationService.requestBackgroundPermission();
if (backgroundPermission != LocationPermissionStatus.always) {
  // Handle background permission denied
  return;
}

// Start tracking (both foreground and background)
await locationService.startLocationTracking(
  accuracy: LocationAccuracy.balanced,
  intervalSeconds: 2,
);
```

### Listen to Location Updates

```dart
// Listen to location updates from both foreground and background
locationService.locationStream.listen((trackPoint) {
  print('New location: ${trackPoint.coordinates.latitude}, ${trackPoint.coordinates.longitude}');
  // Save to database or process as needed
});

// Listen to tracking state changes
locationService.trackingStateStream.listen((state) {
  print('Tracking state: $state');
});
```

### Handle App Lifecycle

```dart
class MyWidget extends StatefulWidget with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        locationService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        locationService.onAppResumed();
        break;
      case AppLifecycleState.detached:
        locationService.onAppDetached();
        break;
    }
  }
}
```

### Monitor Background Tracking

```dart
// Get background tracking statistics
final stats = locationService.getBackgroundTrackingStats();
print('Battery level: ${stats['batteryLevel']}');
print('Current interval: ${stats['currentInterval']}');
print('Pending points: ${stats['pendingPoints']}');

// Check if background tracking is active
if (locationService.isBackgroundTrackingActive) {
  print('Background tracking is running');
}
```

### Stop and Cleanup

```dart
// Stop tracking
await locationService.stopLocationTracking();

// Disable background tracking
await locationService.disableBackgroundTracking();

// Dispose resources
locationService.dispose();
```

## Platform Configuration

### iOS Configuration

The iOS configuration is already set up in `ios/Runner/Info.plist`:

```xml
<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>background-fetch</string>
</array>

<!-- Location permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>TrailRun needs location access to track your running routes and record GPS data during activities.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>TrailRun needs background location access to continue tracking your run when the app is in the background.</string>
```

### Android Configuration

The Android configuration is set up in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Foreground service permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

<!-- Wake lock for background tracking -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Foreground service -->
<service
    android:name=".LocationTrackingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="location" />
```

## Battery Optimization

The system includes several battery optimization features:

### Adaptive Sampling

- **High Movement** (>3 m/s): 1-second intervals for maximum accuracy
- **Normal Movement** (1-3 m/s): 2-second intervals for balanced accuracy/battery
- **Low Movement** (<1 m/s): 3-5 second intervals to save battery
- **Low Battery** (<20%): Maximum intervals to preserve battery

### Power Management

- Monitors device battery level and low power mode
- Automatically adjusts GPS accuracy based on battery status
- Reduces background processing when battery is low
- Uses efficient location filtering to minimize CPU usage

## Error Handling

The system includes comprehensive error handling:

```dart
try {
  await locationService.startLocationTracking();
} catch (e) {
  if (e is LocationServiceException) {
    switch (e.type) {
      case LocationErrorType.permissionDenied:
        // Handle permission error
        break;
      case LocationErrorType.serviceDisabled:
        // Handle GPS disabled
        break;
      case LocationErrorType.timeout:
        // Handle timeout
        break;
    }
  }
}
```

## Testing

The system includes comprehensive tests:

- **Unit Tests** - Test individual components and logic
- **Integration Tests** - Test complete workflows
- **Platform Tests** - Test platform-specific functionality

Run tests with:

```bash
flutter test test/data/services/background_location_manager_test.dart
flutter test test/data/services/enhanced_location_service_test.dart
flutter test test/integration/background_tracking_integration_test.dart
```

## Performance Considerations

### Memory Management

- Streams are properly disposed to prevent memory leaks
- Track points are batched and persisted to prevent memory buildup
- Background processing uses minimal memory footprint

### CPU Usage

- Location filtering is optimized for minimal CPU usage
- Kalman filtering uses efficient algorithms
- Background tasks are scheduled efficiently

### Network Usage

- No network usage during tracking (offline-first)
- Sync operations are batched and optimized
- Exponential backoff for failed sync attempts

## Troubleshooting

### Common Issues

1. **Background tracking stops** - Check battery optimization settings
2. **Inaccurate locations** - Verify GPS accuracy settings
3. **High battery usage** - Check adaptive sampling configuration
4. **Permission errors** - Ensure all required permissions are granted

### Debug Information

```dart
// Get tracking statistics for debugging
final stats = await locationService.getTrackingStats();
print('Total points: ${stats.totalPoints}');
print('Filtered points: ${stats.filteredPoints}');
print('Average accuracy: ${stats.averageAccuracy}');
print('Battery usage: ${stats.batteryUsagePercent}%');
```

## Best Practices

1. **Always request permissions before starting tracking**
2. **Handle app lifecycle events properly**
3. **Monitor battery usage and adjust settings accordingly**
4. **Implement proper error handling and user feedback**
5. **Test thoroughly on different devices and OS versions**
6. **Respect user privacy and provide clear explanations for permissions**

## Example Implementation

See `lib/examples/background_tracking_example.dart` for a complete working example of how to implement background location tracking in your app.