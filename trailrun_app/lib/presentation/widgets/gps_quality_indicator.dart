import 'package:flutter/material.dart';
import '../../domain/repositories/location_repository.dart';

/// Widget displaying GPS signal quality and accuracy information
class GpsQualityIndicator extends StatelessWidget {
  const GpsQualityIndicator({
    super.key,
    this.quality,
    this.accuracy,
    this.showDetails = false,
  });

  final LocationQuality? quality;
  final double? accuracy;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final effectiveQuality = quality ?? const LocationQuality(
      accuracy: 999.0,
      signalStrength: 0.0,
      satelliteCount: 0,
      isGpsEnabled: false,
    );
    
    return GestureDetector(
      onTap: showDetails ? null : () => _showQualityDetails(context, effectiveQuality),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getQualityColor(effectiveQuality).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getQualityColor(effectiveQuality),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getQualityIcon(effectiveQuality),
              color: _getQualityColor(effectiveQuality),
              size: 16,
            ),
            const SizedBox(width: 4),
            if (showDetails) ...[
              _buildDetailedInfo(effectiveQuality),
            ] else ...[
              _buildCompactInfo(effectiveQuality),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(LocationQuality quality) {
    return Text(
      _getQualityText(quality),
      style: TextStyle(
        color: _getQualityColor(quality),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDetailedInfo(LocationQuality quality) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _getQualityText(quality),
          style: TextStyle(
            color: _getQualityColor(quality),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (accuracy != null)
          Text(
            '±${accuracy!.toInt()}m',
            style: TextStyle(
              color: _getQualityColor(quality).withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        Text(
          '${quality.satelliteCount} sats',
          style: TextStyle(
            color: _getQualityColor(quality).withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getQualityColor(LocationQuality quality) {
    if (!quality.isGpsEnabled) {
      return Colors.red;
    }

    final score = quality.qualityScore;
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.orange;
    } else if (score >= 0.4) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  IconData _getQualityIcon(LocationQuality quality) {
    if (!quality.isGpsEnabled) {
      return Icons.gps_off;
    }

    final score = quality.qualityScore;
    if (score >= 0.8) {
      return Icons.gps_fixed;
    } else if (score >= 0.6) {
      return Icons.gps_not_fixed;
    } else {
      return Icons.gps_off;
    }
  }

  String _getQualityText(LocationQuality quality) {
    if (!quality.isGpsEnabled) {
      return 'GPS OFF';
    }

    final score = quality.qualityScore;
    if (score >= 0.8) {
      return 'EXCELLENT';
    } else if (score >= 0.6) {
      return 'GOOD';
    } else if (score >= 0.4) {
      return 'FAIR';
    } else {
      return 'POOR';
    }
  }

  void _showQualityDetails(BuildContext context, LocationQuality quality) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.blue),
            SizedBox(width: 8),
            Text('GPS Quality'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQualityDetailRow(
              'Status',
              quality.isGpsEnabled ? 'Enabled' : 'Disabled',
              quality.isGpsEnabled ? Colors.green : Colors.red,
            ),
            _buildQualityDetailRow(
              'Accuracy',
              accuracy != null ? '±${accuracy!.toInt()}m' : 'Unknown',
              _getAccuracyColor(),
            ),
            _buildQualityDetailRow(
              'Satellites',
              '${quality.satelliteCount}',
              _getSatelliteColor(),
            ),
            _buildQualityDetailRow(
              'Signal Strength',
              '${(quality.signalStrength * 100).toInt()}%',
              _getSignalColor(),
            ),
            _buildQualityDetailRow(
              'Overall Quality',
              _getQualityText(quality),
              _getQualityColor(quality),
            ),
            const SizedBox(height: 16),
            _buildQualityTips(quality),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityTips(LocationQuality quality) {
    final tips = <String>[];
    
    if (!quality.isGpsEnabled) {
      tips.add('• Enable GPS in device settings');
    }
    
    if (quality.satelliteCount < 4) {
      tips.add('• Move to an open area with clear sky view');
    }
    
    if (quality.accuracy > 20) {
      tips.add('• Wait for GPS to acquire better signal');
    }
    
    if (quality.signalStrength < 0.5) {
      tips.add('• Avoid areas with tall buildings or dense trees');
    }

    if (tips.isEmpty) {
      tips.add('• GPS quality is good for accurate tracking');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            tip,
            style: const TextStyle(fontSize: 12),
          ),
        )),
      ],
    );
  }

  Color _getAccuracyColor() {
    if (accuracy == null) return Colors.grey;
    if (accuracy! <= 5) return Colors.green;
    if (accuracy! <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getSatelliteColor() {
    final effectiveQuality = quality ?? const LocationQuality(
      accuracy: 999.0,
      signalStrength: 0.0,
      satelliteCount: 0,
      isGpsEnabled: false,
    );
    if (effectiveQuality.satelliteCount >= 8) return Colors.green;
    if (effectiveQuality.satelliteCount >= 4) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor() {
    final effectiveQuality = quality ?? const LocationQuality(
      accuracy: 999.0,
      signalStrength: 0.0,
      satelliteCount: 0,
      isGpsEnabled: false,
    );
    if (effectiveQuality.signalStrength >= 0.8) return Colors.green;
    if (effectiveQuality.signalStrength >= 0.5) return Colors.orange;
    return Colors.red;
  }
}