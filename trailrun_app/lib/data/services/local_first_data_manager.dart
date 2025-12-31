import 'dart:convert';

import '../database/database.dart';
import '../database/daos/activity_dao.dart';
import '../database/daos/photo_dao.dart';
import '../database/daos/track_point_dao.dart';
import '../database/daos/split_dao.dart';
import '../../domain/models/models.dart';
import '../../domain/enums/enums.dart';
import 'sync_service.dart';

/// Manager for local-first data operations with automatic sync queuing
class LocalFirstDataManager {
  static final LocalFirstDataManager _instance = LocalFirstDataManager._internal();
  factory LocalFirstDataManager() => _instance;
  LocalFirstDataManager._internal();

  TrailRunDatabase? _database;
  ActivityDao? _activityDao;
  PhotoDao? _photoDao;
  TrackPointDao? _trackPointDao;
  SplitDao? _splitDao;
  SyncService? _syncService;

  /// Initialize the data manager
  Future<void> initialize({
    required TrailRunDatabase database,
    required SyncService syncService,
  }) async {
    _database = database;
    _activityDao = database.activityDao;
    _photoDao = database.photoDao;
    _trackPointDao = database.trackPointDao;
    _splitDao = database.splitDao;
    _syncService = syncService;
  }

  // Activity Operations

