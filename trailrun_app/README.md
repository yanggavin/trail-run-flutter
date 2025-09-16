# TrailRun Mobile App

A mobile app for trail runners to track runs, capture geo-tagged photos, and generate rich activity summaries with offline-first reliability, secure storage, and privacy by default.

## Features

- **GPS Tracking**: Start/stop, pause/resume, background tracking, auto-pause, accuracy control
- **Photo Capture**: Geo-tagged photos during activities with fast return to tracking (< 400ms)
- **Activity Summary**: Stats, interactive maps, photo markers, splits, elevation charts
- **Offline-First**: Full functionality offline with automatic cloud sync and conflict resolution
- **History Management**: Activity list with search, filters, and sorting
- **Privacy & Security**: Encrypted local storage, privacy-by-default sharing, data export/deletion
- **Cross-Platform**: Consistent experience on iOS and Android with platform-specific optimizations
- **Performance Optimized**: Battery usage < 6% per hour, responsive UI with large datasets
- **Error Recovery**: Crash recovery, graceful degradation, comprehensive error handling

## Architecture

The app follows a clean architecture pattern with three main layers:

- **Presentation Layer**: Flutter UI with Riverpod state management
- **Domain Layer**: Business logic, entities, and repository interfaces
- **Data Layer**: Local database (Drift) and remote API integration

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- iOS development: Xcode and iOS Simulator
- Android development: Android Studio and Android SDK

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generation:
   ```bash
   flutter packages pub run build_runner build
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Testing

#### Unit and Widget Tests
Run all unit and widget tests:
```bash
flutter test
```

#### Integration Tests
Run comprehensive end-to-end integration tests:
```bash
# Run all integration test suites
dart test_runner.dart

# Run specific integration test suite
flutter test test/integration/complete_tracking_workflow_test.dart
flutter test test/integration/offline_functionality_test.dart
flutter test test/integration/sync_behavior_test.dart
flutter test test/integration/battery_performance_validation_test.dart
```

#### Device Integration Tests
Run tests on actual devices/emulators:
```bash
flutter test integration_test/app_test.dart
```

#### Code Analysis
Run static analysis:
```bash
flutter analyze
```

## Project Structure

```
lib/
├── data/
│   ├── database/       # Local database (Drift) with DAOs and entities
│   ├── repositories/   # Repository implementations
│   └── services/       # Data services (location, camera, sync, etc.)
├── domain/
│   ├── models/         # Domain entities (Activity, Photo, TrackPoint)
│   ├── repositories/   # Repository interfaces
│   ├── value_objects/  # Value objects (Coordinates, Timestamp)
│   └── errors/         # Custom error types
├── presentation/
│   ├── screens/        # UI screens (Home, Tracking, Summary, etc.)
│   ├── widgets/        # Reusable UI components
│   ├── providers/      # Riverpod state providers
│   └── navigation/     # App routing and navigation
├── examples/           # Usage examples and documentation
└── main.dart           # App entry point

test/
├── data/               # Data layer tests
├── domain/             # Domain layer tests
├── presentation/       # Presentation layer tests
└── integration/        # End-to-end integration tests

integration_test/       # Device integration tests
```

## Dependencies

### Core
- **flutter_riverpod**: State management
- **drift**: Local database with encryption
- **geolocator**: GPS location services
- **camera**: Photo capture functionality

### UI & Visualization
- **flutter_map**: Interactive maps
- **fl_chart**: Charts and graphs
- **share_plus**: Native sharing

### Networking & Storage
- **dio**: HTTP client
- **path_provider**: File system access
- **permission_handler**: Runtime permissions

## Performance & Quality Assurance

### Performance Targets
- **Battery Usage**: < 6% per hour during active tracking
- **App Startup**: < 3 seconds cold start
- **Photo Capture**: < 400ms return to tracking (average), < 700ms P95
- **UI Responsiveness**: Smooth performance with 30k+ GPS points
- **Memory Management**: Efficient handling during photo operations

### Test Coverage
- **Unit Tests**: Core business logic and services
- **Widget Tests**: UI components and screens
- **Integration Tests**: Complete user workflows
- **End-to-End Tests**: Full app functionality validation
- **Device Tests**: Real hardware interaction testing

### Quality Features
- **Offline-First**: Complete functionality without network
- **Sync Reliability**: Conflict resolution and retry logic
- **Error Recovery**: Crash recovery and graceful degradation
- **Privacy by Default**: Encrypted storage and privacy controls
- **Cross-Platform**: Consistent iOS and Android experience

## Development Status

✅ **Core Features Complete**
- GPS tracking with background support
- Photo capture and management
- Activity summaries with maps and charts
- Offline-first data management
- Activity history and search

✅ **Advanced Features Complete**
- Sync and conflict resolution
- Privacy and data management
- Share and export functionality
- Performance optimization
- Error handling and recovery

✅ **Testing Complete**
- Comprehensive test suite
- End-to-end integration tests
- Performance validation
- Cross-platform testing

🚀 **Ready for Production Deployment**

## License

This project is licensed under the MIT License.
