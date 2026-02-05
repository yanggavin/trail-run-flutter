import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'sync_service.dart';
import 'local_first_data_manager.dart';
import 'network_connectivity_service.dart';

/// Provider for network connectivity service
final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for local-first data manager
final localFirstDataManagerProvider = Provider<LocalFirstDataManager>((ref) {
  return LocalFirstDataManager();
});

/// Provider for initializing offline data services
final offlineDataInitializationProvider = FutureProvider<void>((ref) async {
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  final dataManager = ref.watch(localFirstDataManagerProvider);
  final networkService = ref.watch(networkConnectivityServiceProvider);

  // Initialize network service
  await networkService.initialize();

  // Initialize sync service
  await syncService.initialize(database: database, localOnly: true);

  // Initialize data manager
  await dataManager.initialize(
    database: database,
    syncService: syncService,
  );
});

/// Provider for network connectivity status
final networkConnectivityProvider = StreamProvider<bool>((ref) {
  final networkService = ref.watch(networkConnectivityServiceProvider);
  return networkService.connectivityStream;
});

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final dataManager = ref.watch(localFirstDataManagerProvider);
  return dataManager.syncStatusStream;
});

/// Provider for sync conflicts
final syncConflictsProvider = StreamProvider<SyncConflict>((ref) {
  final dataManager = ref.watch(localFirstDataManagerProvider);
  return dataManager.conflictStream;
});

/// Provider for offline data statistics
final offlineDataStatsProvider = FutureProvider<OfflineDataStats>((ref) async {
  final dataManager = ref.watch(localFirstDataManagerProvider);
  return dataManager.getOfflineDataStats();
});

/// Provider for manual sync trigger
final manualSyncProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final dataManager = ref.watch(localFirstDataManagerProvider);
    await dataManager.syncAll();
  };
});

/// Provider for activity sync trigger
final activitySyncProvider = Provider<Future<void> Function(String)>((ref) {
  return (String activityId) async {
    final dataManager = ref.watch(localFirstDataManagerProvider);
    await dataManager.syncActivity(activityId);
  };
});

/// Provider for conflict resolution
final conflictResolutionProvider = Provider<Future<void> Function(SyncConflict, {bool preserveLocal})>((ref) {
  return (SyncConflict conflict, {bool preserveLocal = true}) async {
    final dataManager = ref.watch(localFirstDataManagerProvider);
    await dataManager.resolveConflict(conflict, preserveLocal: preserveLocal);
  };
});
