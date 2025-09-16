import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/platform_permission_service.dart';

/// Platform-appropriate permission request flow widget
class PermissionRequestFlow extends ConsumerStatefulWidget {
  final VoidCallback? onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;
  final bool showBackgroundLocationRationale;

  const PermissionRequestFlow({
    super.key,
    this.onPermissionsGranted,
    this.onPermissionsDenied,
    this.showBackgroundLocationRationale = true,
  });

  @override
  ConsumerState<PermissionRequestFlow> createState() => _PermissionRequestFlowState();
}

class _PermissionRequestFlowState extends ConsumerState<PermissionRequestFlow> {
  PermissionStatus? _currentStatus;
  bool _isRequesting = false;
  int _currentStep = 0;

  final List<PermissionStep> _steps = [
    PermissionStep(
      title: 'Location Access',
      description: 'TrailRun needs location access to track your runs and record GPS data.',
      icon: Icons.location_on,
      isRequired: true,
    ),
    PermissionStep(
      title: 'Background Location',
      description: 'Allow location access even when the app is in the background to continue tracking your runs.',
      icon: Icons.gps_fixed,
      isRequired: true,
      platformSpecific: true,
    ),
    PermissionStep(
      title: 'Camera Access',
      description: 'Take photos during your runs and geotag them with your location.',
      icon: Icons.camera_alt,
      isRequired: false,
    ),
    PermissionStep(
      title: 'Photo Storage',
      description: 'Save photos taken during your runs to your device.',
      icon: Icons.photo_library,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final status = await PlatformPermissionService.checkAllPermissions();
    setState(() {
      _currentStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: _steps.length,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildPermissionStep(_steps[index], index);
              },
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildPermissionStep(PermissionStep step, int index) {
    final isGranted = _isPermissionGranted(step);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (index + 1) / _steps.length,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isGranted 
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check : step.icon,
              size: 40,
              color: isGranted 
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            step.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Platform-specific information
          if (step.platformSpecific) ...[
            _buildPlatformSpecificInfo(step),
            const SizedBox(height: 24),
          ],

          // Status
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Permission Granted',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            )
          else if (step.isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Required Permission',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformSpecificInfo(PermissionStep step) {
    final theme = Theme.of(context);
    
    if (step.title == 'Background Location') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Platform.isIOS ? Icons.phone_iphone : Icons.android,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isIOS 
                ? 'On iOS, you\'ll need to select "Always" when prompted for location access.'
                : 'On Android 10+, you\'ll be asked for background location access separately.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildBottomActions() {
    final theme = Theme.of(context);
    final isLastStep = _currentStep == _steps.length - 1;
    final currentStep = _steps[_currentStep];
    final isGranted = _isPermissionGranted(currentStep);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isGranted) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isRequesting ? null : () => _requestPermission(currentStep),
                  child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Grant ${currentStep.title}'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            if (isLastStep && _allRequiredPermissionsGranted())
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onPermissionsGranted?.call();
                  },
                  child: const Text('Continue'),
                ),
              )
            else if (isGranted || !currentStep.isRequired)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (isLastStep) {
                      if (_allRequiredPermissionsGranted()) {
                        widget.onPermissionsGranted?.call();
                      } else {
                        widget.onPermissionsDenied?.call();
                      }
                    } else {
                      // Move to next step
                      setState(() {
                        _currentStep = (_currentStep + 1).clamp(0, _steps.length - 1);
                      });
                    }
                  },
                  child: Text(isLastStep ? 'Finish' : 'Next'),
                ),
              ),
            
            if (!currentStep.isRequired && !isGranted)
              TextButton(
                onPressed: () {
                  if (isLastStep) {
                    widget.onPermissionsGranted?.call();
                  } else {
                    setState(() {
                      _currentStep = (_currentStep + 1).clamp(0, _steps.length - 1);
                    });
                  }
                },
                child: const Text('Skip'),
              ),
          ],
        ),
      ),
    );
  }

  bool _isPermissionGranted(PermissionStep step) {
    if (_currentStatus == null) return false;

    switch (step.title) {
      case 'Location Access':
        return _currentStatus!.location != LocationPermissionResult.denied;
      case 'Background Location':
        return _currentStatus!.location == LocationPermissionResult.always;
      case 'Camera Access':
        return _currentStatus!.camera;
      case 'Photo Storage':
        return _currentStatus!.storage;
      default:
        return false;
    }
  }

  bool _allRequiredPermissionsGranted() {
    return _steps
        .where((step) => step.isRequired)
        .every((step) => _isPermissionGranted(step));
  }

  Future<void> _requestPermission(PermissionStep step) async {
    setState(() {
      _isRequesting = true;
    });

    try {
      switch (step.title) {
        case 'Location Access':
        case 'Background Location':
          await PlatformPermissionService.requestLocationPermission();
          break;
        case 'Camera Access':
          await PlatformPermissionService.requestCameraPermission();
          break;
        case 'Photo Storage':
          await PlatformPermissionService.requestStoragePermission();
          break;
      }

      // Refresh permission status
      await _checkCurrentPermissions();
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }
}

class PermissionStep {
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;
  final bool platformSpecific;

  const PermissionStep({
    required this.title,
    required this.description,
    required this.icon,
    this.isRequired = true,
    this.platformSpecific = false,
  });
}