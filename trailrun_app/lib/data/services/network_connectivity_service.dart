import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity status
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        await _checkConnectivity();
      },
    );
  }

  /// Check current connectivity and update status
  Future<void> _checkConnectivity() async {
    try {
      final ConnectivityResult connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if connection type is available
      final hasConnection = connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.ethernet;

      // Perform actual internet connectivity test if connection is detected
      bool actualConnectivity = false;
      if (hasConnection) {
        actualConnectivity = await _testInternetConnectivity();
      }

      if (_isConnected != actualConnectivity) {
        _isConnected = actualConnectivity;
        _connectivityController.add(_isConnected);
      }
    } catch (e) {
      // If connectivity check fails, assume no connection
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
      }
    }
  }

  /// Test actual internet connectivity by attempting to reach a reliable host
  Future<bool> _testInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Manually trigger connectivity check
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  /// Wait for network connectivity to become available
  Future<void> waitForConnectivity({Duration? timeout}) async {
    if (_isConnected) return;

    final completer = Completer<void>();
    late StreamSubscription<bool> subscription;

    subscription = connectivityStream.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        completer.complete();
      }
    });

    if (timeout != null) {
      return completer.future.timeout(timeout, onTimeout: () {
        subscription.cancel();
        throw TimeoutException('Network connectivity timeout', timeout);
      });
    }

    return completer.future;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}