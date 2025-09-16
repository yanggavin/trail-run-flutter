import 'dart:io';

/// Test runner for the TrailRun app integration tests
/// 
/// This script orchestrates the execution of all integration tests
/// and provides comprehensive validation of the complete system.
void main(List<String> args) async {
  print('🏃‍♂️ TrailRun App - Final Integration Test Runner');
  print('================================================');
  
  final testSuites = [
    'test/integration/complete_tracking_workflow_test.dart',
    'test/integration/offline_functionality_test.dart', 
    'test/integration/sync_behavior_test.dart',
    'test/integration/battery_performance_validation_test.dart',
    'test/integration/final_integration_test_suite.dart',
  ];
  
  var allTestsPassed = true;
  final results = <String, bool>{};
  
  print('Running ${testSuites.length} integration test suites...\n');
  
  for (final testSuite in testSuites) {
    print('📋 Running: ${testSuite.split('/').last}');
    
    try {
      final result = await Process.run(
        'flutter',
        ['test', testSuite, '--verbose'],
        workingDirectory: '.',
      );
      
      final passed = result.exitCode == 0;
      results[testSuite] = passed;
      
      if (passed) {
        print('✅ PASSED: ${testSuite.split('/').last}');
      } else {
        print('❌ FAILED: ${testSuite.split('/').last}');
        print('Error output: ${result.stderr}');
        allTestsPassed = false;
      }
      
    } catch (e) {
      print('❌ ERROR running ${testSuite.split('/').last}: $e');
      results[testSuite] = false;
      allTestsPassed = false;
    }
    
    print('');
  }
  
  // Print summary
  print('📊 Test Results Summary');
  print('======================');
  
  for (final entry in results.entries) {
    final status = entry.value ? '✅ PASSED' : '❌ FAILED';
    print('$status: ${entry.key.split('/').last}');
  }
  
  print('');
  
  if (allTestsPassed) {
    print('🎉 ALL INTEGRATION TESTS PASSED!');
    print('✅ Complete tracking workflow validated');
    print('✅ Offline functionality verified');
    print('✅ Sync behavior confirmed');
    print('✅ Battery and performance targets met');
    print('✅ System integration successful');
    print('');
    print('🚀 TrailRun app is ready for deployment!');
  } else {
    print('⚠️  SOME TESTS FAILED');
    print('Please review the failed tests and fix issues before deployment.');
    exit(1);
  }
}