import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/enhanced_location_service.dart';
import '../data/services/location_service_factory.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/models/track_point.dart';

/// Example demonstrating background location tracking usage
class BackgroundTrackingExample extends ConsumerStatefulWidget {
  const BackgroundTrackingExample({super.key});

  @override
  ConsumerState<BackgroundTrackingExample> createState() => _BackgroundTrackingExampleState();
}

class _BackgroundTrackingExampleState extends ConsumerState<BackgroundTrackingExample> 
    with WidgetsBindingObserver {
  late LocationRepository _locationService;
  StreamSubscription<TrackPoint>? _locationSubscription;
  StreamSubscription<LocationTrackingState>? _stateSubscription;
  
  final List<TrackPoint> _trackPoints = [];
  LocationTrackingState _currentState = LocationTrackingState.stopped;
  Map<String, dynamic> _backgroundStats = {};
  
  String? _currentActivityId;
  bool _isBackgroundTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLocationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _stateSubscription?.cancel();
    
    if (_locationService is EnhancedLocationService) {
      (_locationService as EnhancedLocationService).dispose();
    }
    
    super.dispose();
  }

  void _initializeLocationService() {
    _locationService = LocationServiceFactory.create(useMock: false);
    
    // Listen to location updates
    _locationSubscription = _locationService.locationStream.listen(
      (trackPoint) {
        setState(() {
          _trackPoints.add(trackPoint);
        });
      },
    );
    
    // Listen to state changes
    _stateSubscription = _locationService.trackingStateStream.listen(
      (state) {
        setState(() {
          _currentState = state;
        });
      },
    );
  }

  Future<void> _enableBackgroundTracking() async {
    if (_locationService is EnhancedLocationService) {
      final enhancedService = _locationService as EnhancedLocationService;
      
      _currentActivityId = 'example-activity-${DateTime.now().millisecondsSinceEpoch}';
      
      await enhancedService.enableBackgroundTracking(
        activityId: _currentActivityId!,
        accuracy: LocationAccuracy.balanced,
        minIntervalSeconds: 1,
        maxIntervalSeconds: 5,
      );
      
      setState(() {
        _isBackgroundTrackingEnabled = true;
      });
      
      _updateBackgroundStats();
    }
  }

  Future<void> _disableBackgroundTracking() async {
    if (_locationService is EnhancedLocationService) {
      final enhancedService = _locationService as EnhancedLocationService;
      
      await enhancedService.disableBackgroundTracking();
      
      setState(() {
        _isBackgroundTrackingEnabled = false;
        _currentActivityId = null;
        _backgroundStats = {};
      });
    }
  }

  Future<void> _startTracking() async {
    try {
      // Request permissions first
      final permissionStatus = await _locationService.requestPermission();
      if (permissionStatus == LocationPermissionStatus.denied ||
          permissionStatus == LocationPermissionStatus.deniedForever) {
        _showError('Location permission is required for tracking');
        return;
      }
      
      // Request background permission if background tracking is enabled
      if (_isBackgroundTrackingEnabled) {
        final backgroundPermission = await _locationService.requestBackgroundPermission();
        if (backgroundPermission != LocationPermissionStatus.always) {
          _showError('Background location permission is required for background tracking');
          return;
        }
      }
      
      await _locationService.startLocationTracking(
        accuracy: LocationAccuracy.balanced,
        intervalSeconds: 2,
      );
      
      _updateBackgroundStats();
    } catch (e) {
      _showError('Failed to start tracking: $e');
    }
  }

  Future<void> _stopTracking() async {
    await _locationService.stopLocationTracking();
    setState(() {
      _trackPoints.clear();
    });
  }

  Future<void> _pauseTracking() async {
    await _locationService.pauseLocationTracking();
  }

  Future<void> _resumeTracking() async {
    await _locationService.resumeLocationTracking();
  }

  void _updateBackgroundStats() {
    if (_locationService is EnhancedLocationService) {
      final enhancedService = _locationService as EnhancedLocationService;
      setState(() {
        _backgroundStats = enhancedService.getBackgroundTrackingStats();
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_locationService is EnhancedLocationService) {
      final enhancedService = _locationService as EnhancedLocationService;
      
      switch (state) {
        case AppLifecycleState.paused:
          enhancedService.onAppPaused();
          break;
        case AppLifecycleState.resumed:
          enhancedService.onAppResumed();
          _updateBackgroundStats();
          break;
        case AppLifecycleState.detached:
          enhancedService.onAppDetached();
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Tracking Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Background tracking toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Background Tracking',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: _isBackgroundTrackingEnabled,
                          onChanged: (enabled) {
                            if (enabled) {
                              _enableBackgroundTracking();
                            } else {
                              _disableBackgroundTracking();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(_isBackgroundTrackingEnabled 
                            ? 'Enabled' 
                            : 'Disabled'),
                      ],
                    ),
                    if (_currentActivityId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Activity ID: $_currentActivityId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tracking controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentState == LocationTrackingState.stopped
                                ? _startTracking
                                : null,
                            child: const Text('Start'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentState == LocationTrackingState.active
                                ? _pauseTracking
                                : _currentState == LocationTrackingState.paused
                                    ? _resumeTracking
                                    : null,
                            child: Text(_currentState == LocationTrackingState.paused
                                ? 'Resume'
                                : 'Pause'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentState != LocationTrackingState.stopped
                                ? _stopTracking
                                : null,
                            child: const Text('Stop'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'State: ${_currentState.toString().split('.').last}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Background stats
            if (_backgroundStats.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Background Stats',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...(_backgroundStats.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Track points
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track Points (${_trackPoints.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _trackPoints.length,
                          itemBuilder: (context, index) {
                            final point = _trackPoints[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                '${point.coordinates.latitude.toStringAsFixed(6)}, '
                                '${point.coordinates.longitude.toStringAsFixed(6)}',
                              ),
                              subtitle: Text(
                                'Accuracy: ${point.accuracy.toStringAsFixed(1)}m • '
                                'Time: ${point.timestamp.dateTime.toLocal().toString().split('.')[0]}',
                              ),
                              trailing: Text('#${point.sequence}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}