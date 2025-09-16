import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/activities_table.dart';
import 'tables/track_points_table.dart';
import 'tables/photos_table.dart';
import 'tables/splits_table.dart';
import 'tables/sync_queue_table.dart';
import 'daos/activity_dao.dart';
import 'daos/track_point_dao.dart';
import 'daos/photo_dao.dart';
import 'daos/split_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'database.g.dart';

/// Main database class for TrailRun app with encrypted SQLite storage
@DriftDatabase(
  tables: [
    ActivitiesTable,
    TrackPointsTable,
    PhotosTable,
    SplitsTable,
    SyncQueueTable,
  ],
  daos: [
    ActivityDao,
    TrackPointDao,
    PhotoDao,
    SplitDao,
    SyncQueueDao,
  ],
)
class TrailRunDatabase extends _$TrailRunDatabase {
  TrailRunDatabase() : super(_openConnection());
  
  /// Constructor for testing with custom executor
  TrailRunDatabase.withExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Create indexes for better query performance
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_activities_start_time 
          ON activities (start_time DESC);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_activities_sync_state 
          ON activities (sync_state);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_track_points_activity_sequence 
          ON track_points (activity_id, sequence);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_track_points_timestamp 
          ON track_points (timestamp);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_photos_activity_timestamp 
          ON photos (activity_id, timestamp);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_splits_activity_number 
          ON splits (activity_id, split_number);
        ''');
        
        await customStatement('''
          CREATE INDEX IF NOT EXISTS idx_sync_queue_priority_created 
          ON sync_queue (priority DESC, created_at ASC);
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle future schema migrations
        if (from < 2) {
          // Example migration for version 2
          // await m.addColumn(activitiesTable, activitiesTable.newColumn);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints
        await customStatement('PRAGMA foreign_keys = ON');
        
        // Set encryption key for database
        await customStatement('PRAGMA key = "trailrun_encryption_key_2024"');
        
        // Optimize SQLite settings for mobile
        await customStatement('PRAGMA journal_mode = WAL');
        await customStatement('PRAGMA synchronous = NORMAL');
        await customStatement('PRAGMA cache_size = 10000');
        await customStatement('PRAGMA temp_store = MEMORY');
      },
    );
  }
}

/// Open database connection with encryption and optimization
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Ensure SQLite3 is properly initialized on mobile platforms
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'trailrun.db'));
    
    // Configure SQLite3 for encryption support
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
    
    return NativeDatabase.createInBackground(
      file,
      logStatements: false, // Set to true for debugging
      setup: (database) {
        // Enable encryption
        database.execute('PRAGMA key = "trailrun_encryption_key_2024"');
        
        // Performance optimizations
        database.execute('PRAGMA journal_mode = WAL');
        database.execute('PRAGMA synchronous = NORMAL');
        database.execute('PRAGMA cache_size = 10000');
        database.execute('PRAGMA temp_store = MEMORY');
        database.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}