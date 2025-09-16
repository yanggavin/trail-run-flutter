import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/track_point.dart';

/// Widget displaying elevation profile chart using fl_chart
class ElevationChartWidget extends StatelessWidget {
  const ElevationChartWidget({
    super.key,
    required this.trackPoints,
    this.height = 200,
    this.showGrid = true,
    this.lineColor = Colors.blue,
    this.fillColor,
  });

  final List<TrackPoint> trackPoints;
  final double height;
  final bool showGrid;
  final Color lineColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    if (trackPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'No elevation data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final elevationData = _prepareElevationData();
    
    if (elevationData.isEmpty) {
      return SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'No valid elevation data',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final minElevation = elevationData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxElevation = elevationData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final elevationRange = maxElevation - minElevation;
    
    // Add some padding to the elevation range
    final paddedMin = minElevation - (elevationRange * 0.1);
    final paddedMax = maxElevation + (elevationRange * 0.1);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: showGrid,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: elevationRange > 100 ? 50 : 25,
            verticalInterval: null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateDistanceInterval(),
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toStringAsFixed(1)}km',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: elevationRange > 100 ? 50 : 25,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${value.toInt()}m',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          minX: 0,
          maxX: _calculateTotalDistance(),
          minY: paddedMin,
          maxY: paddedMax,
          lineBarsData: [
            LineChartBarData(
              spots: elevationData,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: fillColor != null,
                color: fillColor?.withOpacity(0.3) ?? lineColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.x.toStringAsFixed(1)}km\n${spot.y.toStringAsFixed(0)}m',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _prepareElevationData() {
    final spots = <FlSpot>[];
    double cumulativeDistance = 0;
    
    for (int i = 0; i < trackPoints.length; i++) {
      final point = trackPoints[i];
      
      // Skip points without elevation data
      if (point.coordinates.elevation == null) continue;
      
      // Calculate cumulative distance
      if (i > 0) {
        final prevPoint = trackPoints[i - 1];
        final distance = _calculateDistance(
          prevPoint.coordinates.latitude,
          prevPoint.coordinates.longitude,
          point.coordinates.latitude,
          point.coordinates.longitude,
        );
        cumulativeDistance += distance;
      }
      
      spots.add(FlSpot(
        cumulativeDistance / 1000, // Convert to kilometers
        point.coordinates.elevation!,
      ));
    }
    
    return spots;
  }

  double _calculateTotalDistance() {
    if (trackPoints.length < 2) return 1.0;
    
    double totalDistance = 0;
    for (int i = 1; i < trackPoints.length; i++) {
      final prevPoint = trackPoints[i - 1];
      final currentPoint = trackPoints[i];
      
      final distance = _calculateDistance(
        prevPoint.coordinates.latitude,
        prevPoint.coordinates.longitude,
        currentPoint.coordinates.latitude,
        currentPoint.coordinates.longitude,
      );
      totalDistance += distance;
    }
    
    return totalDistance / 1000; // Convert to kilometers
  }

  double _calculateDistanceInterval() {
    final totalDistance = _calculateTotalDistance();
    
    if (totalDistance <= 2) return 0.5;
    if (totalDistance <= 5) return 1.0;
    if (totalDistance <= 10) return 2.0;
    if (totalDistance <= 20) return 5.0;
    return 10.0;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

extension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
}