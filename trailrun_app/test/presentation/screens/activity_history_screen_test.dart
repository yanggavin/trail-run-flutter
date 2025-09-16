import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:trailrun_app/presentation/screens/activity_history_screen.dart';
import 'package:trailrun_app/presentation/providers/activity_history_provider.dart';
import 'package:trailrun_app/domain/repositories/activity_repository.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/enums/sync_state.dart';

import 'activity_history_screen_test.mocks.dart';

@GenerateMocks([ActivityRepository])
void main() {
  group('ActivityHistoryScreen', () {
    late MockActivityRepository mockRepository;

    setUp(() {
      mockRepository = MockActivityRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      );
    }

    testWidgets('displays loading indicator initially', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no activities', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No activities found'), findsOneWidget);
      expect(find.text('Start tracking your first run!'), findsOneWidget);
    });

    testWidgets('displays activities when loaded', (tester) async {
      final testActivity = Activity(
        id: 'test_1',
        startTime: Timestamp(DateTime.now().subtract(const Duration(hours: 1))),
        endTime: Timestamp(DateTime.now()),
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

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Run'), findsOneWidget);
      expect(find.text('5.0km'), findsOneWidget);
    });

    testWidgets('search functionality works', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'test search');
      await tester.pumpAndSettle();

      // Verify search query is applied
      verify(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: argThat(
          predicate<ActivityFilter?>((filter) => 
            filter?.searchText == 'test search'),
          named: 'filter',
        ),
        sortBy: anyNamed('sortBy'),
      )).called(greaterThan(0));
    });

    testWidgets('pull to refresh works', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Perform pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify refresh was called
      verify(mockRepository.getActivities(
        page: 0,
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).called(greaterThan(1));
    });

    testWidgets('filter button opens filter sheet', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap filter button
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);

      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify filter sheet is shown
      expect(find.text('Filter Activities'), findsOneWidget);
    });

    testWidgets('sort menu works', (tester) async {
      when(mockRepository.getActivities(
        page: anyNamed('page'),
        pageSize: anyNamed('pageSize'),
        filter: anyNamed('filter'),
        sortBy: anyNamed('sortBy'),
      )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap sort button
      final sortButton = find.byIcon(Icons.sort);
      expect(sortButton, findsOneWidget);

      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Verify sort options are shown
      expect(find.text('Newest First'), findsOneWidget);
      expect(find.text('Oldest First'), findsOneWidget);
      expect(find.text('Longest Distance'), findsOneWidget);
    });
  });
}