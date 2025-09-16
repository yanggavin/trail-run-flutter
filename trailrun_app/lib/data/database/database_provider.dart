import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'daos/activity_dao.dart';
import 'daos/track_point_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/split_dao.dart';
import 'daos/sync_queue_dao.dart';

/// Provider for the TrailRun database instance
final databaseProvider = Provider<TrailRunDatabase>((ref) {
  final database = TrailRunDatabase();
  
  // Ensure database is properly disposed when provider is disposed
  ref.onDispose(() {
    database.close();
  });
  
  return database;
});

/// Provider for ActivityDao
final activityDaoProvider = Provider<ActivityDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.activityDao;
});

/// Provider for TrackPointDao
final trackPointDaoProvider = Provider<TrackPointDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.trackPointDao;
});

/// Provider for PhotoDao
final photoDaoProvider = Provider<PhotoDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.photoDao;
});

/// Provider for SplitDao
final splitDaoProvider = Provider<SplitDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.splitDao;
});

/// Provider for SyncQueueDao
final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.syncQueueDao;
});