import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/logger.dart';

/// Connectivity state
class ConnectivityState {
  final bool hasInternet;
  final bool isChecking;

  const ConnectivityState({
    this.hasInternet = true,
    this.isChecking = true,
  });

  ConnectivityState copyWith({
    bool? hasInternet,
    bool? isChecking,
  }) {
    return ConnectivityState(
      hasInternet: hasInternet ?? this.hasInternet,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  /// Initialize connectivity monitoring
  Future<void> _init() async {
    // Check initial connectivity status
    final hasInternet = await _connectivityService.hasInternet();
    state = state.copyWith(
      hasInternet: hasInternet,
      isChecking: false,
    );
    logger.d('Initial connectivity status: $hasInternet');

    // Start listening to connectivity changes
    _connectivityService.startListening();
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (hasInternet) {
        logger.d('Connectivity changed in ConnectivityNotifier: $hasInternet');
        state = state.copyWith(hasInternet: hasInternet);
      },
      onError: (error) {
        logger.e('Error in connectivity listener', error: error);
      },
    );
  }

  /// Manually refresh connectivity status
  Future<void> refresh() async {
    state = state.copyWith(isChecking: true);
    final hasInternet = await _connectivityService.checkInternetNow();
    state = state.copyWith(
      hasInternet: hasInternet,
      isChecking: false,
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.stopListening();
    super.dispose();
  }
}

/// Connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Helper provider for has internet status
final hasInternetProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).hasInternet;
});
