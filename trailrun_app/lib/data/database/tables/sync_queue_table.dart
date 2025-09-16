import 'package:drift/drift.dart';

/// Database table for managing sync operations queue
@DataClassName('SyncQueueEntity')
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  /// Unique identifier for the sync operation
  TextColumn get id => text()();

  /// Type of entity to sync (activity, photo, etc.)
  TextColumn get entityType => text().named('entity_type')();

  /// ID of the entity to sync
  TextColumn get entityId => text().named('entity_id')();

  /// Type of operation (create, update, delete)
  TextColumn get operation => text()();

  /// JSON payload for the sync operation
  TextColumn get payload => text()();

  /// Priority of the sync operation (higher number = higher priority)
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Number of retry attempts made
  IntColumn get retryCount => integer().named('retry_count').withDefault(const Constant(0))();

  /// Maximum number of retry attempts allowed
  IntColumn get maxRetries => integer().named('max_retries').withDefault(const Constant(3))();

  /// When this sync operation was created (milliseconds since epoch)
  IntColumn get createdAt => integer().named('created_at')();

  /// When this sync operation was last attempted (milliseconds since epoch, nullable if never attempted)
  IntColumn get lastAttemptAt => integer().named('last_attempt_at').nullable()();

  /// When to next attempt this sync operation (milliseconds since epoch)
  IntColumn get nextAttemptAt => integer().named('next_attempt_at')();

  /// Error message from last failed attempt (nullable if no error)
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (entity_type IN ("activity", "photo", "split", "track_point"))',
    'CHECK (operation IN ("create", "update", "delete"))',
    'CHECK (priority >= 0)',
    'CHECK (retry_count >= 0)',
    'CHECK (max_retries >= 0)',
    'CHECK (retry_count <= max_retries)',
    'CHECK (created_at > 0)',
    'CHECK (next_attempt_at > 0)',
    'CHECK (last_attempt_at IS NULL OR last_attempt_at > 0)',
  ];
}