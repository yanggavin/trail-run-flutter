import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/screens/home_screen.dart';
import 'package:trailrun_app/presentation/screens/activity_summary_screen.dart';
import '../domain/models/activity.dart';

class TrailRunApp extends StatelessWidget {
  const TrailRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'TrailRun',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/activity-summary': (context) {
            final activity = ModalRoute.of(context)?.settings.arguments;
            if (activity != null) {
              return ActivitySummaryScreen(activity: activity as Activity);
            }
            return const HomeScreen();
          },
        },
      ),
    );
  }
}