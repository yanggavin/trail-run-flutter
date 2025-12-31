import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../database/daos/sync_queue_dao.dart';
import '../../domain/enums/sync_state.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/photo.dart';
import 'network_connectivity_service.dart';

/// Service for managing data synchronization with server
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final NetworkConnectivityService _networkService = NetworkConnectivityService();
  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();
  
  TrailRunDatabase? _database;
  SyncQueueDao? _syncQueueDao;
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  final StreamController<SyncConflict> _conflictController = StreamController<SyncConflict>.broadcast();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Stream of sync conflicts that need resolution
  Stream<SyncConflict> get conflictStream => _conflictController.stream;

  /// Current sync status
  SyncStatus get currentStatus => _currentStatus;
  SyncStatus _currentStatus = SyncStatus.idle;

  /// Last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize sync service
  Future<void> initialize({
    required TrailRunDatabase database,
    String? baseUrl,
    Map<String, String>? headers,
  }) async {
    _database = database;
    _syncQueueDao = database.syncQueueDao;
    
    // Load last sync time
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMillis = prefs.getInt('last_sync_time');
    if (lastSyncMillis != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
    
    // Configure Dio
    _dio.options.baseUrl = baseUrl ?? 'https://api.trailrun.app';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers.addAll(headers ?? {});

    // Initialize network service
    await _networkService.initialize();

    // Listen for network connectivity changes
    _networkService.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        _scheduleSyncCheck();
      }
    });

    // Start periodic sync checks
    _startPeriodicSync();
  }

  /// Start periodic sync checks
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_networkService.isConnected && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Schedule immediate sync check
  void _scheduleSyncCheck() {
    Timer(const Duration(seconds: 2), () {
      if (_networkService.isConnected && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Sync all pending operations
  Future<void> syncAll() async {
    if (_isSyncing || !_networkService.isConnected || _syncQueueDao == null) {
      return;
    }

    _isSyncing = true;
    _updateSyncStatus(SyncStatus.syncing);

    try {
      final pendingOperations = await _syncQueueDao!.getPendingSyncOperations();
      
      if (pendingOperations.isEmpty) {
        _updateSyncStatus(SyncStatus.idle);
        await _updateLastSyncTime();
        return;
      }

      int successCount = 0;
      int failureCount = 0;

      for (final operation in pendingOperations) {
        try {
          final success = await _syncOperation(operation);
          if (success) {
            await _syncQueueDao!.deleteSyncOperation(operation.id);
            successCount++;
          } else {
            await _handleSyncFailure(operation, 'Sync operation failed');
            failureCount++;
          }
        } catch (e) {
          await _handleSyncFailure(operation, e.toString());
          failureCount++;
        }

        // Add small delay between operations to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (failureCount == 0) {
        await _updateLastSyncTime();
      }

      _updateSyncStatus(failureCount > 0 ? SyncStatus.error : SyncStatus.idle);
    } catch (e) {
      _updateSyncStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync specific activity
  Future<void> syncActivity(String activityId) async {
    if (!_networkService.isConnected || _syncQueueDao == null) {
      return;
    }

    final operations = await _syncQueueDao!.getSyncOperationsByType('activity');
    final activityOperations = operations.where((op) => op.entityId == activityId).toList();

    for (final operation in activityOperations) {
      try {
        final success = await _syncOperation(operation);
        if (success) {
          await _syncQueueDao!.deleteSyncOperation(operation.id);
        } else {
          await _handleSyncFailure(operation, 'Activity sync failed');
        }
      } catch (e) {
        await _handleSyncFailure(operation, e.toString());
      }
    }
  }

  /// Perform individual sync operation
  Future<bool> _syncOperation(SyncQueueEntity operation) async {
    try {
      switch (operation.entityType) {
        case 'activity':
          return await _syncActivityOperation(operation);
        case 'photo':
          return await _syncPhotoOperation(operation);
        case 'track_point':
          return await _syncTrackPointOperation(operation);
        case 'split':
          return await _syncSplitOperation(operation);
        default:
          throw UnsupportedError('Unknown entity type: ${operation.entityType}');
      }
    } catch (e) {
      if (e is DioException) {
        // Handle specific HTTP errors
        if (e.response?.statusCode == 409) {
          // Conflict - trigger conflict resolution
          await _handleSyncConflict(operation, e.response?.data);
          return false;
        } else if (e.response?.statusCode == 404 && operation.operation == 'update') {
          // Entity not found on server, convert to create operation
          return await _convertUpdateToCreate(operation);
        }
      }
      rethrow;
    }
  }

  /// Sync activity operation
  Future<bool> _syncActivityOperation(SyncQueueEntity operation) async {
    final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
    
    switch (operation.operation) {
      case 'create':
        final response = await _dio.post('/activities', data: payload);
        return response.statusCode == 201;
      case 'update':
        final response = await _dio.put('/activities/${operation.entityId}', data: payload);
        return response.statusCode == 200;
      case 'delete':
        final response = await _dio.delete('/activities/${operation.entityId}');
        return response.statusCode == 204;
      default:
        return false;
    }
  }

  /// Sync photo operation
  Future<bool> _syncPhotoOperation(SyncQueueEntity operation) async {
    final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
    
    switch (operation.operation) {
      case 'create':
        // For photos, we need to upload the file as well
        final formData = FormData.fromMap(payload);
        final response = await _dio.post('/photos', data: formData);
        return response.statusCode == 201;
      case 'update':
        final response = await _dio.put('/photos/${operation.entityId}', data: payload);
        return response.statusCode == 200;
      case 'delete':
        final response = await _dio.delete('/photos/${operation.entityId}');
        return response.statusCode == 204;
      default:
        return false;
    }
  }

  /// Sync track point operation
  Future<bool> _syncTrackPointOperation(SyncQueueEntity operation) async {
    final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
    
    switch (operation.operation) {
      case 'create':
        final response = await _dio.post('/track-points', data: payload);
        return response.statusCode == 201;
      case 'update':
        final response = await _dio.put('/track-points/${operation.entityId}', data: payload);
        return response.statusCode == 200;
      case 'delete':
        final response = await _dio.delete('/track-points/${operation.entityId}');
        return response.statusCode == 204;
      default:
        return false;
    }
  }

  /// Sync split operation
  Future<bool> _syncSplitOperation(SyncQueueEntity operation) async {
    final payload = jsonDecode(operation.payload) as Map<String, dynamic>;
    
    switch (operation.operation) {
      case 'create':
        final response = await _dio.post('/splits', data: payload);
        return response.statusCode == 201;
      case 'update':
        final response = await _dio.put('/splits/${operation.entityId}', data: payload);
        return response.statusCode == 200;
      case 'delete':
        final response = await _dio.delete('/splits/${operation.entityId}');
        return response.statusCode == 204;
      default:
        return false;
    }
  }

  /// Handle sync failure with exponential backoff
  Future<void> _handleSyncFailure(SyncQueueEntity operation, String error) async {
    final newRetryCount = operation.retryCount + 1;
    
    if (newRetryCount >= operation.maxRetries) {
      // Max retries exceeded, mark as failed
      await _syncQueueDao!.updateSyncOperationRetry(
        id: operation.id,
        retryCount: newRetryCount,
        nextAttemptAt: DateTime.now().add(const Duration(days: 1)), // Try again tomorrow
        lastError: error,
      );
      return;
    }

    // Calculate exponential backoff delay
    final baseDelay = const Duration(minutes: 1);
    final exponentialDelay = Duration(
      milliseconds: baseDelay.inMilliseconds * pow(2, newRetryCount).toInt(),
    );
    
    // Add jitter to prevent thundering herd
    final jitter = Duration(
      milliseconds: Random().nextInt(exponentialDelay.inMilliseconds ~/ 4),
    );
    
    final nextAttempt = DateTime.now().add(exponentialDelay + jitter);

    await _syncQueueDao!.updateSyncOperationRetry(
      id: operation.id,
      retryCount: newRetryCount,
      nextAttemptAt: nextAttempt,
      lastError: error,
    );
  }

  /// Handle sync conflict
  Future<void> _handleSyncConflict(SyncQueueEntity operation, dynamic serverData) async {
    final conflict = SyncConflict(
      id: _uuid.v4(),
      entityType: operation.entityType,
      entityId: operation.entityId,
      operation: operation.operation,
      localData: jsonDecode(operation.payload),
      serverData: serverData,
      timestamp: DateTime.now(),
    );

    _conflictController.add(conflict);
  }

  /// Convert update operation to create operation when entity not found on server
  Future<bool> _convertUpdateToCreate(SyncQueueEntity operation) async {
    final createOperation = SyncQueueEntity(
      id: _uuid.v4(),
      entityType: operation.entityType,
      entityId: operation.entityId,
      operation: 'create',
      payload: operation.payload,
      priority: operation.priority,
      retryCount: 0,
      maxRetries: operation.maxRetries,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastAttemptAt: null,
      nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
      lastError: null,
    );

    await _syncQueueDao!.createSyncOperation(createOperation);
    await _syncQueueDao!.deleteSyncOperation(operation.id);
    
    return await _syncOperation(createOperation);
  }

  /// Resolve sync conflict with server-wins strategy
  Future<void> resolveConflict(SyncConflict conflict, {bool preserveLocal = true}) async {
    if (_syncQueueDao == null) return;

    try {
      // Server-wins strategy: accept server data
      if (conflict.serverData != null) {
        // Update local data with server data
        await _updateLocalDataWithServerData(conflict);
      }

      // If preserveLocal is true, create a new sync operation with local changes
      if (preserveLocal) {
        final preservedOperation = SyncQueueEntity(
          id: _uuid.v4(),
          entityType: conflict.entityType,
          entityId: '${conflict.entityId}_local_${DateTime.now().millisecondsSinceEpoch}',
          operation: 'create',
          payload: jsonEncode(conflict.localData),
          priority: 1, // Higher priority for preserved local changes
          retryCount: 0,
          maxRetries: 3,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          lastAttemptAt: null,
          nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
          lastError: null,
        );

        await _syncQueueDao!.createSyncOperation(preservedOperation);
      }

      // Remove the conflicted operation from sync queue
      await _syncQueueDao!.deleteSyncOperationsForEntity(
        entityType: conflict.entityType,
        entityId: conflict.entityId,
      );
    } catch (e) {
      // If conflict resolution fails, leave the operation in queue for retry
    }
  }

  /// Update local data with server data
  Future<void> _updateLocalDataWithServerData(SyncConflict conflict) async {
    // This would update the local database with server data
    // Implementation depends on the specific entity type
    switch (conflict.entityType) {
      case 'activity':
        // Update activity in local database
        break;
      case 'photo':
        // Update photo in local database
        break;
      // Add other entity types as needed
    }
  }

  /// Queue entity for sync
  Future<void> queueEntitySync({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    if (_syncQueueDao == null) return;

    final syncOperation = SyncQueueEntity(
      id: _uuid.v4(),
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: jsonEncode(data),
      priority: priority,
      retryCount: 0,
      maxRetries: 3,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastAttemptAt: null,
      nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
      lastError: null,
    );

    await _syncQueueDao!.createSyncOperation(syncOperation);

    // Trigger immediate sync if connected
    if (_networkService.isConnected && !_isSyncing) {
      _scheduleSyncCheck();
    }
  }

  /// Update sync status
  void _updateSyncStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    final now = DateTime.now();
    _lastSyncTime = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_time', now.millisecondsSinceEpoch);
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    _conflictController.close();
    _networkService.dispose();
  }
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  error,
}

/// Sync conflict data class
class SyncConflict {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> localData;
  final dynamic serverData;
  final DateTime timestamp;

  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.localData,
    required this.serverData,
    required this.timestamp,
  });
}