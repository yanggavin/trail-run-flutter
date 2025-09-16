import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailrun_app/presentation/providers/error_provider.dart';

void main() {
  group('ErrorProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty state', () {
      final state = container.read(errorProvider);

      expect(state.currentError, null);
      expect(state.errorHistory, isEmpty);
      expect(state.isShowingError, false);
    });

    test('should show error', () {
      final notifier = container.read(errorProvider.notifier);
      final error = AppError(
        type: ErrorType.network,
        message: 'Network error',
        timestamp: DateTime.now(),
      );
      
      notifier.showError(error);
      
      final state = container.read(errorProvider);
      expect(state.currentError, error);
      expect(state.isShowingError, true);
      expect(state.errorHistory, contains(error));
    });

    test('should show error message', () {
      final notifier = container.read(errorProvider.notifier);
      
      notifier.showErrorMessage(
        'Test error',
        type: ErrorType.location,
        details: 'Error details',
      );
      
      final state = container.read(errorProvider);
      expect(state.currentError?.message, 'Test error');
      expect(state.currentError?.type, ErrorType.location);
      expect(state.currentError?.details, 'Error details');
      expect(state.isShowingError, true);
    });

    test('should clear current error', () {
      final notifier = container.read(errorProvider.notifier);
      
      notifier.showErrorMessage('Test error');
      expect(container.read(errorProvider).currentError, isNotNull);
      
      notifier.clearCurrentError();
      
      final state = container.read(errorProvider);
      expect(state.currentError, null);
      expect(state.isShowingError, false);
    });

    test('should dismiss error', () {
      final notifier = container.read(errorProvider.notifier);
      
      notifier.showErrorMessage('Test error');
      expect(container.read(errorProvider).isShowingError, true);
      
      notifier.dismissError();
      
      final state = container.read(errorProvider);
      expect(state.isShowingError, false);
      expect(state.currentError, isNotNull); // Error still exists, just not showing
    });

    test('should maintain error history', () {
      final notifier = container.read(errorProvider.notifier);
      
      notifier.showErrorMessage('Error 1');
      notifier.showErrorMessage('Error 2');
      notifier.showErrorMessage('Error 3');
      
      final state = container.read(errorProvider);
      expect(state.errorHistory.length, 3);
      expect(state.errorHistory[0].message, 'Error 1');
      expect(state.errorHistory[1].message, 'Error 2');
      expect(state.errorHistory[2].message, 'Error 3');
    });

    test('should limit error history to 10 items', () {
      final notifier = container.read(errorProvider.notifier);
      
      // Add 12 errors
      for (int i = 1; i <= 12; i++) {
        notifier.showErrorMessage('Error $i');
      }
      
      final state = container.read(errorProvider);
      expect(state.errorHistory.length, 10);
      expect(state.errorHistory.first.message, 'Error 3'); // First two should be removed
      expect(state.errorHistory.last.message, 'Error 12');
    });

    test('should clear all errors', () {
      final notifier = container.read(errorProvider.notifier);
      
      notifier.showErrorMessage('Error 1');
      notifier.showErrorMessage('Error 2');
      
      notifier.clearAllErrors();
      
      final state = container.read(errorProvider);
      expect(state.currentError, null);
      expect(state.errorHistory, isEmpty);
      expect(state.isShowingError, false);
    });
  });

  group('ErrorHandler', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle AppError directly through notifier', () {
      final error = AppError(
        type: ErrorType.camera,
        message: 'Camera error',
      );
      
      container.read(errorProvider.notifier).showError(error);
      
      final state = container.read(errorProvider);
      expect(state.currentError, error);
    });

    test('should handle error message directly through notifier', () {
      container.read(errorProvider.notifier).showErrorMessage(
        'Network connection failed',
        type: ErrorType.network,
      );
      
      final state = container.read(errorProvider);
      expect(state.currentError?.type, ErrorType.network);
      expect(state.currentError?.message, 'Network connection failed');
    });

    test('should handle location error type', () {
      container.read(errorProvider.notifier).showErrorMessage(
        'GPS signal lost',
        type: ErrorType.location,
      );
      
      final state = container.read(errorProvider);
      expect(state.currentError?.type, ErrorType.location);
    });

    test('should handle general error type', () {
      container.read(errorProvider.notifier).showErrorMessage(
        'Unknown error',
        type: ErrorType.general,
      );
      
      final state = container.read(errorProvider);
      expect(state.currentError?.type, ErrorType.general);
    });
  });
}