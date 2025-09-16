import 'dart:math' as math;

import '../../domain/models/activity.dart';
import '../../domain/models/split.dart';
import '../../domain/models/track_point.dart';
import '../../domain/value_objects/measurement_units.dart';
import '../../domain/value_objects/timestamp.dart';

/// Service for calculating activity statistics and generating splits
class ActivityStatisticsService {
  /// Calculate total distance from track points using GPS coordinates
  Distance calculateTotalDistance(List<TrackPoint> trackPoints) {
    if (trackPoints.length < 2) {
      return Distance.meters(0);
    }

    final sortedPoints = List<TrackPoint>.from(trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    double totalDistance = 0.0;
    for (int i = 1; i < sortedPoints.length; i++) {
      totalDistance += sortedPoints[i - 1].distanceTo(sortedPoints[i]);
    }

    return Distance.meters(totalDistance);
  }

  /// Calculate average pace for the entire activity
  Pace? calculateAveragePace(List<TrackPoint> trackPoints, Duration? duration) {
    if (trackPoints.length < 2 || duration == null || duration.inSeconds == 0) {
      return null;
    }

    final distance = calculateTotalDistance(trackPoints);
    if (distance.kilometers == 0) {
      return null;
    }

    return Pace.fromDistanceAndDuration(distance, duration);
  }

  /// Calculate elevation gain and loss from track points
  ElevationStats calculateElevationStats(List<TrackPoint> trackPoints) {
    if (trackPoints.length < 2) {
      return ElevationStats(
        gain: Elevation.meters(0),
        loss: Elevation.meters(0),
      );
    }

    final sortedPoints = List<TrackPoint>.from(trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    double totalGain = 0.0;
    double totalLoss = 0.0;
    double? lastElevation;

    for (final point in sortedPoints) {
      final currentElevation = point.coordinates.elevation;
      
      if (currentElevation != null) {
        if (lastElevation != null) {
          final elevationChange = currentElevation - lastElevation;
          if (elevationChange > 0) {
            totalGain += elevationChange;
          } else {
            totalLoss += elevationChange.abs();
          }
        }
        lastElevation = currentElevation;
      }
    }

    return ElevationStats(
      gain: Elevation.meters(totalGain),
      loss: Elevation.meters(totalLoss),
    );
  }

  /// Generate per-kilometer splits from track points
  List<Split> generateSplits(String activityId, List<TrackPoint> trackPoints) {
    if (trackPoints.length < 2) {
      return [];
    }

    final sortedPoints = List<TrackPoint>.from(trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final List<Split> splits = [];
    double cumulativeDistance = 0.0;
    int currentSplitNumber = 1;
    int splitStartIndex = 0;

    for (int i = 1; i < sortedPoints.length; i++) {
      final segmentDistance = sortedPoints[i - 1].distanceTo(sortedPoints[i]);
      cumulativeDistance += segmentDistance;

      // Check if we've completed a kilometer
      if (cumulativeDistance >= 1000.0) {
        // Find the exact point where we crossed the kilometer mark
        final excessDistance = cumulativeDistance - 1000.0;
        final segmentRatio = (segmentDistance - excessDistance) / segmentDistance;
        
        // Interpolate the exact crossing point
        final crossingPoint = _interpolateTrackPoint(
          sortedPoints[i - 1],
          sortedPoints[i],
          segmentRatio,
        );

        // Create the split
        final split = _createSplit(
          activityId: activityId,
          splitNumber: currentSplitNumber,
          startPoint: sortedPoints[splitStartIndex],
          endPoint: crossingPoint,
          trackPoints: sortedPoints.sublist(splitStartIndex, i + 1),
        );

        splits.add(split);

        // Reset for next split
        currentSplitNumber++;
        splitStartIndex = i;
        cumulativeDistance = excessDistance;
      }
    }

    // Handle partial final split if there's remaining distance
    if (splitStartIndex < sortedPoints.length - 1 && cumulativeDistance > 100) {
      final split = _createSplit(
        activityId: activityId,
        splitNumber: currentSplitNumber,
        startPoint: sortedPoints[splitStartIndex],
        endPoint: sortedPoints.last,
        trackPoints: sortedPoints.sublist(splitStartIndex),
      );
      splits.add(split);
    }

    return splits;
  }

  /// Calculate moving average pace over a specified window
  List<Pace> calculateMovingAveragePace(
    List<TrackPoint> trackPoints, {
    Duration windowSize = const Duration(minutes: 1),
  }) {
    if (trackPoints.length < 2) {
      return [];
    }

    final sortedPoints = List<TrackPoint>.from(trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final List<Pace> movingAverages = [];
    final windowSizeMs = windowSize.inMilliseconds;

    for (int i = 0; i < sortedPoints.length; i++) {
      final currentTime = sortedPoints[i].timestamp.dateTime;
      final windowStart = currentTime.subtract(windowSize);

      // Find points within the window
      final windowPoints = <TrackPoint>[];
      for (int j = i; j >= 0; j--) {
        final pointTime = sortedPoints[j].timestamp.dateTime;
        if (pointTime.isAfter(windowStart)) {
          windowPoints.insert(0, sortedPoints[j]);
        } else {
          break;
        }
      }

      if (windowPoints.length >= 2) {
        final windowDistance = calculateTotalDistance(windowPoints);
        final windowDuration = Duration(
          milliseconds: windowPoints.last.timestamp.dateTime
              .difference(windowPoints.first.timestamp.dateTime)
              .inMilliseconds,
        );

        if (windowDuration.inSeconds > 0 && windowDistance.meters > 0) {
          final pace = Pace.fromDistanceAndDuration(windowDistance, windowDuration);
          movingAverages.add(pace);
        }
      }
    }

    return movingAverages;
  }

  /// Generate elevation profile data points for visualization
  List<ElevationProfilePoint> generateElevationProfile(List<TrackPoint> trackPoints) {
    if (trackPoints.isEmpty) {
      return [];
    }

    final sortedPoints = List<TrackPoint>.from(trackPoints)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final List<ElevationProfilePoint> profile = [];
    double cumulativeDistance = 0.0;

    // Add first point
    if (sortedPoints.first.coordinates.elevation != null) {
      profile.add(ElevationProfilePoint(
        distance: Distance.meters(0),
        elevation: Elevation.meters(sortedPoints.first.coordinates.elevation!),
      ));
    }

    // Add subsequent points
    for (int i = 1; i < sortedPoints.length; i++) {
      final segmentDistance = sortedPoints[i - 1].distanceTo(sortedPoints[i]);
      cumulativeDistance += segmentDistance;

      if (sortedPoints[i].coordinates.elevation != null) {
        profile.add(ElevationProfilePoint(
          distance: Distance.meters(cumulativeDistance),
          elevation: Elevation.meters(sortedPoints[i].coordinates.elevation!),
        ));
      }
    }

    return profile;
  }

  /// Update activity with calculated statistics
  Activity updateActivityWithStats(Activity activity) {
    final trackPoints = activity.trackPointsSortedBySequence;
    
    if (trackPoints.isEmpty) {
      return activity;
    }

    // Calculate basic stats
    final distance = calculateTotalDistance(trackPoints);
    final elevationStats = calculateElevationStats(trackPoints);
    final averagePace = calculateAveragePace(trackPoints, activity.duration);

    // Generate splits
    final splits = generateSplits(activity.id, trackPoints);

    return activity.copyWith(
      distance: distance,
      elevationGain: elevationStats.gain,
      elevationLoss: elevationStats.loss,
      averagePace: averagePace,
      splits: splits,
    );
  }

  /// Create a split from track points
  Split _createSplit({
    required String activityId,
    required int splitNumber,
    required TrackPoint startPoint,
    required TrackPoint endPoint,
    required List<TrackPoint> trackPoints,
  }) {
    final distance = calculateTotalDistance(trackPoints);
    final duration = endPoint.timestamp.difference(startPoint.timestamp);
    final pace = Pace.fromDistanceAndDuration(distance, duration);
    
    // Calculate elevation change for this split
    final elevationStats = calculateElevationStats(trackPoints);

    return Split(
      id: '${activityId}_split_$splitNumber',
      activityId: activityId,
      splitNumber: splitNumber,
      startTime: startPoint.timestamp,
      endTime: endPoint.timestamp,
      distance: distance,
      pace: pace,
      elevationGain: elevationStats.gain,
      elevationLoss: elevationStats.loss,
    );
  }

  /// Interpolate a track point between two points
  TrackPoint _interpolateTrackPoint(
    TrackPoint start,
    TrackPoint end,
    double ratio,
  ) {
    final lat = start.coordinates.latitude + 
        (end.coordinates.latitude - start.coordinates.latitude) * ratio;
    final lon = start.coordinates.longitude + 
        (end.coordinates.longitude - start.coordinates.longitude) * ratio;
    
    double? elevation;
    if (start.coordinates.elevation != null && end.coordinates.elevation != null) {
      elevation = start.coordinates.elevation! + 
          (end.coordinates.elevation! - start.coordinates.elevation!) * ratio;
    }

    final timestamp = Timestamp(
      start.timestamp.dateTime.add(
        Duration(
          milliseconds: (end.timestamp.dateTime
              .difference(start.timestamp.dateTime)
              .inMilliseconds * ratio).round(),
        ),
      ),
    );

    return TrackPoint(
      id: '${start.id}_interpolated',
      activityId: start.activityId,
      timestamp: timestamp,
      coordinates: start.coordinates.copyWith(
        latitude: lat,
        longitude: lon,
        elevation: elevation,
      ),
      accuracy: math.max(start.accuracy, end.accuracy),
      source: start.source,
      sequence: start.sequence,
    );
  }
}

/// Container for elevation gain and loss statistics
class ElevationStats {
  const ElevationStats({
    required this.gain,
    required this.loss,
  });

  final Elevation gain;
  final Elevation loss;

  Elevation get netChange => gain - loss;
}

/// Data point for elevation profile visualization
class ElevationProfilePoint {
  const ElevationProfilePoint({
    required this.distance,
    required this.elevation,
  });

  final Distance distance;
  final Elevation elevation;

  @override
  String toString() => 'ElevationProfilePoint(${distance.kilometers.toStringAsFixed(2)}km, ${elevation.meters.toStringAsFixed(1)}m)';
}