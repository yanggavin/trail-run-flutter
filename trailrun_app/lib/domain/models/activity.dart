import '../enums/privacy_level.dart';
import '../enums/sync_state.dart';
import '../value_objects/measurement_units.dart';
import '../value_objects/timestamp.dart';
import 'photo.dart';
import 'split.dart';
import 'track_point.dart';

/// Main activity entity representing a tracked running session
class Activity {
  Activity({
    required this.id,
    required this.startTime,
    required this.title,
    this.endTime,
    Distance? distance,
    Elevation? elevationGain,
    Elevation? elevationLoss,
    this.averagePace,
    this.notes,
    this.privacy = PrivacyLevel.private,
    this.coverPhotoId,
    this.syncState = SyncState.local,
    this.trackPoints = const [],
    this.photos = const [],
    this.splits = const [],
  }) : distance = distance ?? Distance.meters(0),
       elevationGain = elevationGain ?? Elevation.meters(0),
       elevationLoss = elevationLoss ?? Elevation.meters(0);

  /// Unique identifier for this activity
  final String id;

  /// When the activity started
  final Timestamp startTime;

  /// When the activity ended (null if still in progress)
  final Timestamp? endTime;

  /// Total distance covered
  final Distance distance;

  /// Total elevation gained
  final Elevation elevationGain;

  /// Total elevation lost
  final Elevation elevationLoss;

  /// Average pace for the entire activity
  final Pace? averagePace;

  /// User-provided title for the activity
  final String title;

  /// Optional user notes about the activity
  final String? notes;

  /// Privacy level for sharing
  final PrivacyLevel privacy;

  /// ID of the photo to use as cover image
  final String? coverPhotoId;

  /// Current synchronization state
  final SyncState syncState;

  /// All GPS track points for this activity
  final List<TrackPoint> trackPoints;

  /// All photos captured during this activity
  final List<Photo> photos;

  /// Per-kilometer splits for this activity
  final List<Split> splits;

  /// Duration of the activity
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Check if activity is currently in progress
  bool get isInProgress => endTime == null;

  /// Check if activity is completed
  bool get isCompleted => endTime != null;

  /// Check if activity has any photos
  bool get hasPhotos => photos.isNotEmpty;

  /// Check if activity has GPS data
  bool get hasGpsData => trackPoints.isNotEmpty;

  /// Get cover photo if available
  Photo? get coverPhoto {
    if (coverPhotoId == null) return null;
    try {
      return photos.firstWhere((photo) => photo.id == coverPhotoId);
    } catch (e) {
      return null;
    }
  }

  /// Get photos sorted by timestamp
  List<Photo> get photosSortedByTime {
    final List<Photo> sortedPhotos = List.from(photos);
    sortedPhotos.sort((a, b) => a.timestamp.dateTime.compareTo(b.timestamp.dateTime));
    return sortedPhotos;
  }

  /// Get track points sorted by sequence
  List<TrackPoint> get trackPointsSortedBySequence {
    final List<TrackPoint> sortedPoints = List.from(trackPoints);
    sortedPoints.sort((a, b) => a.sequence.compareTo(b.sequence));
    return sortedPoints;
  }

  /// Get splits sorted by split number
  List<Split> get splitsSortedByNumber {
    final List<Split> sortedSplits = List.from(splits);
    sortedSplits.sort((a, b) => a.splitNumber.compareTo(b.splitNumber));
    return sortedSplits;
  }

  /// Net elevation change (positive = net gain, negative = net loss)
  Elevation get netElevationChange => elevationGain - elevationLoss;

  /// Check if activity needs sync
  bool get needsSync => syncState == SyncState.pending || syncState == SyncState.failed;

  /// Check if activity is synced
  bool get isSynced => syncState == SyncState.synced;

  /// Get fastest split
  Split? get fastestSplit {
    if (splits.isEmpty) return null;
    return splits.reduce((a, b) => 
        a.pace.secondsPerKilometer < b.pace.secondsPerKilometer ? a : b);
  }

  /// Get slowest split
  Split? get slowestSplit {
    if (splits.isEmpty) return null;
    return splits.reduce((a, b) => 
        a.pace.secondsPerKilometer > b.pace.secondsPerKilometer ? a : b);
  }

  /// Create a copy with updated values
  Activity copyWith({
    String? id,
    Timestamp? startTime,
    Timestamp? endTime,
    Distance? distance,
    Elevation? elevationGain,
    Elevation? elevationLoss,
    Pace? averagePace,
    String? title,
    String? notes,
    PrivacyLevel? privacy,
    String? coverPhotoId,
    SyncState? syncState,
    List<TrackPoint>? trackPoints,
    List<Photo>? photos,
    List<Split>? splits,
  }) {
    return Activity(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      averagePace: averagePace ?? this.averagePace,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      privacy: privacy ?? this.privacy,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
      syncState: syncState ?? this.syncState,
      trackPoints: trackPoints ?? this.trackPoints,
      photos: photos ?? this.photos,
      splits: splits ?? this.splits,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          distance == other.distance &&
          elevationGain == other.elevationGain &&
          elevationLoss == other.elevationLoss &&
          averagePace == other.averagePace &&
          title == other.title &&
          notes == other.notes &&
          privacy == other.privacy &&
          coverPhotoId == other.coverPhotoId &&
          syncState == other.syncState;

  @override
  int get hashCode => Object.hash(
        id,
        startTime,
        endTime,
        distance,
        elevationGain,
        elevationLoss,
        averagePace,
        title,
        notes,
        privacy,
        coverPhotoId,
        syncState,
      );

  @override
  String toString() => 'Activity(id: $id, title: $title, distance: ${distance.kilometers.toStringAsFixed(2)}km, isInProgress: $isInProgress)';
}