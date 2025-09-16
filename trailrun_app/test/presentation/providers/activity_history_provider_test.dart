import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:trailrun_app/presentation/providers/activity_history_provider.dart';
import 'package:trailrun_app/domain/repositories/activity_repository.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';

import 'activity_history_provider_test.mocks.dart';

@GenerateMocks([ActivityRepository])
void main() {
  group('ActivityHistoryProvider', () {
    late MockActivityRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockActivityRepository();
      container = ProviderContainer(
        overrides: [
          activityRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is correct', () {
      final state = container.read(activityHistoryProvider);
      
      expect(state.activities, isEmpty);
      expect(state.isLoading, false);
      expect(state.isRefreshing, false);
      expect(state.hasMore, true);
      expect(state.currentPage, 0);
      expect(state.filter, isNull);
      expect(state.sortBy, ActivitySortBy.startTimeDesc);
      expect(state.searchQuery, '');
      expect(state.error, isNull);
    });

    test('loadActivities updates state correctly', () async {
      final testActivity = Activity(
        id: 'test_1',
        startTime: Timestamp(DateTime.now()),
        title: 'Test Run',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(100),
        elevationLoss: Elevation.meters(50),
        privacy: PrivacyLevel.public,
        syncState: SyncState.synced,
        trackPoints: [],
        photos: [],
        splits: [],
      );

      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => [testActivity]);

      final notifier = container.read(activityHistoryProvider.notifier);
      await notifier.loadActivities();

      final state = container.read(activityHistoryProvider);
      expect(state.activities, hasLength(1));
      expect(state.activities.first.id, 'test_1');
      expect(state.isLoading, false);
      expect(state.currentPage, 1);
    });

    test('updateSearchQuery updates state and triggers load', () async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      final notifier = container.read(activityHistoryProvider.notifier);
      notifier.updateSearchQuery('test query');

      final state = container.read(activityHistoryProvider);
      expect(state.searchQuery, 'test query');
    });

    test('updateFilter updates state and reloads activities', () async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      final filter = ActivityFilter(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );

      final notifier = container.read(activityHistoryProvider.notifier);
      notifier.updateFilter(filter);

      final state = container.read(activityHistoryProvider);
      expect(state.filter, equals(filter));
    });

    test('updateSortBy updates state and reloads activities', () async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      final notifier = container.read(activityHistoryProvider.notifier);
      await notifier.updateSortBy(ActivitySortBy.distanceDesc);

      final state = container.read(activityHistoryProvider);
      expect(state.sortBy, ActivitySortBy.distanceDesc);
    });

    test('clearFilters resets filter and search query', () async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      final notifier = container.read(activityHistoryProvider.notifier);
      
      // Set some filters first
      notifier.updateSearchQuery('test');
      notifier.updateFilter(ActivityFilter(hasPhotos: true));
      
      // Clear filters
      notifier.clearFilters();

      final state = container.read(activityHistoryProvider);
      expect(state.filter, isNull);
      expect(state.searchQuery, '');
    });

    test('refreshActivities resets pagination and reloads', () async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      final notifier = container.read(activityHistoryProvider.notifier);
      await notifier.refreshActivities();

      verify(mockRepository.getActivities(
        page: 0,
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).called(1);

      final state = container.read(activityHistoryProvider);
      expect(state.currentPage, 1);
      expect(state.isRefreshing, false);
    });

    test('deleteActivity removes activity from list', () async {
      final testActivity = Activity(
        id: 'test_1',
        startTime: Timestamp(DateTime.now()),
        title: 'Test Run',
        distance: Distance.kilometers(5.0),
        elevationGain: Elevation.meters(100),
        elevationLoss: Elevation.meters(50),
        privacy: PrivacyLevel.public,
        syncState: SyncState.synced,
        trackPoints: [],
        photos: [],
        splits: [],
      );

      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => [testActivity]);

      when(mockRepository.deleteActivity('test_1')).thenAnswer((_) async {});

      final notifier = container.read(activityHistoryProvider.notifier);
      await notifier.loadActivities();
      
      // Verify activity is loaded
      var state = container.read(activityHistoryProvider);
      expect(state.activities, hasLength(1));

      // Delete activity
      await notifier.deleteActivity('test_1');

      // Verify activity is removed
      state = container.read(activityHistoryProvider);
      expect(state.activities, isEmpty);
    });
  });
}