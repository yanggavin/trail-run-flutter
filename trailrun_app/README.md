# TrailRun Mobile App

A mobile app for trail runners to track runs, capture geo-tagged photos, and generate rich activity summaries with offline-first reliability, secure storage, and privacy by default.

## Features

- **GPS Tracking**: Start/stop, pause/resume, background tracking, auto-pause, accuracy control
- **Photo Capture**: Geo-tagged photos during activities with fast return to tracking
- **Activity Summary**: Stats, interactive maps, photo markers, splits, elevation charts
- **Offline-First**: Full functionality offline with automatic cloud sync
- **History Management**: Activity list with search, filters, and sorting
- **Privacy & Security**: Encrypted local storage, privacy-by-default sharing
- **Cross-Platform**: Consistent experience on iOS and Android

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

Run all tests:
```bash
flutter test
```

Run analysis:
```bash
flutter analyze
```

## Project Structure

```
lib/
├── data/           # Data layer - repositories, data sources
├── domain/         # Domain layer - entities, use cases
├── presentation/   # Presentation layer - UI, screens, providers
└── main.dart       # App entry point
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

## License

This project is licensed under the MIT License.
