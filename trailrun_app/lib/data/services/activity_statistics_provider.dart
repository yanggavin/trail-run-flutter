import 'package:riverpod/riverpod.dart';

import 'activity_statistics_service.dart';

/// Provider for the activity statistics service
final activityStatisticsServiceProvider = Provider<ActivityStatisticsService>((ref) {
  return ActivityStatisticsService();
});