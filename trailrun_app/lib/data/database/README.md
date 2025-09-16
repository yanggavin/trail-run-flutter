# TrailRun Database Implementation

This directory contains the complete database implementation for the TrailRun mobile app using Drift (SQLite) with encryption support.

## Architecture

The database follows a layered architecture with:
- **Tables**: Define the database schema with constraints and indexes
- **DAOs**: Data Access Objects providing CRUD operations and business logic
- **Entities**: Generated Drift entities for type-safe database operations
- **Providers**: Riverpod providers for dependency injection

## Database Schema

### Core Tables

1. **activities** - Main activity records
   - Stores activity metadata (title, distance, duration, elevation, etc.)
   - Supports privacy levels and sync states
   - Includes timestamps for creation and updates

2. **track_points** - GPS tracking data
   - Individual GPS coordinates with accuracy and source information
   - Sequential ordering within activities
   - Supports different location sources (GPS, network, fused, etc.)

3. **photos** - Photo metadata and location data
   - Links photos to activities with timestamps
   - Stores GPS coordinates and EXIF data flags
   - Includes curation scores for automatic cover photo selection

4. **splits** - Per-kilometer performance data
   - Detailed split analysis with pace and elevation data
   - Supports performance comparisons and analytics

5. **sync_queue** - Offline sync management
   - Queues operations for server synchronization
   - Supports retry logic with exponential backoff
   - Priority-based operation ordering

## Features

### Security
- **AES-256 Encryption**: All data is encrypted at rest using SQLite encryption
- **TLS 1.2+ Communication**: Secure data transmission (when implemented)
- **Privacy by Default**: Activities default to private visibility

### Performance
- **Optimized Indexes**: Strategic indexes for common query patterns
- **Batch Operations**: Efficient bulk inserts for track points and photos
- **Connection Pooling**: Proper database connection management
- **WAL Mode**: Write-Ahead Logging for better concurrency

### Offline Support
- **Local-First**: All operations work without network connectivity
- **Sync Queue**: Automatic queuing of changes for later synchronization
- **Conflict Resolution**: Server-wins strategy with local change preservation
- **Data Integrity**: Foreign key constraints and validation rules

## Usage

### Basic Setup

```dart
// Get database instance
final database = ref.watch(databaseProvider);

// Access DAOs
final activityDao = ref.watch(activityDaoProvider);
final trackPointDao = ref.watch(trackPointDaoProvider);
final photoDao = ref.watch(photoDaoProvider);
```

### Creating Activities

```dart
final activity = Activity(
  id: 'activity-123',
  startTime: Timestamp.now(),
  title: 'Morning Run',
  distance: Distance.kilometers(5.0),
  elevationGain: Elevation.meters(100),
);

await activityDao.createActivity(activityDao.toEntity(activity));
```

### Batch Operations

```dart
final trackPoints = generateTrackPoints(); // List<TrackPoint>
final entities = trackPoints.map(trackPointDao.toEntity).toList();
await trackPointDao.createTrackPointsBatch(entities);
```

### Reactive Queries

```dart
// Watch for activity changes
Stream<Activity?> watchActivity(String id) {
  return activityDao.watchActivityById(id)
    .map((entity) => entity != null ? activityDao.fromEntity(entity) : null);
}
```

## Testing

Comprehensive test coverage includes:
- **Unit Tests**: Individual DAO operations and data integrity
- **Integration Tests**: Cross-table relationships and complex workflows
- **Performance Tests**: Batch operations and large dataset handling

Run tests with:
```bash
flutter test test/data/database/
```

## Migration Strategy

The database supports schema versioning and migrations:
- Version 1: Initial schema with all core tables
- Future versions: Incremental schema changes with data preservation

## File Structure

```
lib/data/database/
├── database.dart              # Main database class
├── database_provider.dart     # Riverpod providers
├── tables/                    # Table definitions
│   ├── activities_table.dart
│   ├── track_points_table.dart
│   ├── photos_table.dart
│   ├── splits_table.dart
│   └── sync_queue_table.dart
└── daos/                      # Data Access Objects
    ├── activity_dao.dart
    ├── track_point_dao.dart
    ├── photo_dao.dart
    ├── split_dao.dart
    └── sync_queue_dao.dart
```

## Requirements Satisfied

This implementation satisfies the following requirements:
- **5.2**: Offline-first data storage with encrypted local database
- **8.1**: AES-256 encryption for local data storage
- **8.4**: GDPR-compliant data deletion and export capabilities

The database provides a solid foundation for the TrailRun app's data persistence needs with security, performance, and offline capabilities built-in.