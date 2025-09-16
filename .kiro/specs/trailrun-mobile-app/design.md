# Design Document

## Overview

TrailRun is a Flutter-based mobile application designed for trail runners to track GPS activities, capture geotagged photos, and generate comprehensive activity summaries. The architecture prioritizes offline-first operation, battery efficiency, and cross-platform consistency while maintaining robust GPS tracking capabilities.

The application follows a layered architecture with clear separation of concerns, utilizing reactive state management and encrypted local storage with cloud synchronization capabilities.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  Flutter UI (Material 3) + Riverpod State Management       │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│     Use Cases + Domain Models + Repository Interfaces      │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  Local Repository (Drift) + Remote Repository (Dio/HTTP)   │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                 Platform Services                           │
│   Location Service + Camera + File System + Permissions    │
└─────────────────────────────────────────────────────────────┘
```

### Core Architectural Principles

1. **Offline-First**: All functionality works without network connectivity
2. **Reactive Architecture**: State changes propagate through the app using streams
3. **Platform Abstraction**: Common interface with platform-specific implementations
4. **Battery Optimization**: Efficient background processing and adaptive sampling
5. **Security by Design**: Encryption at rest and in transit

## Components and Interfaces

### 1. Location Tracking System

**LocationService Interface**
```dart
abstract class LocationService {
  Stream<LocationPoint> get locationStream;
  Future<void> startTracking({LocationAccuracy accuracy});
  Future<void> stopTracking();
  Future<void> pauseTracking();
  Future<void> resumeTracking();
  LocationPermissionStatus get permissionStatus;
}
```

**Key Components:**
- **LocationManager**: Orchestrates location tracking lifecycle
- **LocationFilter**: Applies Kalman filtering and outlier detection
- **AdaptiveSampler**: Adjusts sampling rate based on movement and battery
- **BackgroundLocationHandler**: Manages iOS background modes and Android foreground service

**Location Processing Pipeline:**
```
Raw GPS → Accuracy Gate → Kalman Filter → Outlier Detection → Adaptive Sampler → Batch Writer
```

### 2. Activity Management System

**ActivityRepository Interface**
```dart
abstract class ActivityRepository {
  Future<Activity> createActivity();
  Future<void> updateActivity(Activity activity);
  Future<Activity?> getActiveActivity();
  Future<List<Activity>> getActivities({int page, ActivityFilter? filter});
  Future<void> deleteActivity(String activityId);
  Stream<Activity> watchActivity(String activityId);
}
```

**Core Models:**
- **Activity**: Main activity entity with metadata and stats
- **TrackPoint**: Individual GPS point with timestamp and accuracy
- **ActivityStats**: Calculated metrics (distance, pace, elevation)
- **Split**: Per-kilometer performance data

### 3. Photo Management System

**PhotoService Interface**
```dart
abstract class PhotoService {
  Future<Photo> capturePhoto(String activityId);
  Future<void> processPhoto(Photo photo);
  Future<List<Photo>> getPhotosForActivity(String activityId);
  Future<void> stripExifData(Photo photo);
}
```

**Components:**
- **CameraController**: Manages camera interface and capture
- **ExifProcessor**: Handles EXIF data reading/writing/stripping
- **PhotoStorage**: Manages photo file storage and thumbnails
- **GeotaggingService**: Associates photos with GPS coordinates

### 4. Sync and Storage System

**SyncService Interface**
```dart
abstract class SyncService {
  Future<void> syncAll();
  Future<void> syncActivity(String activityId);
  Stream<SyncStatus> get syncStatusStream;
  Future<void> resolveConflict(SyncConflict conflict);
}
```

**Storage Architecture:**
- **Drift Database**: Encrypted SQLite with type-safe queries
- **SyncQueue**: Manages pending sync operations with retry logic
- **ConflictResolver**: Implements server-wins strategy with local preservation
- **BackupService**: Handles data export and restore

### 5. Map and Visualization System

**MapService Interface**
```dart
abstract class MapService {
  Widget buildMapWidget({required List<TrackPoint> route, List<Photo> photos});
  Future<void> renderRoutePolyline(List<TrackPoint> points);
  Future<void> addPhotoMarkers(List<Photo> photos);
  Future<Uint8List> generateMapSnapshot(Activity activity);
}
```

**Components:**
- **MapRenderer**: Handles route visualization and photo markers
- **ElevationChart**: Generates elevation profile charts
- **ShareCardGenerator**: Creates activity summary images

## Data Models

### Core Entities

**Activity Model**
```dart
class Activity {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final Duration duration;
  final double elevationGainMeters;
  final double averagePaceSecondsPerKm;
  final String title;
  final String? notes;
  final PrivacyLevel privacy;
  final String? coverPhotoId;
  final SyncState syncState;
  final List<TrackPoint> trackPoints;
  final List<Photo> photos;
  final List<Split> splits;
}
```

**TrackPoint Model**
```dart
class TrackPoint {
  final String id;
  final String activityId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? elevation;
  final double accuracy;
  final LocationSource source;
  final int sequence;
}
```

**Photo Model**
```dart
class Photo {
  final String id;
  final String activityId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String filePath;
  final String? thumbnailPath;
  final bool hasExifData;
  final double curationScore;
}
```

### Database Schema

**Activities Table**
```sql
CREATE TABLE activities (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  end_time INTEGER,
  distance_meters REAL NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  elevation_gain_meters REAL NOT NULL DEFAULT 0,
  average_pace_seconds_per_km REAL,
  title TEXT NOT NULL,
  notes TEXT,
  privacy_level INTEGER NOT NULL DEFAULT 0,
  cover_photo_id TEXT,
  sync_state INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**TrackPoints Table**
```sql
CREATE TABLE track_points (
  id TEXT PRIMARY KEY,
  activity_id TEXT NOT NULL REFERENCES activities(id),
  timestamp INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  elevation REAL,
  accuracy REAL NOT NULL,
  source INTEGER NOT NULL,
  sequence INTEGER NOT NULL
);
```

## Error Handling

### Error Categories and Strategies

**1. Location Errors**
- **GPS Signal Loss**: Queue points for interpolation, show user feedback
- **Permission Denied**: Graceful degradation with clear user guidance
- **Background Restrictions**: Platform-specific handling with user education

**2. Storage Errors**
- **Database Corruption**: Automatic backup restoration
- **Disk Space**: Cleanup old data with user consent
- **Encryption Failures**: Secure key regeneration flow

**3. Network Errors**
- **Sync Failures**: Exponential backoff with retry limits
- **Authentication Errors**: Token refresh with re-authentication flow
- **Conflict Resolution**: Server-wins with local change preservation

**4. Camera/Photo Errors**
- **Camera Access Denied**: Alternative photo import option
- **Storage Failures**: Retry with different storage location
- **Processing Errors**: Fallback to basic photo storage

### Error Recovery Patterns

```dart
class ErrorHandler {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    // Exponential backoff retry logic
  }
  
  static void handleLocationError(LocationError error) {
    // Location-specific error handling
  }
  
  static void handleSyncError(SyncError error) {
    // Sync-specific error handling with queue management
  }
}
```

## Testing Strategy

### Unit Testing
- **Domain Logic**: Test all use cases and business rules
- **Data Processing**: Test location filtering, stats calculation
- **Sync Logic**: Test conflict resolution and queue management
- **Utilities**: Test helper functions and data transformations

### Integration Testing
- **Database Operations**: Test Drift repository implementations
- **Location Services**: Test GPS tracking with mock location data
- **Photo Processing**: Test camera integration and EXIF handling
- **Sync Operations**: Test end-to-end sync with mock server

### Widget Testing
- **UI Components**: Test individual widgets and their interactions
- **State Management**: Test Riverpod providers and state changes
- **Navigation**: Test route transitions and deep linking
- **Accessibility**: Test screen reader support and keyboard navigation

### Platform Testing
- **Background Location**: Test iOS background modes and Android foreground service
- **Permissions**: Test permission flows on both platforms
- **Battery Usage**: Test power consumption during tracking
- **Performance**: Test with large datasets (30k+ points, 50+ photos)

### End-to-End Testing
- **Complete Tracking Flow**: Start → Track → Photos → Stop → Summary
- **Offline Scenarios**: Test full offline functionality
- **Sync Scenarios**: Test various sync conflict situations
- **Recovery Scenarios**: Test crash recovery and state restoration

## Performance Considerations

### Battery Optimization
- **Adaptive GPS Sampling**: 1-5 second intervals based on movement
- **Background Processing**: Minimal CPU usage during background tracking
- **Efficient Data Structures**: Batch operations and lazy loading
- **Platform Optimization**: iOS background modes, Android foreground service

### Memory Management
- **Stream Management**: Proper disposal of location and camera streams
- **Image Processing**: Process photos in isolates to avoid UI blocking
- **Database Connections**: Connection pooling and proper cleanup
- **Large Dataset Handling**: Pagination and virtual scrolling

### UI Performance
- **Map Rendering**: Efficient polyline rendering for large routes
- **List Performance**: Virtual scrolling for activity history
- **Image Loading**: Progressive loading with thumbnails
- **State Updates**: Debounced updates to prevent excessive rebuilds

### Storage Optimization
- **Database Indexing**: Proper indexes for common queries
- **Photo Compression**: Automatic compression with quality settings
- **Data Cleanup**: Automatic cleanup of old temporary files
- **Sync Efficiency**: Delta sync to minimize data transfer