import 'dart:math' as math;

import '../../domain/models/track_point.dart';
import '../../domain/value_objects/coordinates.dart';
import '../../domain/value_objects/timestamp.dart';
import '../../domain/enums/location_source.dart';

/// Configuration for GPS signal processing
class GpsProcessingConfig {
  const GpsProcessingConfig({
    this.maxAccuracy = 50.0,
    this.maxSpeed = 50.0,
    this.maxJumpDistance = 1000.0,
    this.kalmanProcessNoise = 0.1,
    this.kalmanMeasurementNoise = 1.0,
    this.enableKalmanFilter = true,
    this.enableOutlierDetection = true,
    this.enableGapInterpolation = true,
    this.maxGapDuration = const Duration(seconds: 30),
    this.minConfidenceScore = 0.3,
  });

  /// Maximum acceptable GPS accuracy in meters
  final double maxAccuracy;
  
  /// Maximum realistic speed in m/s (50 m/s = 180 km/h)
  final double maxSpeed;
  
  /// Maximum distance jump that's considered valid in meters
  final double maxJumpDistance;
  
  /// Kalman filter process noise parameter
  final double kalmanProcessNoise;
  
  /// Kalman filter measurement noise parameter
  final double kalmanMeasurementNoise;
  
  /// Whether to enable Kalman filtering
  final bool enableKalmanFilter;
  
  /// Whether to enable outlier detection
  final bool enableOutlierDetection;
  
  /// Whether to enable gap interpolation
  final bool enableGapInterpolation;
  
  /// Maximum gap duration to interpolate
  final Duration maxGapDuration;
  
  /// Minimum confidence score to accept a point
  final double minConfidenceScore;
}

/// GPS confidence score components
class GpsConfidence {
  const GpsConfidence({
    required this.accuracy,
    required this.speed,
    required this.consistency,
    required this.temporal,
    required this.overall,
  });

  /// Accuracy-based confidence (0.0 to 1.0)
  final double accuracy;
  
  /// Speed-based confidence (0.0 to 1.0)
  final double speed;
  
  /// Consistency with previous points (0.0 to 1.0)
  final double consistency;
  
  /// Temporal consistency (0.0 to 1.0)
  final double temporal;
  
  /// Overall confidence score (0.0 to 1.0)
  final double overall;
}

/// Kalman filter state for GPS coordinates
class KalmanState {
  KalmanState({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.latitudeVelocity,
    required this.longitudeVelocity,
    required this.elevationVelocity,
    required this.errorCovariance,
    required this.timestamp,
  });

  double latitude;
  double longitude;
  double? elevation;
  double latitudeVelocity;
  double longitudeVelocity;
  double? elevationVelocity;
  double errorCovariance;
  DateTime timestamp;

  KalmanState copy() {
    return KalmanState(
      latitude: latitude,
      longitude: longitude,
      elevation: elevation,
      latitudeVelocity: latitudeVelocity,
      longitudeVelocity: longitudeVelocity,
      elevationVelocity: elevationVelocity,
      errorCovariance: errorCovariance,
      timestamp: timestamp,
    );
  }
}

/// GPS signal processing pipeline
class GpsSignalProcessor {
  GpsSignalProcessor({
    GpsProcessingConfig? config,
  }) : _config = config ?? const GpsProcessingConfig();

  final GpsProcessingConfig _config;
  
  // Processing state
  KalmanState? _kalmanState;
  TrackPoint? _lastValidPoint;
  final List<TrackPoint> _recentPoints = [];
  final List<double> _recentSpeeds = [];
  
  // Statistics
  int _totalProcessed = 0;
  int _filteredOut = 0;
  int _interpolated = 0;
  final List<double> _confidenceHistory = [];

