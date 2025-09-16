import 'package:flutter/material.dart';
import '../../data/services/graceful_degradation_service.dart';

/// Widget that displays graceful degradation options when permissions are denied
class PermissionDegradationWidget extends StatefulWidget {
  const PermissionDegradationWidget({
    super.key,
    required this.degradationService,
    this.onAlternativeSelected,
  });

  final GracefulDegradationService degradationService;
  final Function(AlternativeFeature)? onAlternativeSelected;

  @override
  State<PermissionDegradationWidget> createState() => _PermissionDegradationWidgetState();
}

class _PermissionDegradationWidgetState extends State<PermissionDegradationWidget> {
  AppCapabilities? _capabilities;
  AlternativeFunctionality? _alternatives;
  DegradedTrackingOptions? _degradedOptions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final capabilities = await widget.degradationService.getAppCapabilities();
      final alternatives = await widget.degradationService.getAlternativeFunctionality();
      final degradedOptions = await widget.degradationService.getDegradedTrackingOptions();

      setState(() {
        _capabilities = capabilities;
        _alternatives = alternatives;
        _degradedOptions = degradedOptions;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_capabilities?.functionalityLevel == FunctionalityLevel.full) {
      return _buildFullFunctionalityView();
    }

    return _buildDegradedFunctionalityView();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to check app capabilities'),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCapabilities,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullFunctionalityView() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text(
                  'All Features Available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'TrailRun has all the permissions needed to provide the full experience.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegradedFunctionalityView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCapabilityStatus(),
          const SizedBox(height: 16),
          if (_capabilities!.limitations.isNotEmpty) _buildLimitations(),
          const SizedBox(height: 16),
          if (_alternatives != null) _buildAlternatives(),
          const SizedBox(height: 16),
          if (_degradedOptions != null) _buildDegradedOptions(),
          const SizedBox(height: 16),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildCapabilityStatus() {
    final level = _capabilities!.functionalityLevel;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (level) {
      case FunctionalityLevel.full:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Full Functionality';
        break;
      case FunctionalityLevel.core:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Core Functionality';
        break;
      case FunctionalityLevel.limited:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Limited Functionality';
        break;
      case FunctionalityLevel.minimal:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'Minimal Functionality';
        break;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCapabilityItem('GPS Tracking', _capabilities!.canTrackLocation),
            _buildCapabilityItem('Background Tracking', _capabilities!.canTrackInBackground),
            _buildCapabilityItem('Camera Access', _capabilities!.canTakePhotos),
            _buildCapabilityItem('Data Storage', _capabilities!.canSaveData),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(String label, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check : Icons.close,
            size: 16,
            color: isAvailable ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildLimitations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Limitations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._capabilities!.limitations.map((limitation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(limitation)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternatives() {
    final hasAlternatives = _alternatives!.locationAlternatives.isNotEmpty ||
                           _alternatives!.photoAlternatives.isNotEmpty ||
                           _alternatives!.backgroundAlternatives.isNotEmpty;

    if (!hasAlternatives) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternative Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_alternatives!.locationAlternatives.isNotEmpty) ...[
              const Text(
                'Location Alternatives:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._alternatives!.locationAlternatives.map(_buildAlternativeFeature),
              const SizedBox(height: 12),
            ],
            if (_alternatives!.photoAlternatives.isNotEmpty) ...[
              const Text(
                'Photo Alternatives:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._alternatives!.photoAlternatives.map(_buildAlternativeFeature),
              const SizedBox(height: 12),
            ],
            if (_alternatives!.backgroundAlternatives.isNotEmpty) ...[
              const Text(
                'Background Tracking Alternatives:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._alternatives!.backgroundAlternatives.map(_buildAlternativeFeature),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeFeature(AlternativeFeature feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: feature.isAvailable ? () async {
          try {
            await feature.action();
            widget.onAlternativeSelected?.call(feature);
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to execute: ${error.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: feature.isAvailable ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
            color: feature.isAvailable ? Colors.blue.shade50 : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Icon(
                feature.isAvailable ? Icons.touch_app : Icons.block,
                color: feature.isAvailable ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: feature.isAvailable ? Colors.blue.shade700 : Colors.grey,
                      ),
                    ),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: feature.isAvailable ? Colors.grey.shade600 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDegradedOptions() {
    final options = <DegradedFeature>[];
    
    if (_degradedOptions!.manualTracking != null) {
      options.add(_degradedOptions!.manualTracking!);
    }
    if (_degradedOptions!.foregroundOnlyTracking != null) {
      options.add(_degradedOptions!.foregroundOnlyTracking!);
    }
    if (_degradedOptions!.photolessTracking != null) {
      options.add(_degradedOptions!.photolessTracking!);
    }

    if (options.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Degraded Tracking Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(_buildDegradedOption),
          ],
        ),
      ),
    );
  }

  Widget _buildDegradedOption(DegradedFeature option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: option.isRecommended ? Colors.green.shade300 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: option.isRecommended ? Colors.green.shade50 : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                option.isRecommended ? Icons.recommend : Icons.info_outline,
                color: option.isRecommended ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: option.isRecommended ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ),
              if (option.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(option.description),
          const SizedBox(height: 8),
          if (option.limitations.isNotEmpty) ...[
            const Text(
              'Limitations:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            ...option.limitations.map((limitation) => Text(
              '• $limitation',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            )),
            const SizedBox(height: 4),
          ],
          if (option.benefits.isNotEmpty) ...[
            const Text(
              'Benefits:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            ...option.benefits.map((benefit) => Text(
              '• $benefit',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_capabilities!.recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._capabilities!.recommendations.map((recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text(recommendation)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}