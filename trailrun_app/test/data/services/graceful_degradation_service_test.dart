import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';

import '../../../lib/data/services/graceful_degradation_service.dart';
import '../../../lib/data/services/platform_permission_service.dart';
import '../../../lib/data/services/location_service.dart';
import '../../../lib/data/services/camera_service.dart';

@GenerateMocks([
  PlatformPermissionService,
  LocationService,
  CameraService,
])
import 'graceful_degradation_service_test.mocks.dart';

void main() {
  group('GracefulDegradationService', () {
    late GracefulDegradationService degradationService;
    late MockPlatformPermissionService mockPermissionService;
    late MockLocationService mockLocationService;
    late MockCameraService mockCameraService;

    setUp(() {
      mockPermissionService = MockPlatformPermissionService();
      mockLocationService = MockLocationService();
      mockCameraService = MockCameraService();
      
      degradationService = GracefulDegradationService(
        permissionService: mockPermissionService,
        locationService: mockLocationService,
        cameraService: mockCameraService,
      );
    });

    group('getAppCapabilities', () {
      test('returns full functionality when all permissions granted', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final capabilities = await degradationService.getAppCapabilities();
        
        expect(capabilities.functionalityLevel, FunctionalityLevel.full);
        expect(capabilities.limitations, isEmpty);
        expect(capabilities.recommendations, contains('All features are available'));
      });

      test('returns limited functionality when some permissions denied', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => false);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final capabilities = await degradationService.getAppCapabilities();
        
        expect(capabilities.functionalityLevel, isNot(FunctionalityLevel.full));
        expect(capabilities.limitations, contains('Camera features are not available'));
        expect(capabilities.recommendations, contains('Grant camera permission to take photos during runs'));
      });

      test('returns minimal functionality when critical permissions denied', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => false);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => false);
        
        final capabilities = await degradationService.getAppCapabilities();
        
        expect(capabilities.functionalityLevel, FunctionalityLevel.minimal);
        expect(capabilities.limitations, isNotEmpty);
        expect(capabilities.recommendations, isNotEmpty);
      });

      test('handles errors gracefully', () async {
        when(mockPermissionService.hasCameraPermission()).thenThrow(Exception('Permission check failed'));
        
        final capabilities = await degradationService.getAppCapabilities();
        
        expect(capabilities.functionalityLevel, FunctionalityLevel.limited);
        expect(capabilities.limitations, contains('Unable to check app permissions and capabilities.'));
      });
    });

    group('getAlternativeFunctionality', () {
      test('provides location alternatives when location unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final alternatives = await degradationService.getAlternativeFunctionality();
        
        expect(alternatives.locationAlternatives, isNotEmpty);
        expect(alternatives.locationAlternatives.first.title, 'Manual Distance Entry');
        expect(alternatives.locationAlternatives.first.isAvailable, isTrue);
      });

      test('provides photo alternatives when camera unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final alternatives = await degradationService.getAlternativeFunctionality();
        
        expect(alternatives.photoAlternatives, isNotEmpty);
        expect(alternatives.photoAlternatives.first.title, 'Import Photos');
      });

      test('provides background alternatives when background tracking unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final alternatives = await degradationService.getAlternativeFunctionality();
        
        expect(alternatives.backgroundAlternatives, isNotEmpty);
        expect(alternatives.backgroundAlternatives.first.title, 'Keep Screen On');
      });
    });

    group('handlePermissionDenial', () {
      test('handles location permission denial correctly', () async {
        final response = await degradationService.handlePermissionDenial(
          PermissionType.location,
          false,
        );
        
        expect(response.title, 'Location Permission Required');
        expect(response.message, contains('TrailRun needs location permission'));
        expect(response.alternatives, isNotEmpty);
        expect(response.canRetry, isTrue);
        expect(response.settingsRequired, isFalse);
      });

      test('handles permanent location permission denial', () async {
        final response = await degradationService.handlePermissionDenial(
          PermissionType.location,
          true,
        );
        
        expect(response.title, 'Location Permission Required');
        expect(response.message, contains('permanently denied'));
        expect(response.canRetry, isFalse);
        expect(response.settingsRequired, isTrue);
      });

      test('handles camera permission denial correctly', () async {
        final response = await degradationService.handlePermissionDenial(
          PermissionType.camera,
          false,
        );
        
        expect(response.title, 'Camera Permission Required');
        expect(response.message, contains('camera permission to take photos'));
        expect(response.alternatives, contains('Add photos from gallery after your run'));
        expect(response.canRetry, isTrue);
      });

      test('handles storage permission denial correctly', () async {
        final response = await degradationService.handlePermissionDenial(
          PermissionType.storage,
          false,
        );
        
        expect(response.title, 'Storage Permission Required');
        expect(response.message, contains('storage permission to save'));
        expect(response.alternatives, contains('Use cloud sync only (if available)'));
        expect(response.canRetry, isTrue);
      });
    });

    group('getDegradedTrackingOptions', () {
      test('provides manual tracking when location unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final options = await degradationService.getDegradedTrackingOptions();
        
        expect(options.manualTracking, isNotNull);
        expect(options.manualTracking!.title, 'Manual Tracking');
        expect(options.manualTracking!.isRecommended, isTrue);
        expect(options.manualTracking!.limitations, contains('No route map'));
        expect(options.manualTracking!.benefits, contains('Still tracks time and pace'));
      });

      test('provides foreground tracking when background unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final options = await degradationService.getDegradedTrackingOptions();
        
        expect(options.foregroundOnlyTracking, isNotNull);
        expect(options.foregroundOnlyTracking!.title, 'Foreground Tracking');
        expect(options.foregroundOnlyTracking!.limitations, contains('Must keep app open'));
        expect(options.foregroundOnlyTracking!.benefits, contains('Full GPS tracking'));
      });

      test('provides photoless tracking when camera unavailable', () async {
        when(mockPermissionService.hasCameraPermission()).thenAnswer((_) async => true);
        when(mockPermissionService.hasStoragePermission()).thenAnswer((_) async => true);
        
        final options = await degradationService.getDegradedTrackingOptions();
        
        expect(options.photolessTracking, isNotNull);
        expect(options.photolessTracking!.title, 'Run Tracking Only');
        expect(options.photolessTracking!.limitations, contains('No in-run photos'));
        expect(options.photolessTracking!.benefits, contains('Full tracking features'));
      });
    });

    group('AppCapabilities', () {
      test('determines functionality level correctly', () {
        final service = GracefulDegradationService(
          permissionService: mockPermissionService,
          locationService: mockLocationService,
          cameraService: mockCameraService,
        );

        // Test full functionality
        var capabilities = AppCapabilities()
          ..canTrackLocation = true
          ..canTrackInBackground = true
          ..canTakePhotos = true
          ..canSaveData = true;
        
        expect(service._determineFunctionalityLevel(capabilities), FunctionalityLevel.full);

        // Test core functionality
        capabilities = AppCapabilities()
          ..canTrackLocation = true
          ..canTrackInBackground = false
          ..canTakePhotos = false
          ..canSaveData = true;
        
        expect(service._determineFunctionalityLevel(capabilities), FunctionalityLevel.core);

        // Test limited functionality
        capabilities = AppCapabilities()
          ..canTrackLocation = false
          ..canTrackInBackground = false
          ..canTakePhotos = false
          ..canSaveData = true;
        
        expect(service._determineFunctionalityLevel(capabilities), FunctionalityLevel.limited);

        // Test minimal functionality
        capabilities = AppCapabilities()
          ..canTrackLocation = false
          ..canTrackInBackground = false
          ..canTakePhotos = false
          ..canSaveData = false;
        
        expect(service._determineFunctionalityLevel(capabilities), FunctionalityLevel.minimal);
      });
    });

    group('PermissionDenialResponse', () {
      test('creates response with correct properties', () {
        const response = PermissionDenialResponse(
          title: 'Test Title',
          message: 'Test Message',
          alternatives: ['Alt 1', 'Alt 2'],
          canRetry: true,
          settingsRequired: false,
        );

        expect(response.title, 'Test Title');
        expect(response.message, 'Test Message');
        expect(response.alternatives, ['Alt 1', 'Alt 2']);
        expect(response.canRetry, isTrue);
        expect(response.settingsRequired, isFalse);
      });
    });

    group('AlternativeFeature', () {
      test('creates feature with correct properties', () {
        final feature = AlternativeFeature(
          title: 'Test Feature',
          description: 'Test Description',
          isAvailable: true,
          action: () async {},
        );

        expect(feature.title, 'Test Feature');
        expect(feature.description, 'Test Description');
        expect(feature.isAvailable, isTrue);
        expect(feature.action, isA<Function>());
      });
    });

    group('DegradedFeature', () {
      test('creates degraded feature with correct properties', () {
        const feature = DegradedFeature(
          title: 'Test Degraded',
          description: 'Test Description',
          isRecommended: true,
          limitations: ['Limit 1', 'Limit 2'],
          benefits: ['Benefit 1', 'Benefit 2'],
        );

        expect(feature.title, 'Test Degraded');
        expect(feature.description, 'Test Description');
        expect(feature.isRecommended, isTrue);
        expect(feature.limitations, ['Limit 1', 'Limit 2']);
        expect(feature.benefits, ['Benefit 1', 'Benefit 2']);
      });
    });
  });
}