  /// Process a raw GPS point through the signal processing pipeline
  ProcessingResult processPoint(TrackPoint rawPoint) {
    _totalProcessed++;
    
    // Step 1: Calculate confidence score
    final confidence = _calculateConfidence(rawPoint);
    _confidenceHistory.add(confidence.overall);
    
    // Keep confidence history manageable
    if (_confidenceHistory.length > 100) {
      _confidenceHistory.removeAt(0);
    }
    
    // Step 2: Basic quality gate
    if (confidence.overall < _config.minConfidenceScore) {
      _filteredOut++;
      return ProcessingResult.filtered(
        reason: 'Low confidence score: ${confidence.overall.toStringAsFixed(2)}',
        confidence: confidence,
      );
    }
    
    // Step 3: Outlier detection
    if (_config.enableOutlierDetection && _isOutlier(rawPoint)) {
      _filteredOut++;
      return ProcessingResult.filtered(
        reason: 'Outlier detected',
        confidence: confidence,
      );
    }
    
    // Step 4: Apply Kalman filter
    TrackPoint processedPoint = rawPoint;
    if (_config.enableKalmanFilter) {
      processedPoint = _applyKalmanFilter(rawPoint);
    }
    
    // Step 5: Update state
    _updateState(processedPoint);
    
    return ProcessingResult.accepted(
      point: processedPoint,
      confidence: confidence,
    );
  }

  /// Interpolate points for gaps in GPS signal
  List<TrackPoint> interpolateGap(TrackPoint beforeGap, TrackPoint afterGap) {
    if (!_config.enableGapInterpolation) {
      return [];
    }
    
    final gapDuration = afterGap.timestamp.difference(beforeGap.timestamp);
    if (gapDuration > _config.maxGapDuration) {
      return []; // Gap too large to interpolate
    }
    
    final distance = beforeGap.distanceTo(afterGap);
    final speed = distance / gapDuration.inSeconds;
    
    // Don't interpolate if implied speed is unrealistic
    if (speed > _config.maxSpeed) {
      return [];
    }
    
    // Calculate number of interpolated points (one every 5 seconds)
    final intervalSeconds = 5;
    final numPoints = (gapDuration.inSeconds / intervalSeconds).floor();
    
    if (numPoints <= 0) {
      return [];
    }
    
    final interpolatedPoints = <TrackPoint>[];
    
    for (int i = 1; i <= numPoints; i++) {
      final ratio = i / (numPoints + 1);
      final interpolatedTime = beforeGap.timestamp.dateTime.add(
        Duration(milliseconds: (gapDuration.inMilliseconds * ratio).round()),
      );
      
      final interpolatedCoords = _interpolateCoordinates(
        beforeGap.coordinates,
        afterGap.coordinates,
        ratio,
      );
      
      final interpolatedPoint = TrackPoint(
        id: '', // Will be set by repository
        activityId: beforeGap.activityId,
        timestamp: Timestamp(interpolatedTime),
        coordinates: interpolatedCoords,
        accuracy: math.max(beforeGap.accuracy, afterGap.accuracy) * 1.5, // Lower confidence
        source: LocationSource.interpolated,
        sequence: beforeGap.sequence + i,
      );
      
      interpolatedPoints.add(interpolatedPoint);
      _interpolated++;
    }
    
    return interpolatedPoints;
  }

  /// Get processing statistics
  ProcessingStats getStats() {
    final averageConfidence = _confidenceHistory.isNotEmpty
        ? _confidenceHistory.reduce((a, b) => a + b) / _confidenceHistory.length
        : 0.0;
    
    return ProcessingStats(
      totalProcessed: _totalProcessed,
      filteredOut: _filteredOut,
      interpolated: _interpolated,
      averageConfidence: averageConfidence,
      filterRate: _totalProcessed > 0 ? _filteredOut / _totalProcessed : 0.0,
    );
  }

  /// Reset processing statistics
  void resetStats() {
    _totalProcessed = 0;
    _filteredOut = 0;
    _interpolated = 0;
    _confidenceHistory.clear();
  }

  /// Reset processing state (for new activity)
  void resetState() {
    _kalmanState = null;
    _lastValidPoint = null;
    _recentPoints.clear();
    _recentSpeeds.clear();
  }

  // Private methods

  GpsConfidence _calculateConfidence(TrackPoint point) {
    // Accuracy confidence (better accuracy = higher confidence)
    final accuracyConfidence = _calculateAccuracyConfidence(point.accuracy);
    
    // Speed confidence (realistic speed = higher confidence)
    final speedConfidence = _calculateSpeedConfidence(point);
    
    // Consistency confidence (consistent with recent points)
    final consistencyConfidence = _calculateConsistencyConfidence(point);
    
    // Temporal confidence (reasonable time progression)
    final temporalConfidence = _calculateTemporalConfidence(point);
    
    // Overall confidence (weighted average)
    final overall = (accuracyConfidence * 0.3 +
                    speedConfidence * 0.25 +
                    consistencyConfidence * 0.25 +
                    temporalConfidence * 0.2);
    
    return GpsConfidence(
      accuracy: accuracyConfidence,
      speed: speedConfidence,
      consistency: consistencyConfidence,
      temporal: temporalConfidence,
      overall: overall,
    );
  }

