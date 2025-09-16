import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/activity.dart';
import '../screens/home_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/activity_summary_screen.dart';
import '../screens/activity_history_screen.dart';
import '../screens/activity_map_screen.dart';
import '../screens/privacy_settings_screen.dart';

/// App routes
class AppRoutes {
  static const String home = '/';
  static const String activityHistory = '/history';
  static const String activitySummary = '/activity';
  static const String activityMap = '/activity/map';
  static const String privacySettings = '/settings/privacy';
  static const String tracking = '/tracking';
}

/// Route arguments
class ActivityRouteArgs {
  const ActivityRouteArgs({required this.activity});
  final Activity activity;
}

/// App router configuration
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
        
      case AppRoutes.activityHistory:
        return MaterialPageRoute(
          builder: (_) => const ActivityHistoryScreen(),
          settings: settings,
        );
        
      case AppRoutes.activitySummary:
        final args = settings.arguments;
        if (args is ActivityRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => ActivitySummaryScreen(activity: args.activity),
            settings: settings,
          );
        }
        return _errorRoute(settings);
        
      case AppRoutes.activityMap:
        final args = settings.arguments;
        if (args is ActivityRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => ActivityMapScreen(activity: args.activity),
            settings: settings,
          );
        }
        return _errorRoute(settings);
        
      case AppRoutes.privacySettings:
        return MaterialPageRoute(
          builder: (_) => const PrivacySettingsScreen(),
          settings: settings,
        );
        
      case AppRoutes.tracking:
        return MaterialPageRoute(
          builder: (_) => const TrackingScreen(),
          settings: settings,
        );
        
      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Route not found: ${settings.name}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pushReplacementNamed(AppRoutes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}

/// Navigation helper
class AppNavigator {
  static void toHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  static void toActivityHistory(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.activityHistory);
  }

  static void toActivitySummary(BuildContext context, Activity activity) {
    Navigator.of(context).pushNamed(
      AppRoutes.activitySummary,
      arguments: ActivityRouteArgs(activity: activity),
    );
  }

  static void toActivityMap(BuildContext context, Activity activity) {
    Navigator.of(context).pushNamed(
      AppRoutes.activityMap,
      arguments: ActivityRouteArgs(activity: activity),
    );
  }

  static void toPrivacySettings(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.privacySettings);
  }

  static void toTracking(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.tracking);
  }

  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void backToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Deep link handler
class DeepLinkHandler {
  static Route<dynamic>? handleDeepLink(String link) {
    final uri = Uri.parse(link);
    
    switch (uri.path) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
        
      case '/history':
        return MaterialPageRoute(builder: (_) => const ActivityHistoryScreen());
        
      case '/settings/privacy':
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
        
      default:
        // Handle activity-specific deep links
        if (uri.path.startsWith('/activity/')) {
          final activityId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
          if (activityId != null) {
            // Return a route that will load the activity and navigate
            return MaterialPageRoute(
              builder: (context) => Consumer(
                builder: (context, ref, child) {
                  // This would need to be implemented to load activity by ID
                  // For now, navigate to home
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppNavigator.toHome(context);
                  });
                  return const HomeScreen();
                },
              ),
            );
          }
        }
        return null;
    }
  }
}

/// Provider for current route
final currentRouteProvider = StateProvider<String>((ref) => AppRoutes.home);

/// Provider for navigation history
final navigationHistoryProvider = StateProvider<List<String>>((ref) => [AppRoutes.home]);