  /// Create activity with immediate local persistence and sync queuing
  Future<Activity> createActivity(Activity activity) async {
    if (_activityDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Set initial sync state to local
    final localActivity = activity.copyWith(syncState: SyncState.local);
    
    // Persist immediately to local database
    await _activityDao!.insertActivity(localActivity.toEntity());
    
    // Queue for sync
    await _syncService!.queueEntitySync(
      entityType: 'activity',
      entityId: localActivity.id,
      operation: 'create',
      data: localActivity.toJson(),
      priority: 1, // High priority for new activities
    );

    return localActivity;
  }

  /// Update activity with immediate local persistence and sync queuing
  Future<Activity> updateActivity(Activity activity) async {
    if (_activityDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Update sync state to pending if it was synced
    final updatedActivity = activity.syncState == SyncState.synced
        ? activity.copyWith(syncState: SyncState.pending)
        : activity;
    
    // Persist immediately to local database
    await _activityDao!.updateActivity(updatedActivity.toEntity());
    
    // Queue for sync
    await _syncService!.queueEntitySync(
      entityType: 'activity',
      entityId: updatedActivity.id,
      operation: 'update',
      data: updatedActivity.toJson(),
    );

    return updatedActivity;
  }

  /// Delete activity with immediate local persistence and sync queuing
  Future<void> deleteActivity(String activityId) async {
    if (_activityDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Get activity before deletion for sync data
    final activity = await _activityDao!.getActivityById(activityId);
    if (activity == null) return;

    // Delete immediately from local database
    await _activityDao!.deleteActivity(activityId);
    
    // Queue for sync only if it was previously synced
    if (activity.syncState == SyncState.synced.index) {
      await _syncService!.queueEntitySync(
        entityType: 'activity',
        entityId: activityId,
        operation: 'delete',
        data: {'id': activityId},
      );
    }
  }

  /// Get activity by ID
  Future<Activity?> getActivity(String activityId) async {
    if (_activityDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final entity = await _activityDao!.getActivityById(activityId);
    return entity?.toDomain();
  }

  /// Get all activities with pagination
  Future<List<Activity>> getActivities({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    if (_activityDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final entities = await _activityDao!.getActivities(
      limit: limit,
      offset: offset,
    );
    
    return entities.map((e) => e.toDomain()).toList();
  }

  /// Watch activity changes
  Stream<Activity?> watchActivity(String activityId) {
    if (_activityDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    return _activityDao!.watchActivity(activityId)
        .map((entity) => entity?.toDomain());
  }

  /// Watch all activities
  Stream<List<Activity>> watchActivities({int limit = 20}) {
    if (_activityDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    return _activityDao!.watchActivities(limit: limit)
        .map((entities) => entities.map((e) => e.toDomain()).toList());
  }

  // Photo Operations

  /// Create photo with immediate local persistence and sync queuing
  Future<Photo> createPhoto(Photo photo) async {
    if (_photoDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Set initial sync state to local
    final localPhoto = photo.copyWith(syncState: SyncState.local);
    
    // Persist immediately to local database
    await _photoDao!.insertPhoto(localPhoto.toEntity());
    
    // Queue for sync
    await _syncService!.queueEntitySync(
      entityType: 'photo',
      entityId: localPhoto.id,
      operation: 'create',
      data: localPhoto.toJson(),
      priority: 2, // Medium priority for photos
    );

    return localPhoto;
  }

  /// Update photo with immediate local persistence and sync queuing
  Future<Photo> updatePhoto(Photo photo) async {
    if (_photoDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Update sync state to pending if it was synced
    final updatedPhoto = photo.syncState == SyncState.synced
        ? photo.copyWith(syncState: SyncState.pending)
        : photo;
    
    // Persist immediately to local database
    await _photoDao!.updatePhoto(updatedPhoto.toEntity());
    
    // Queue for sync
    await _syncService!.queueEntitySync(
      entityType: 'photo',
      entityId: updatedPhoto.id,
      operation: 'update',
      data: updatedPhoto.toJson(),
    );

    return updatedPhoto;
  }

  /// Delete photo with immediate local persistence and sync queuing
  Future<void> deletePhoto(String photoId) async {
    if (_photoDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Get photo before deletion for sync data
    final photo = await _photoDao!.getPhotoById(photoId);
    if (photo == null) return;

    // Delete immediately from local database
    await _photoDao!.deletePhoto(photoId);
    
    // Queue for sync only if it was previously synced
    if (photo.syncState == SyncState.synced.index) {
      await _syncService!.queueEntitySync(
        entityType: 'photo',
        entityId: photoId,
        operation: 'delete',
        data: {'id': photoId},
      );
    }
  }

  /// Get photos for activity
  Future<List<Photo>> getPhotosForActivity(String activityId) async {
    if (_photoDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final entities = await _photoDao!.getPhotosForActivity(activityId);
    return entities.map((e) => e.toDomain()).toList();
  }

  // Track Point Operations

  /// Create track point with immediate local persistence and sync queuing
  Future<TrackPoint> createTrackPoint(TrackPoint trackPoint) async {
    if (_trackPointDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Persist immediately to local database
    await _trackPointDao!.insertTrackPoint(trackPoint.toEntity());
    
    // Queue for sync with lower priority (track points are numerous)
    await _syncService!.queueEntitySync(
      entityType: 'track_point',
      entityId: trackPoint.id,
      operation: 'create',
      data: trackPoint.toJson(),
      priority: 0, // Lower priority for track points
    );

    return trackPoint;
  }

  /// Create multiple track points in batch
  Future<void> createTrackPointsBatch(List<TrackPoint> trackPoints) async {
    if (_trackPointDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Persist immediately to local database in batch
    await _trackPointDao!.insertTrackPointsBatch(
      trackPoints.map((tp) => tp.toEntity()).toList(),
    );
    
    // Queue for sync in batch with lower priority
    for (final trackPoint in trackPoints) {
      await _syncService!.queueEntitySync(
        entityType: 'track_point',
        entityId: trackPoint.id,
        operation: 'create',
        data: trackPoint.toJson(),
        priority: 0,
      );
    }
  }

  /// Get track points for activity
  Future<List<TrackPoint>> getTrackPointsForActivity(String activityId) async {
    if (_trackPointDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final entities = await _trackPointDao!.getTrackPointsForActivity(activityId);
    return entities.map((e) => e.toDomain()).toList();
  }

  // Split Operations

  /// Create split with immediate local persistence and sync queuing
  Future<Split> createSplit(Split split) async {
    if (_splitDao == null || _syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    // Persist immediately to local database
    await _splitDao!.insertSplit(split.toEntity());
    
    // Queue for sync
    await _syncService!.queueEntitySync(
      entityType: 'split',
      entityId: split.id,
      operation: 'create',
      data: split.toJson(),
      priority: 1,
    );

    return split;
  }

  /// Get splits for activity
  Future<List<Split>> getSplitsForActivity(String activityId) async {
    if (_splitDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final entities = await _splitDao!.getSplitsForActivity(activityId);
    return entities.map((e) => e.toDomain()).toList();
  }

  // Sync Management

  /// Force sync for specific activity
  Future<void> syncActivity(String activityId) async {
    if (_syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    await _syncService!.syncActivity(activityId);
  }

  /// Force sync all pending data
  Future<void> syncAll() async {
    if (_syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    await _syncService!.syncAll();
  }

  /// Get sync status stream
  Stream<SyncStatus> get syncStatusStream {
    if (_syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    return _syncService!.syncStatusStream;
  }

  /// Get conflict resolution stream
  Stream<SyncConflict> get conflictStream {
    if (_syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    return _syncService!.conflictStream;
  }

  /// Resolve sync conflict
  Future<void> resolveConflict(SyncConflict conflict, {bool preserveLocal = true}) async {
    if (_syncService == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    await _syncService!.resolveConflict(conflict, preserveLocal: preserveLocal);
  }

  /// Check if data is available offline
  bool get isOfflineCapable => _database != null;

  /// Get offline data statistics
  Future<OfflineDataStats> getOfflineDataStats() async {
    if (_activityDao == null || _photoDao == null || _trackPointDao == null) {
      throw StateError('LocalFirstDataManager not initialized');
    }

    final activityCount = await _activityDao!.getActivitiesCount();
    final photoCount = await _photoDao!.getPhotosCount();
    final trackPointCount = await _trackPointDao!.getTrackPointsCount();

    return OfflineDataStats(
      activityCount: activityCount,
      photoCount: photoCount,
      trackPointCount: trackPointCount,
      lastSyncTime: _syncService!.lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Offline data statistics
class OfflineDataStats {
  final int activityCount;
  final int photoCount;
  final int trackPointCount;
  final DateTime lastSyncTime;

  const OfflineDataStats({
    required this.activityCount,
    required this.photoCount,
    required this.trackPointCount,
    required this.lastSyncTime,
  });
}

/// Extension methods for domain model conversions
extension ActivityEntityExtension on ActivityEntity {
  Activity toDomain() {
    return Activity(
      id: id,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTime),
      endTime: endTime != null ? DateTime.fromMillisecondsSinceEpoch(endTime!) : null,
      distanceMeters: distanceMeters,
      duration: Duration(seconds: durationSeconds),
      elevationGainMeters: elevationGainMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      title: title,
      notes: notes,
      privacy: PrivacyLevel.values[privacyLevel],
      coverPhotoId: coverPhotoId,
      syncState: SyncState.values[syncState],
      trackPoints: const [], // Loaded separately
      photos: const [], // Loaded separately
      splits: const [], // Loaded separately
    );
  }
}

extension ActivityDomainExtension on Activity {
  ActivityEntity toEntity() {
    return ActivityEntity(
      id: id,
      startTime: startTime.millisecondsSinceEpoch,
      endTime: endTime?.millisecondsSinceEpoch,
      distanceMeters: distanceMeters,
      durationSeconds: duration.inSeconds,
      elevationGainMeters: elevationGainMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      title: title,
      notes: notes,
      privacyLevel: privacy.index,
      coverPhotoId: coverPhotoId,
      syncState: syncState.index,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'distanceMeters': distanceMeters,
      'durationSeconds': duration.inSeconds,
      'elevationGainMeters': elevationGainMeters,
      'averagePaceSecondsPerKm': averagePaceSecondsPerKm,
      'title': title,
      'notes': notes,
      'privacy': privacy.name,
      'coverPhotoId': coverPhotoId,
    };
  }
}

extension PhotoEntityExtension on PhotoEntity {
  Photo toDomain() {
    return Photo(
      id: id,
      activityId: activityId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      latitude: latitude,
      longitude: longitude,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      hasExifData: hasExifData,
      curationScore: curationScore,
      syncState: SyncState.values[syncState],
    );
  }
}

extension PhotoDomainExtension on Photo {
  PhotoEntity toEntity() {
    return PhotoEntity(
      id: id,
      activityId: activityId,
      timestamp: timestamp.millisecondsSinceEpoch,
      latitude: latitude,
      longitude: longitude,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      hasExifData: hasExifData,
      curationScore: curationScore,
      syncState: syncState.index,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'hasExifData': hasExifData,
      'curationScore': curationScore,
    };
  }
}

extension TrackPointEntityExtension on TrackPointEntity {
  TrackPoint toDomain() {
    return TrackPoint(
      id: id,
      activityId: activityId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      latitude: latitude,
      longitude: longitude,
      elevation: elevation,
      accuracy: accuracy,
      source: LocationSource.values[source],
      sequence: sequence,
    );
  }
}

extension TrackPointDomainExtension on TrackPoint {
  TrackPointEntity toEntity() {
    return TrackPointEntity(
      id: id,
      activityId: activityId,
      timestamp: timestamp.millisecondsSinceEpoch,
      latitude: latitude,
      longitude: longitude,
      elevation: elevation,
      accuracy: accuracy,
      source: source.index,
      sequence: sequence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'accuracy': accuracy,
      'source': source.name,
      'sequence': sequence,
    };
  }
}

extension SplitEntityExtension on SplitEntity {
  Split toDomain() {
    return Split(
      id: id,
      activityId: activityId,
      splitNumber: splitNumber,
      distanceMeters: distanceMeters,
      duration: Duration(seconds: durationSeconds),
      elevationGainMeters: elevationGainMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTime),
      endTime: DateTime.fromMillisecondsSinceEpoch(endTime),
    );
  }
}

extension SplitDomainExtension on Split {
  SplitEntity toEntity() {
    return SplitEntity(
      id: id,
      activityId: activityId,
      splitNumber: splitNumber,
      distanceMeters: distanceMeters,
      durationSeconds: duration.inSeconds,
      elevationGainMeters: elevationGainMeters,
      averagePaceSecondsPerKm: averagePaceSecondsPerKm,
      startTime: startTime.millisecondsSinceEpoch,
      endTime: endTime.millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'splitNumber': splitNumber,
      'distanceMeters': distanceMeters,
      'durationSeconds': duration.inSeconds,
      'elevationGainMeters': elevationGainMeters,
      'averagePaceSecondsPerKm': averagePaceSecondsPerKm,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}