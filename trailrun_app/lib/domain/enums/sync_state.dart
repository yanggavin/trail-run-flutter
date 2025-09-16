/// Synchronization state for activities and related data
enum SyncState {
  /// Data exists only locally, not yet synced
  local,
  
  /// Data is queued for synchronization
  pending,
  
  /// Data is currently being synchronized
  syncing,
  
  /// Data has been successfully synchronized
  synced,
  
  /// Synchronization failed
  failed,
  
  /// Data has conflicts that need resolution
  conflict,
}

extension SyncStateExtension on SyncState {
  /// Human-readable name for the sync state
  String get displayName {
    switch (this) {
      case SyncState.local:
        return 'Local Only';
      case SyncState.pending:
        return 'Pending Sync';
      case SyncState.syncing:
        return 'Syncing';
      case SyncState.synced:
        return 'Synced';
      case SyncState.failed:
        return 'Sync Failed';
      case SyncState.conflict:
        return 'Sync Conflict';
    }
  }
  
  /// Icon representation for the sync state
  String get icon {
    switch (this) {
      case SyncState.local:
        return '📱';
      case SyncState.pending:
        return '⏳';
      case SyncState.syncing:
        return '🔄';
      case SyncState.synced:
        return '✅';
      case SyncState.failed:
        return '❌';
      case SyncState.conflict:
        return '⚠️';
    }
  }
  
  /// Whether this state indicates successful synchronization
  bool get isSynced => this == SyncState.synced;
  
  /// Whether this state indicates an error condition
  bool get hasError => this == SyncState.failed || this == SyncState.conflict;
  
  /// Whether this state indicates sync is in progress
  bool get isInProgress => this == SyncState.pending || this == SyncState.syncing;
  
  /// Whether this state requires user attention
  bool get requiresAttention => hasError;
}