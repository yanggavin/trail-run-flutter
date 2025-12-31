import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/activity_tracking_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/tracking_controls_widget.dart';
import '../widgets/tracking_stats_widget.dart';
import '../widgets/gps_quality_indicator.dart';
import '../widgets/battery_usage_indicator.dart';
import '../widgets/auto_pause_indicator.dart';
import '../widgets/camera_quick_capture_widget.dart';
import '../navigation/app_router.dart';
import '../../data/services/camera_service.dart';

/// Main tracking screen for recording trail runs
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize camera service for quick photo capture
      await CameraService.instance.initialize();
      
      setState(() {
        _isInitialized = true;
        _initError = null;
      });
    } catch (e) {
      setState(() {
        _isInitialized = false;
        _initError = e.toString();
      });
    }
  }

  void _handleAppPaused() {
    // Camera will be paused automatically by the system
    // Location tracking continues in background
  }

  void _handleAppResumed() async {
    // Resume camera if needed
    try {
      await CameraService.instance.resume();
    } catch (e) {
      debugPrint('Error resuming camera: $e');
    }
  }

  void _handleAppDetached() {
    // App is being terminated - cleanup handled by providers
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(activityTrackingProvider);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? _buildTrackingInterface(context, trackingState, locationState)
            : _buildInitializingInterface(),
      ),
    );
  }

  Widget _buildInitializingInterface() {
    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to initialize tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _initError!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeServices,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Initializing tracking...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInterface(
    BuildContext context,
    ActivityTrackingState trackingState,
    LocationState locationState,
  ) {
    return Column(
      children: [
        // Top status bar
        _buildTopStatusBar(locationState),
        
        // Main content area
        Expanded(
          child: Column(
            children: [
              // Stats display
              Expanded(
                flex: 2,
                child: TrackingStatsWidget(
                  trackingState: trackingState,
                ),
              ),
              
              // Auto-pause indicator (if active)
              if (trackingState.isAutopaused)
                const AutoPauseIndicator(),
              
              // Camera quick capture
              Expanded(
                flex: 1,
                child: CameraQuickCaptureWidget(
                  isTracking: trackingState.isTracking,
                  onPhotoCaptured: _handlePhotoCaptured,
                ),
              ),
              
              // Control buttons
              TrackingControlsWidget(
                trackingState: trackingState,
                onStartPressed: _handleStartTracking,
                onPausePressed: _handlePauseTracking,
                onResumePressed: _handleResumeTracking,
                onStopPressed: _handleStopTracking,
                onAutoPauseToggle: _handleAutoPauseToggle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatusBar(LocationState locationState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => _handleBackPressed(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          
          const Spacer(),
          
          // GPS quality indicator
          GpsQualityIndicator(
            quality: locationState.quality,
            accuracy: locationState.accuracy,
          ),
          
          const SizedBox(width: 16),
          
          // Battery usage indicator
          const BatteryUsageIndicator(),
        ],
      ),
    );
  }

  void _handleBackPressed() {
    final trackingState = ref.read(activityTrackingProvider);
    
    if (trackingState.isTracking) {
      _showExitTrackingDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showExitTrackingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Tracking?'),
        content: const Text(
          'You have an active tracking session. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePauseTracking();
              Navigator.of(context).pop();
            },
            child: const Text('Pause & Exit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleStopTracking();
            },
            child: const Text('Stop & Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartTracking() async {
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    await trackingNotifier.startActivity();
    
    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking started'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handlePauseTracking() async {
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    await trackingNotifier.pauseActivity();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking paused'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleResumeTracking() async {
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    await trackingNotifier.resumeActivity();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tracking resumed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleStopTracking() async {
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    final activity = await trackingNotifier.stopActivity();
    
    if (mounted) {
      if (activity != null) {
        // Navigate to activity summary
        AppNavigator.toActivitySummary(context, activity);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save activity'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleAutoPauseToggle() {
    final trackingNotifier = ref.read(activityTrackingProvider.notifier);
    trackingNotifier.toggleAutoPause();
    
    if (mounted) {
      final isEnabled = ref.read(activityTrackingProvider).isAutoPauseEnabled;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-pause ${isEnabled ? "enabled" : "disabled"}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handlePhotoCaptured() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}