  double _calculateAccuracyConfidence(double accuracy) {
    if (accuracy <= 3) return 1.0;
    if (accuracy <= 5) return 0.9;
    if (accuracy <= 10) return 0.8;
    if (accuracy <= 20) return 0.6;
    if (accuracy <= 50) return 0.4;
    return 0.2;
  }

  double _calculateSpeedConfidence(TrackPoint point) {
    if (_lastValidPoint == null) return 1.0;
    
    final speed = point.speedTo(_lastValidPoint!);
    
    if (speed <= 15) return 1.0; // Walking/running speed
    if (speed <= 25) return 0.8; // Fast running
    if (speed <= 35) return 0.6; // Cycling speed
    if (speed <= 50) return 0.4; // Vehicle speed
    return 0.1; // Unrealistic speed
  }

  double _calculateConsistencyConfidence(TrackPoint point) {
    if (_recentPoints.length < 2) return 1.0;
    
    // Calculate how consistent this point is with recent trajectory
    final recentSpeeds = <double>[];
    for (int i = 1; i < _recentPoints.length; i++) {
      final speed = _recentPoints[i].speedTo(_recentPoints[i - 1]);
      if (speed.isFinite && speed >= 0) {
        recentSpeeds.add(speed);
      }
    }
    
    if (recentSpeeds.isEmpty) return 1.0;
    
    final currentSpeed = point.speedTo(_recentPoints.last);
    if (!currentSpeed.isFinite || currentSpeed < 0) return 0.5;
    
    final averageSpeed = recentSpeeds.reduce((a, b) => a + b) / recentSpeeds.length;
    
    if (averageSpeed == 0 && currentSpeed == 0) return 1.0; // Both stationary
    if (averageSpeed == 0) return currentSpeed <= 2.0 ? 0.8 : 0.3; // Starting to move
    
    final speedDifference = (currentSpeed - averageSpeed).abs();
    final relativeSpeedDifference = speedDifference / averageSpeed;
    
    if (relativeSpeedDifference <= 0.2) return 1.0; // Within 20%
    if (relativeSpeedDifference <= 0.5) return 0.8; // Within 50%
    if (relativeSpeedDifference <= 1.0) return 0.6; // Within 100%
    return 0.3; // Very inconsistent
  }

  double _calculateTemporalConfidence(TrackPoint point) {
    if (_lastValidPoint == null) return 1.0;
    
    final timeDiff = point.timestamp.difference(_lastValidPoint!.timestamp);
    final seconds = timeDiff.inSeconds.abs();
    
    if (seconds <= 0) return 0.1; // Same or backwards time
    if (seconds <= 10) return 1.0; // Normal interval
    if (seconds <= 30) return 0.8; // Acceptable interval
    if (seconds <= 60) return 0.6; // Long interval
    return 0.4; // Very long interval
  }

  bool _isOutlier(TrackPoint point) {
    if (_lastValidPoint == null) return false;
    
    // Check for impossible distance jumps
    final distance = point.distanceTo(_lastValidPoint!);
    if (distance > _config.maxJumpDistance) {
      return true;
    }
    
    // Check for impossible speed
    final speed = point.speedTo(_lastValidPoint!);
    if (speed > _config.maxSpeed) {
      return true;
    }
    
    return false;
  }

