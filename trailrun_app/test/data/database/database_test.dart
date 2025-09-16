import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:trailrun_app/data/database/database.dart';

void main() {
  late TrailRunDatabase database;

  setUp(() {
    database = TrailRunDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('TrailRunDatabase', () {
    test('should create database and tables', () async {
      // Act - just accessing the database should create tables
      final activityDao = database.activityDao;
      final trackPointDao = database.trackPointDao;
      final photoDao = database.photoDao;
      final splitDao = database.splitDao;
      final syncQueueDao = database.syncQueueDao;

      // Assert - DAOs should be accessible
      expect(activityDao, isNotNull);
      expect(trackPointDao, isNotNull);
      expect(photoDao, isNotNull);
      expect(splitDao, isNotNull);
      expect(syncQueueDao, isNotNull);
    });

    test('should get empty counts initially', () async {
      // Act
      final activityCount = await database.activityDao.getActivitiesCount();
      final trackPointCount = await database.trackPointDao.getTrackPointsCount('test-activity');
      final photoCount = await database.photoDao.getPhotosCount('test-activity');
      final syncQueueCount = await database.syncQueueDao.getSyncOperationsCount();

      // Assert
      expect(activityCount, equals(0));
      expect(trackPointCount, equals(0));
      expect(photoCount, equals(0));
      expect(syncQueueCount, equals(0));
    });
  });
}