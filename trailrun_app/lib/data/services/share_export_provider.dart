import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_export_service.dart';
import 'share_card_generator.dart';

/// Provider for ShareExportService
final shareExportServiceProvider = Provider<ShareExportService>((ref) {
  return ShareExportService();
});

/// Provider for ShareCardGenerator
final shareCardGeneratorProvider = Provider<ShareCardGenerator>((ref) {
  return ShareCardGenerator();
});