import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/activity_repository.dart';
import '../providers/activity_history_provider.dart';
import '../widgets/activity_preview_card.dart';
import '../widgets/activity_filter_sheet.dart';

/// Screen for displaying activity history with search and filtering
class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(activityHistoryProvider.notifier).loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          PopupMenuButton<ActivitySortBy>(
            icon: const Icon(Icons.sort),
            onSelected: (sortBy) {
              ref.read(activityHistoryProvider.notifier).updateSortBy(sortBy);
            },
            itemBuilder: (context) => [
              _buildSortMenuItem(ActivitySortBy.startTimeDesc, 'Newest First', state.sortBy),
              _buildSortMenuItem(ActivitySortBy.startTimeAsc, 'Oldest First', state.sortBy),
              _buildSortMenuItem(ActivitySortBy.distanceDesc, 'Longest Distance', state.sortBy),
              _buildSortMenuItem(ActivitySortBy.distanceAsc, 'Shortest Distance', state.sortBy),
              _buildSortMenuItem(ActivitySortBy.durationDesc, 'Longest Duration', state.sortBy),
              _buildSortMenuItem(ActivitySortBy.durationAsc, 'Shortest Duration', state.sortBy),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Filter chips (if any filters are active)
          if (state.filter != null || state.searchQuery.isNotEmpty)
            _buildActiveFilters(state),
          
          // Activity list
          Expanded(
            child: _buildActivityList(state),
          ),
        ],
      ),
    );
  }  
Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search activities...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(activityHistoryProvider.notifier).updateSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (query) {
          ref.read(activityHistoryProvider.notifier).updateSearchQuery(query);
        },
      ),
    );
  }

  Widget _buildActiveFilters(ActivityHistoryState state) {
    final filters = <Widget>[];
    
    if (state.searchQuery.isNotEmpty) {
      filters.add(
        Chip(
          label: Text('Search: "${state.searchQuery}"'),
          onDeleted: () {
            _searchController.clear();
            ref.read(activityHistoryProvider.notifier).updateSearchQuery('');
          },
        ),
      );
    }
    
    if (state.filter != null) {
      final filter = state.filter!;
      
      if (filter.startDate != null || filter.endDate != null) {
        String dateText = 'Date: ';
        if (filter.startDate != null && filter.endDate != null) {
          dateText += '${_formatDate(filter.startDate!)} - ${_formatDate(filter.endDate!)}';
        } else if (filter.startDate != null) {
          dateText += 'After ${_formatDate(filter.startDate!)}';
        } else {
          dateText += 'Before ${_formatDate(filter.endDate!)}';
        }
        
        filters.add(
          Chip(
            label: Text(dateText),
            onDeleted: () => _removeFilter('date'),
          ),
        );
      }
      
      if (filter.minDistance != null || filter.maxDistance != null) {
        String distanceText = 'Distance: ';
        if (filter.minDistance != null && filter.maxDistance != null) {
          distanceText += '${(filter.minDistance! / 1000).toStringAsFixed(1)} - ${(filter.maxDistance! / 1000).toStringAsFixed(1)}km';
        } else if (filter.minDistance != null) {
          distanceText += '> ${(filter.minDistance! / 1000).toStringAsFixed(1)}km';
        } else {
          distanceText += '< ${(filter.maxDistance! / 1000).toStringAsFixed(1)}km';
        }
        
        filters.add(
          Chip(
            label: Text(distanceText),
            onDeleted: () => _removeFilter('distance'),
          ),
        );
      }
      
      if (filter.hasPhotos != null) {
        filters.add(
          Chip(
            label: Text(filter.hasPhotos! ? 'Has Photos' : 'No Photos'),
            onDeleted: () => _removeFilter('photos'),
          ),
        );
      }
    }
    
    if (filters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Active Filters:'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(activityHistoryProvider.notifier).clearFilters();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: filters,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActivityList(ActivityHistoryState state) {
    if (state.isLoading && state.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(activityHistoryProvider.notifier).loadActivities(reset: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (state.activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No activities found'),
            SizedBox(height: 8),
            Text(
              'Start tracking your first run!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(activityHistoryProvider.notifier).refreshActivities();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.activities.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.activities.length) {
            // Loading indicator at bottom
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          final activity = state.activities[index];
          return ActivityPreviewCard(
            activity: activity,
            onDelete: () {
              ref.read(activityHistoryProvider.notifier).deleteActivity(activity.id);
            },
          );
        },
      ),
    );
  }

  PopupMenuItem<ActivitySortBy> _buildSortMenuItem(
    ActivitySortBy sortBy,
    String title,
    ActivitySortBy currentSort,
  ) {
    return PopupMenuItem(
      value: sortBy,
      child: Row(
        children: [
          if (sortBy == currentSort)
            const Icon(Icons.check, size: 20)
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ActivityFilterSheet(
        initialFilter: ref.read(activityHistoryProvider).filter,
        onApplyFilter: (filter) {
          ref.read(activityHistoryProvider.notifier).updateFilter(filter);
        },
      ),
    );
  }

  void _removeFilter(String filterType) {
    final currentFilter = ref.read(activityHistoryProvider).filter;
    if (currentFilter == null) return;
    
    ActivityFilter? newFilter;
    
    switch (filterType) {
      case 'date':
        newFilter = ActivityFilter(
          minDistance: currentFilter.minDistance,
          maxDistance: currentFilter.maxDistance,
          hasPhotos: currentFilter.hasPhotos,
          privacyLevels: currentFilter.privacyLevels,
        );
        break;
      case 'distance':
        newFilter = ActivityFilter(
          startDate: currentFilter.startDate,
          endDate: currentFilter.endDate,
          hasPhotos: currentFilter.hasPhotos,
          privacyLevels: currentFilter.privacyLevels,
        );
        break;
      case 'photos':
        newFilter = ActivityFilter(
          startDate: currentFilter.startDate,
          endDate: currentFilter.endDate,
          minDistance: currentFilter.minDistance,
          maxDistance: currentFilter.maxDistance,
          privacyLevels: currentFilter.privacyLevels,
        );
        break;
    }
    
    // Check if the new filter has any criteria, if not, set to null
    if (newFilter != null &&
        newFilter.startDate == null &&
        newFilter.endDate == null &&
        newFilter.minDistance == null &&
        newFilter.maxDistance == null &&
        newFilter.hasPhotos == null &&
        (newFilter.privacyLevels?.isEmpty ?? true)) {
      newFilter = null;
    }
    
    ref.read(activityHistoryProvider.notifier).updateFilter(newFilter);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}