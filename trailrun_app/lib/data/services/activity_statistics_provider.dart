import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_statistics_service.dart';

/// Provider for the activity statistics service
final activityStatisticsServiceProvider = Provider<ActivityStatisticsService>((ref) {
  return ActivityStatisticsService();
});
