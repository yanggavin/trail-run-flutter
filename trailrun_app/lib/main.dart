import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TrailRunApp(),
    ),
  );
}