  TrackPoint _applyKalmanFilter(TrackPoint rawPoint) {
    final timestamp = rawPoint.timestamp.dateTime;
    
    if (_kalmanState == null) {
      // Initialize Kalman state
      _kalmanState = KalmanState(
        latitude: rawPoint.coordinates.latitude,
        longitude: rawPoint.coordinates.longitude,
        elevation: rawPoint.coordinates.elevation,
        latitudeVelocity: 0.0,
        longitudeVelocity: 0.0,
        elevationVelocity: 0.0,
        errorCovariance: _config.kalmanProcessNoise,
        timestamp: timestamp,
      );
      return rawPoint;
    }
    
    final dt = timestamp.difference(_kalmanState!.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0) return rawPoint; // Invalid time progression
    
    // Prediction step
    _kalmanState!.latitude += _kalmanState!.latitudeVelocity * dt;
    _kalmanState!.longitude += _kalmanState!.longitudeVelocity * dt;
    if (_kalmanState!.elevation != null && _kalmanState!.elevationVelocity != null) {
      _kalmanState!.elevation = _kalmanState!.elevation! + _kalmanState!.elevationVelocity! * dt;
    }
    
    _kalmanState!.errorCovariance += _config.kalmanProcessNoise * dt;
    
    // Update step
    final measurementNoise = rawPoint.accuracy * _config.kalmanMeasurementNoise;
    final kalmanGain = _kalmanState!.errorCovariance / (_kalmanState!.errorCovariance + measurementNoise);
    
    // Update position
    final latError = rawPoint.coordinates.latitude - _kalmanState!.latitude;
    final lonError = rawPoint.coordinates.longitude - _kalmanState!.longitude;
    
    _kalmanState!.latitude += kalmanGain * latError;
    _kalmanState!.longitude += kalmanGain * lonError;
    
    // Update velocity
    _kalmanState!.latitudeVelocity += kalmanGain * (latError / dt - _kalmanState!.latitudeVelocity);
    _kalmanState!.longitudeVelocity += kalmanGain * (lonError / dt - _kalmanState!.longitudeVelocity);
    
    // Update elevation if available
    if (rawPoint.coordinates.elevation != null && _kalmanState!.elevation != null) {
      final elevError = rawPoint.coordinates.elevation! - _kalmanState!.elevation!;
      _kalmanState!.elevation = _kalmanState!.elevation! + kalmanGain * elevError;
      _kalmanState!.elevationVelocity = (_kalmanState!.elevationVelocity ?? 0.0) + 
          kalmanGain * (elevError / dt - (_kalmanState!.elevationVelocity ?? 0.0));
    }
    
    // Update error covariance
    _kalmanState!.errorCovariance *= (1 - kalmanGain);
    _kalmanState!.timestamp = timestamp;
    
    // Create filtered point
    return rawPoint.copyWith(
      coordinates: Coordinates(
        latitude: _kalmanState!.latitude,
        longitude: _kalmanState!.longitude,
        elevation: _kalmanState!.elevation,
      ),
      accuracy: rawPoint.accuracy * (1 - kalmanGain), // Improved accuracy
    );
  }

  void _updateState(TrackPoint point) {
    _lastValidPoint = point;
    
    // Maintain recent points history
    _recentPoints.add(point);
    if (_recentPoints.length > 10) {
      _recentPoints.removeAt(0);
    }
    
    // Maintain recent speeds history
    if (_recentPoints.length >= 2) {
      final speed = _recentPoints.last.speedTo(_recentPoints[_recentPoints.length - 2]);
      _recentSpeeds.add(speed);
      if (_recentSpeeds.length > 10) {
        _recentSpeeds.removeAt(0);
      }
    }
  }

  Coordinates _interpolateCoordinates(Coordinates start, Coordinates end, double ratio) {
    final lat = start.latitude + (end.latitude - start.latitude) * ratio;
    final lon = start.longitude + (end.longitude - start.longitude) * ratio;
    
    double? elevation;
    if (start.elevation != null && end.elevation != null) {
      elevation = start.elevation! + (end.elevation! - start.elevation!) * ratio;
    }
    
    return Coordinates(
      latitude: lat,
      longitude: lon,
      elevation: elevation,
    );
  }
}

/// Result of processing a GPS point
class ProcessingResult {
  const ProcessingResult._({
    required this.isAccepted,
    this.point,
    this.reason,
    required this.confidence,
  });

  factory ProcessingResult.accepted({
    required TrackPoint point,
    required GpsConfidence confidence,
  }) {
    return ProcessingResult._(
      isAccepted: true,
      point: point,
      confidence: confidence,
    );
  }

  factory ProcessingResult.filtered({
    required String reason,
    required GpsConfidence confidence,
  }) {
    return ProcessingResult._(
      isAccepted: false,
      reason: reason,
      confidence: confidence,
    );
  }

  final bool isAccepted;
  final TrackPoint? point;
  final String? reason;
  final GpsConfidence confidence;
}

/// GPS signal processing statistics
class ProcessingStats {
  const ProcessingStats({
    required this.totalProcessed,
    required this.filteredOut,
    required this.interpolated,
    required this.averageConfidence,
    required this.filterRate,
  });

  final int totalProcessed;
  final int filteredOut;
  final int interpolated;
  final double averageConfidence;
  final double filterRate;
}