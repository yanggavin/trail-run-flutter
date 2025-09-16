import 'package:flutter/material.dart';
import '../screens/activity_summary_screen.dart';
import '../screens/activity_history_screen.dart';
import '../navigation/app_router.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/track_point.dart';
import '../../domain/models/photo.dart';
import '../../domain/models/split.dart' as domain;
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';
import '../../domain/value_objects/measurement_units.dart';
import '../../domain/enums/privacy_level.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/enums/location_source.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TrailRun'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.directions_run,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to TrailRun',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your trail runs with GPS and photos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showDemoActivity(context),
              child: const Text('View Demo Activity Summary'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _navigateToHistory(context),
              child: const Text('View Activity History'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppNavigator.toTracking(context);
        },
        tooltip: 'Start Tracking',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  void _showDemoActivity(BuildContext context) {
    final demoActivity = _createDemoActivity();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivitySummaryScreen(activity: demoActivity),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ActivityHistoryScreen(),
      ),
    );
  }

  Activity _createDemoActivity() {
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 1, minutes: 30));
    
    // Create demo track points (simulating a trail run)
    final trackPoints = <TrackPoint>[];
    const baseLatitude = 37.7749;
    const baseLongitude = -122.4194;
    const baseElevation = 100.0;
    
    for (int i = 0; i < 100; i++) {
      final timestamp = startTime.add(Duration(seconds: i * 54)); // ~90 minutes total
      final latOffset = (i * 0.0001) + (i % 10) * 0.00005; // Simulate movement
      final lngOffset = (i * 0.00008) + (i % 8) * 0.00003;
      final elevationOffset = (i % 20) * 2.0 - 10.0; // Simulate elevation changes
      
      trackPoints.add(TrackPoint(
        id: 'tp_$i',
        activityId: 'demo_activity',
        timestamp: Timestamp(timestamp),
        coordinates: Coordinates(
          latitude: baseLatitude + latOffset,
          longitude: baseLongitude + lngOffset,
          elevation: baseElevation + elevationOffset + (i * 0.5), // Gradual climb
        ),
        accuracy: 5.0,
        source: LocationSource.gps,
        sequence: i,
      ));
    }
    
    // Create demo photos
    final photos = <Photo>[
      Photo(
        id: 'photo_1',
        activityId: 'demo_activity',
        timestamp: Timestamp(startTime.add(const Duration(minutes: 20))),
        coordinates: Coordinates(
          latitude: baseLatitude + 0.002,
          longitude: baseLongitude + 0.0016,
          elevation: baseElevation + 10,
        ),
        filePath: 'assets/images/.gitkeep', // Placeholder
        hasExifData: true,
        curationScore: 0.8,
        caption: 'Beautiful trail view!',
      ),
      Photo(
        id: 'photo_2',
        activityId: 'demo_activity',
        timestamp: Timestamp(startTime.add(const Duration(minutes: 45))),
        coordinates: Coordinates(
          latitude: baseLatitude + 0.005,
          longitude: baseLongitude + 0.004,
          elevation: baseElevation + 25,
        ),
        filePath: 'assets/images/.gitkeep', // Placeholder
        hasExifData: true,
        curationScore: 0.9,
        caption: 'Summit reached!',
      ),
    ];
    
    // Create demo splits
    final splits = <domain.Split>[
      domain.Split(
        id: 'split_1',
        activityId: 'demo_activity',
        splitNumber: 1,
        startTime: Timestamp(startTime),
        endTime: Timestamp(startTime.add(const Duration(minutes: 18))),
        distance: Distance.kilometers(1.0),
        pace: Pace.secondsPerKilometer(18 * 60), // 18:00/km
        elevationGain: Elevation.meters(15),
        elevationLoss: Elevation.meters(5),
      ),
      domain.Split(
        id: 'split_2',
        activityId: 'demo_activity',
        splitNumber: 2,
        startTime: Timestamp(startTime.add(const Duration(minutes: 18))),
        endTime: Timestamp(startTime.add(const Duration(minutes: 35))),
        distance: Distance.kilometers(1.0),
        pace: Pace.secondsPerKilometer(17 * 60), // 17:00/km
        elevationGain: Elevation.meters(20),
        elevationLoss: Elevation.meters(8),
      ),
      domain.Split(
        id: 'split_3',
        activityId: 'demo_activity',
        splitNumber: 3,
        startTime: Timestamp(startTime.add(const Duration(minutes: 35))),
        endTime: Timestamp(startTime.add(const Duration(minutes: 54))),
        distance: Distance.kilometers(1.0),
        pace: Pace.secondsPerKilometer(19 * 60), // 19:00/km
        elevationGain: Elevation.meters(25),
        elevationLoss: Elevation.meters(10),
      ),
    ];
    
    return Activity(
      id: 'demo_activity',
      startTime: Timestamp(startTime),
      endTime: Timestamp(startTime.add(const Duration(hours: 1, minutes: 30))),
      title: 'Morning Trail Run',
      notes: 'Great run through the hills! Weather was perfect and the views were amazing. Felt strong throughout the entire run.',
      distance: Distance.kilometers(5.2),
      elevationGain: Elevation.meters(180),
      elevationLoss: Elevation.meters(95),
      averagePace: Pace.secondsPerKilometer(17 * 60 + 30), // 17:30/km
      privacy: PrivacyLevel.friends,
      coverPhotoId: 'photo_2',
      syncState: SyncState.synced,
      trackPoints: trackPoints,
      photos: photos,
      splits: splits,
    );
  }
}