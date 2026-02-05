import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trailrun_app/presentation/widgets/share_export_sheet.dart';
import 'package:trailrun_app/data/services/share_export_service.dart';
import 'package:trailrun_app/data/services/share_card_generator.dart';
import 'package:trailrun_app/data/services/share_export_provider.dart';
import 'package:trailrun_app/domain/models/activity.dart';
import 'package:trailrun_app/domain/enums/privacy_level.dart';
import 'package:trailrun_app/domain/value_objects/timestamp.dart';
import 'package:trailrun_app/domain/value_objects/measurement_units.dart';

@GenerateMocks([ShareExportService, ShareCardGenerator])
import 'share_export_sheet_test.mocks.dart';

void main() {
  group('ShareExportSheet', () {
    late MockShareExportService mockShareService;
    late MockShareCardGenerator mockCardGenerator;
    late Activity testActivity;
    late Uint8List mockMapSnapshot;

    setUp(() {
      mockShareService = MockShareExportService();
      mockCardGenerator = MockShareCardGenerator();
      
      // Create mock map snapshot
      mockMapSnapshot = Uint8List.fromList([1, 2, 3, 4]);
      
      // Create test activity
      testActivity = Activity(
        id: 'activity1',
        startTime: Timestamp(DateTime(2024, 1, 15, 10, 0, 0)),
        endTime: Timestamp(DateTime(2024, 1, 15, 10, 30, 0)),
        title: 'Morning Trail Run',
        distance: Distance.meters(5000),
        elevationGain: Elevation.meters(200),
        privacy: PrivacyLevel.public,
      );
    });

    Widget createTestWidget({Uint8List? mapSnapshot}) {
      return ProviderScope(
        overrides: [
          shareExportServiceProvider.overrideWithValue(mockShareService),
          shareCardGeneratorProvider.overrideWithValue(mockCardGenerator),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ShareExportSheet(
              activity: testActivity,
              mapSnapshot: mapSnapshot,
            ),
          ),
        ),
      );
    }

    group('Widget Display', () {
      testWidgets('should display activity title and share options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Share & Export'), findsOneWidget);
        expect(find.text('Morning Trail Run'), findsOneWidget);
        expect(find.text('Share Activity'), findsOneWidget);
        expect(find.text('Share Card'), findsOneWidget);
        expect(find.text('Export GPX'), findsOneWidget);
        expect(find.text('Export Photos'), findsOneWidget);
      });

      testWidgets('should display correct icons for each option', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.share), findsOneWidget);
        expect(find.byIcon(Icons.image), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      });

      testWidgets('should show handle bar at top', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Look for the handle bar container
        final handleBar = find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final constraints = widget.constraints;
          return constraints != null &&
              constraints.minWidth == 40 &&
              constraints.maxWidth == 40 &&
              constraints.minHeight == 4 &&
              constraints.maxHeight == 4;
        });
        
        expect(handleBar, findsOneWidget);
      });
    });

    group('Share Activity', () {
      testWidgets('should call share service when share activity is tapped', (WidgetTester tester) async {
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(mapSnapshot: mockMapSnapshot));
        
        await tester.tap(find.text('Share Activity'));
        await tester.pump();

        verify(mockShareService.shareActivity(
          testActivity,
          mapSnapshot: mockMapSnapshot,
          includePhotos: true,
        )).called(1);
      });

      testWidgets('should show loading indicator during share', (WidgetTester tester) async {
        // Make the service call take some time
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Share Activity'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Wait for completion
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should show error message on share failure', (WidgetTester tester) async {
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenThrow(Exception('Share failed'));

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Share Activity'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to share activity: Exception: Share failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Share Card', () {
      testWidgets('should generate and share card when tapped', (WidgetTester tester) async {
        final mockCardBytes = Uint8List.fromList([5, 6, 7, 8]);
        
        when(mockCardGenerator.loadPhotoThumbnails(any))
            .thenAnswer((_) async => []);
        when(mockCardGenerator.renderShareCard(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          photoThumbnails: anyNamed('photoThumbnails'),
        )).thenAnswer((_) async => mockCardBytes);
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(mapSnapshot: mockMapSnapshot));
        
        await tester.tap(find.text('Share Card'));
        await tester.pumpAndSettle();

        verify(mockCardGenerator.loadPhotoThumbnails(testActivity.photos)).called(1);
        verify(mockCardGenerator.renderShareCard(
          testActivity,
          mapSnapshot: mockMapSnapshot,
          photoThumbnails: [],
        )).called(1);
        verify(mockShareService.shareActivity(
          testActivity,
          mapSnapshot: mockCardBytes,
          includePhotos: false,
        )).called(1);
      });

      testWidgets('should show error when card generation fails', (WidgetTester tester) async {
        when(mockCardGenerator.loadPhotoThumbnails(any))
            .thenAnswer((_) async => []);
        when(mockCardGenerator.renderShareCard(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          photoThumbnails: anyNamed('photoThumbnails'),
        )).thenAnswer((_) async => null);

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Share Card'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to generate share card'), findsOneWidget);
      });
    });

    group('Export GPX', () {
      testWidgets('should export GPX when tapped', (WidgetTester tester) async {
        final mockGpxFile = XFile('/test/activity.gpx');
        
        when(mockShareService.exportActivityAsGpx(any))
            .thenAnswer((_) async => mockGpxFile);

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Export GPX'));
        await tester.pumpAndSettle();

        verify(mockShareService.exportActivityAsGpx(testActivity)).called(1);
      });

      testWidgets('should show error when GPX export fails', (WidgetTester tester) async {
        when(mockShareService.exportActivityAsGpx(any))
            .thenThrow(Exception('GPX export failed'));

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Export GPX'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to export GPX: Exception: GPX export failed'), findsOneWidget);
      });
    });

    group('Export Photos', () {
      testWidgets('should export photos when tapped', (WidgetTester tester) async {
        final mockPhotoFiles = [XFile('/test/photo1.jpg'), XFile('/test/metadata.json')];
        
        when(mockShareService.exportPhotoBundle(any))
            .thenAnswer((_) async => mockPhotoFiles);

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Export Photos'));
        await tester.pumpAndSettle();

        verify(mockShareService.exportPhotoBundle(testActivity)).called(1);
      });

      testWidgets('should show error when no photos to export', (WidgetTester tester) async {
        final activityWithoutPhotos = testActivity.copyWith(photos: []);
        
        await tester.pumpWidget(ProviderScope(
          overrides: [
            shareExportServiceProvider.overrideWithValue(mockShareService),
            shareCardGeneratorProvider.overrideWithValue(mockCardGenerator),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ShareExportSheet(
                activity: activityWithoutPhotos,
              ),
            ),
          ),
        ));
        
        await tester.tap(find.text('Export Photos'));
        await tester.pumpAndSettle();

        expect(find.text('No photos to export'), findsOneWidget);
      });

      testWidgets('should show error when photo export fails', (WidgetTester tester) async {
        when(mockShareService.exportPhotoBundle(any))
            .thenThrow(Exception('Photo export failed'));

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Export Photos'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to export photos: Exception: Photo export failed'), findsOneWidget);
      });
    });

    group('UI State Management', () {
      testWidgets('should disable buttons during loading', (WidgetTester tester) async {
        // Make the service call take some time
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Share Activity'));
        await tester.pump();

        // All buttons should be disabled during loading
        final shareCardTile = tester.widget<ListTile>(
          find.ancestor(
            of: find.text('Share Card'),
            matching: find.byType(ListTile),
          ),
        );
        expect(shareCardTile.enabled, isFalse);
      });

      testWidgets('should clear error message when starting new operation', (WidgetTester tester) async {
        // First, cause an error
        when(mockShareService.shareActivity(
          any,
          mapSnapshot: anyNamed('mapSnapshot'),
          includePhotos: anyNamed('includePhotos'),
        )).thenThrow(Exception('First error'));

        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.text('Share Activity'));
        await tester.pumpAndSettle();

        expect(find.text('Failed to share activity: Exception: First error'), findsOneWidget);

        // Now try another operation - error should be cleared
        when(mockShareService.exportActivityAsGpx(any))
            .thenAnswer((_) async => XFile('/test/activity.gpx'));

        await tester.tap(find.text('Export GPX'));
        await tester.pump();

        expect(find.text('Failed to share activity: Exception: First error'), findsNothing);
      });
    });

    group('Helper Function', () {
      testWidgets('showShareExportSheet should display the sheet', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showShareExportSheet(context, testActivity),
                    child: const Text('Show Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Share & Export'), findsOneWidget);
        expect(find.text('Morning Trail Run'), findsOneWidget);
      });
    });
  });
}
