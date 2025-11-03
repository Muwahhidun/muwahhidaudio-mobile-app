import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logger.dart';
import '../../config/api_config.dart';

/// Service for checking internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  bool? _lastKnownStatus;
  DateTime? _lastCheckTime;
  static const _cacheDuration = Duration(seconds: 5);

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _connectivityController = StreamController<bool>.broadcast();

  /// Check if device has internet connectivity
  /// Uses cached result if checked recently (within 5 seconds)
  Future<bool> hasInternet() async {
    // Return cached result if available and recent
    if (_lastKnownStatus != null &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
      return _lastKnownStatus!;
    }

    // Perform actual check
    final status = await _checkConnectivity();
    _lastKnownStatus = status;
    _lastCheckTime = DateTime.now();

    return status;
  }

  /// Force check internet connectivity (ignores cache)
  Future<bool> checkInternetNow() async {
    final status = await _checkConnectivity();
    _lastKnownStatus = status;
    _lastCheckTime = DateTime.now();
    return status;
  }

  /// Actual connectivity check implementation
  Future<bool> _checkConnectivity() async {
    try {
      // Method 1: Try to resolve a domain name (fast and reliable)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        logger.d('Internet connectivity: ONLINE (DNS lookup successful)');
        return true;
      }
    } catch (e) {
      // DNS lookup failed, try HTTP request to our backend
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ));

        // Try to ping our backend health endpoint (if exists) or any simple endpoint
        final response = await dio.get('${ApiConfig.baseUrl}/api/themes',
          queryParameters: {'limit': 1});

        if (response.statusCode == 200) {
          logger.d('Internet connectivity: ONLINE (backend reachable)');
          return true;
        }
      } catch (e) {
        // Both DNS and HTTP failed
        logger.d('Internet connectivity: OFFLINE');
        return false;
      }
    }

    logger.d('Internet connectivity: OFFLINE');
    return false;
  }

  /// Clear cached connectivity status (for testing)
  void clearCache() {
    _lastKnownStatus = null;
    _lastCheckTime = null;
  }

  /// Get last known status without checking
  bool? get lastKnownStatus => _lastKnownStatus;

  /// Stream of connectivity changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Start listening to connectivity changes
  void startListening() {
    if (_connectivitySubscription != null) {
      logger.w('Already listening to connectivity changes');
      return;
    }

    logger.i('Starting connectivity listener...');
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Check if any result is not none
        final hasConnection = results.any((result) => result != ConnectivityResult.none);

        logger.d('Connectivity changed: $results (hasConnection: $hasConnection)');

        // Actually check if we have real internet (not just WiFi/mobile connected)
        final previousStatus = _lastKnownStatus;
        final actualInternetStatus = await checkInternetNow();

        // Only emit if status actually changed
        if (previousStatus != null && previousStatus != actualInternetStatus) {
          logger.i('Internet status changed: $previousStatus -> $actualInternetStatus');
          _connectivityController.add(actualInternetStatus);
        }
      },
      onError: (error) {
        logger.e('Error listening to connectivity changes', error: error);
      },
    );
  }

  /// Stop listening to connectivity changes
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    logger.i('Stopped connectivity listener');
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _connectivityController.close();
  }
}
