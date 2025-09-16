import '../value_objects/coordinates.dart';
import '../value_objects/timestamp.dart';

/// Photo captured during an activity with location and metadata
class Photo {
  const Photo({
    required this.id,
    required this.activityId,
    required this.timestamp,
    required this.filePath,
    this.coordinates,
    this.thumbnailPath,
    this.hasExifData = false,
    this.curationScore = 0.0,
    this.caption,
  });

  /// Unique identifier for this photo
  final String id;

  /// ID of the activity this photo belongs to
  final String activityId;

  /// When this photo was captured
  final Timestamp timestamp;

  /// GPS coordinates where photo was taken (if available)
  final Coordinates? coordinates;

  /// File path to the full-size photo
  final String filePath;

  /// File path to the thumbnail (if generated)
  final String? thumbnailPath;

  /// Whether the photo contains EXIF metadata
  final bool hasExifData;

  /// AI-generated curation score (0.0-1.0, higher is better for highlights)
  final double curationScore;

  /// Optional user-provided caption
  final String? caption;

  /// Check if photo has location data
  bool get hasLocation => coordinates != null;

  /// Check if photo has thumbnail
  bool get hasThumbnail => thumbnailPath != null;

  /// Get file extension from path
  String get fileExtension {
    final int lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot + 1).toLowerCase();
  }

  /// Check if photo is suitable for activity cover (high curation score)
  bool get isCoverCandidate => curationScore >= 0.7;

  /// Create a copy with updated values
  Photo copyWith({
    String? id,
    String? activityId,
    Timestamp? timestamp,
    Coordinates? coordinates,
    String? filePath,
    String? thumbnailPath,
    bool? hasExifData,
    double? curationScore,
    String? caption,
  }) {
    return Photo(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timestamp: timestamp ?? this.timestamp,
      coordinates: coordinates ?? this.coordinates,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      hasExifData: hasExifData ?? this.hasExifData,
      curationScore: curationScore ?? this.curationScore,
      caption: caption ?? this.caption,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Photo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activityId == other.activityId &&
          timestamp == other.timestamp &&
          coordinates == other.coordinates &&
          filePath == other.filePath &&
          thumbnailPath == other.thumbnailPath &&
          hasExifData == other.hasExifData &&
          curationScore == other.curationScore &&
          caption == other.caption;

  @override
  int get hashCode => Object.hash(
        id,
        activityId,
        timestamp,
        coordinates,
        filePath,
        thumbnailPath,
        hasExifData,
        curationScore,
        caption,
      );

  @override
  String toString() => 'Photo(id: $id, timestamp: $timestamp, hasLocation: $hasLocation)';
}