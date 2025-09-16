import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/database/database_provider.dart';

/// State for activity history screen
class ActivityHistoryState {
  const ActivityHistoryState({
    this.activities = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.filter,
    this.sortBy = ActivitySortBy.startTimeDesc,
    this.searchQuery = '',
    this.error,
  });

  final List<Activity> activities;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int currentPage;
  final ActivityFilter? filter;
  final ActivitySortBy sortBy;
  final String searchQuery;
  final String? error;

  ActivityHistoryState copyWith({
    List<Activity>? activities,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    int? currentPage,
    ActivityFilter? filter,
    ActivitySortBy? sortBy,
    String? searchQuery,
    String? error,
  }) {
    return ActivityHistoryState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error ?? this.error,
    );
  }
}

/// Provider for activity repository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ActivityRepositoryImpl(database: database);
});

/// Provider for activity history state
final activityHistoryProvider = StateNotifierProvider<ActivityHistoryNotifier, ActivityHistoryState>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return ActivityHistoryNotifier(repository);
});

/// Notifier for managing activity history state
class ActivityHistoryNotifier extends StateNotifier<ActivityHistoryState> {
  ActivityHistoryNotifier(this._repository) : super(const ActivityHistoryState()) {
    _loadSortPreference();
    loadActivities();
  }

  final ActivityRepository _repository;
  static const int _pageSize = 20;
  static const String _sortPreferenceKey = 'activity_sort_preference';

  /// Load activities with current filters and pagination
  Future<void> loadActivities({bool reset = false}) async {
    if (reset) {
      state = state.copyWith(
        activities: [],
        currentPage: 0,
        hasMore: true,
        error: null,
      );
    }

    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final activities = await _repository.getActivities(
        page: state.currentPage,
        pageSize: _pageSize,
        filter: _buildCurrentFilter(),
        sortBy: state.sortBy,
      );

      final allActivities = reset 
          ? activities 
          : [...state.activities, ...activities];

      state = state.copyWith(
        activities: allActivities,
        isLoading: false,
        hasMore: activities.length == _pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh activities (pull-to-refresh)
  Future<void> refreshActivities() async {
    state = state.copyWith(isRefreshing: true);
    
    try {
      final activities = await _repository.getActivities(
        page: 0,
        pageSize: _pageSize,
        filter: _buildCurrentFilter(),
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        activities: activities,
        isRefreshing: false,
        currentPage: 1,
        hasMore: activities.length == _pageSize,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _debounceSearch();
  }

  /// Update filter
  void updateFilter(ActivityFilter? filter) {
    state = state.copyWith(filter: filter);
    loadActivities(reset: true);
  }

  /// Update sort option
  Future<void> updateSortBy(ActivitySortBy sortBy) async {
    state = state.copyWith(sortBy: sortBy);
    await _saveSortPreference(sortBy);
    loadActivities(reset: true);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      filter: null,
      searchQuery: '',
    );
    loadActivities(reset: true);
  }

  /// Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _repository.deleteActivity(activityId);
      
      // Remove from current list
      final updatedActivities = state.activities
          .where((activity) => activity.id != activityId)
          .toList();
      
      state = state.copyWith(activities: updatedActivities);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Build current filter including search query
  ActivityFilter? _buildCurrentFilter() {
    final baseFilter = state.filter;
    final searchQuery = state.searchQuery.trim();
    
    if (baseFilter == null && searchQuery.isEmpty) {
      return null;
    }
    
    return ActivityFilter(
      startDate: baseFilter?.startDate,
      endDate: baseFilter?.endDate,
      minDistance: baseFilter?.minDistance,
      maxDistance: baseFilter?.maxDistance,
      searchText: searchQuery.isEmpty ? null : searchQuery,
      hasPhotos: baseFilter?.hasPhotos,
      privacyLevels: baseFilter?.privacyLevels,
    );
  }

  /// Debounce search to avoid too many API calls
  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        loadActivities(reset: true);
      }
    });
  }

  /// Load sort preference from shared preferences
  Future<void> _loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortIndex = prefs.getInt(_sortPreferenceKey);
      if (sortIndex != null && sortIndex < ActivitySortBy.values.length) {
        state = state.copyWith(sortBy: ActivitySortBy.values[sortIndex]);
      }
    } catch (e) {
      // Ignore errors, use default sort
    }
  }

  /// Save sort preference to shared preferences
  Future<void> _saveSortPreference(ActivitySortBy sortBy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sortPreferenceKey, sortBy.index);
    } catch (e) {
      // Ignore errors
    }
  }
}