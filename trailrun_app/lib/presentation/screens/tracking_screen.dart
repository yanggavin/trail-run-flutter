import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/camera_service.dart';
import '../navigation/app_router.dart';
import '../providers/activity_tracking_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/auto_pause_indicator.dart';
import '../widgets/battery_usage_indicator.dart';
import '../widgets/camera_quick_capture_widget.dart';
import '../widgets/gps_quality_indicator.dart';
import '../widgets/tracking_controls_widget.dart';
import '../widgets/tracking_stats_widget.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    ref.listen<ActivityTrackingState>(activityTrackingProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      await CameraService.instance.initialize();
      if (mounted) {
        setState(() {
          _cameraReady = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    CameraService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(activityTrackingProvider);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Tracking',
          style: TextStyle(color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: BatteryUsageIndicator(showDetails: false),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GpsQualityIndicator(
                    quality: locationState.quality,
                    accuracy: locationState.currentLocation?.accuracy,
                  ),
                  if (trackingState.isAutopaused)
                    AutoPauseIndicator(
                      onManualOverride: () {
                        ref.read(activityTrackingProvider.notifier).resumeActivity();
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: TrackingStatsWidget(trackingState: trackingState),
            ),
            if (_cameraReady)
              CameraQuickCaptureWidget(
                isTracking: trackingState.isTracking,
                onPhotoCaptured: () {
                  ref.read(activityTrackingProvider.notifier).notifyPhotoCaptured();
                },
              )
            else
              const SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    'Camera unavailable',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            TrackingControlsWidget(
              trackingState: trackingState,
              onStartPressed: () => ref.read(activityTrackingProvider.notifier).startActivity(),
              onPausePressed: () => ref.read(activityTrackingProvider.notifier).pauseActivity(),
              onResumePressed: () => ref.read(activityTrackingProvider.notifier).resumeActivity(),
              onStopPressed: () async {
                final activity = await ref.read(activityTrackingProvider.notifier).stopActivity();
                if (!mounted) return;
                if (activity != null) {
                  AppNavigator.toActivitySummary(context, activity);
                } else {
                  AppNavigator.back(context);
                }
              },
              onAutoPauseToggle: () => ref.read(activityTrackingProvider.notifier).toggleAutoPause(),
            ),
          ],
        ),
      ),
    );
  }
}
