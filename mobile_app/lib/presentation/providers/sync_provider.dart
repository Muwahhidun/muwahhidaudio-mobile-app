import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/sync/sync_service.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/logger.dart';
import '../../config/app_constants.dart';

/// Sync state
class SyncState {
  final bool isSyncing;
  final String? currentStep;
  final String? error;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isSyncing = false,
    this.currentStep,
    this.error,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isSyncing,
    String? currentStep,
    String? error,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      currentStep: currentStep ?? this.currentStep,
      error: error ?? this.error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

/// Sync notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService = SyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription<bool>? _connectivitySubscription;

  SyncNotifier() : super(const SyncState()) {
    _initConnectivityListener();
    _autoSyncOnStart();
  }

  /// Auto-sync on provider initialization (app start)
  Future<void> _autoSyncOnStart() async {
    // Wait a bit for auth provider to initialize
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is authenticated
    final isAuth = await _isAuthenticated();
    if (!isAuth) {
      logger.i('User not authenticated, skipping auto-sync on start');
      return;
    }

    // Check if internet is available
    final hasInternet = await _connectivityService.hasInternet();
    if (!hasInternet) {
      logger.i('No internet, skipping auto-sync on start');
      return;
    }

    // Check if we need initial sync or background sync
    final needsSync = await _syncService.needsInitialSync();
    if (needsSync) {
      logger.i('Auto-sync on start: performing initial sync');
      await performInitialSync();
    } else {
      logger.i('Auto-sync on start: performing background sync');
      await performBackgroundSync();
    }
  }

  /// Check if user is authenticated (has access token)
  Future<bool> _isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Initialize connectivity listener
  void _initConnectivityListener() {
    logger.i('Initializing connectivity listener for auto-sync...');
    _connectivityService.startListening();

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (hasInternet) async {
        logger.i('Connectivity changed in SyncNotifier: hasInternet=$hasInternet');

        if (hasInternet) {
          // Check if user is authenticated before syncing
          final isAuthenticated = await _isAuthenticated();
          if (!isAuthenticated) {
            logger.i('User not authenticated, skipping auto-sync');
            return;
          }

          // Internet restored - check if we need to sync
          final needsSync = await _syncService.needsInitialSync();

          if (needsSync) {
            logger.i('Internet restored and cache is empty - auto-syncing...');
            await performInitialSync();
          } else {
            logger.i('Internet restored but cache exists - performing background sync...');
            await performBackgroundSync();
          }
        }
      },
      onError: (error) {
        logger.e('Error in connectivity listener', error: error);
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.stopListening();
    super.dispose();
  }

  /// Perform initial sync (blocking, for first launch)
  Future<bool> performInitialSync() async {
    if (state.isSyncing) {
      logger.w('Sync already in progress');
      return false;
    }

    // Check internet
    final hasInternet = await _connectivityService.hasInternet();
    if (!hasInternet) {
      state = state.copyWith(
        error: 'Для первого запуска требуется подключение к интернету',
      );
      return false;
    }

    state = state.copyWith(
      isSyncing: true,
      error: null,
      currentStep: 'Начало синхронизации...',
    );

    try {
      final result = await _syncService.syncAllData(
        onProgress: (step) {
          state = state.copyWith(currentStep: step);
        },
      );

      if (result.success) {
        state = state.copyWith(
          isSyncing: false,
          currentStep: null,
          lastSyncTime: DateTime.now(),
        );
        logger.i('Initial sync completed successfully');
        return true;
      } else {
        state = state.copyWith(
          isSyncing: false,
          error: result.message,
          currentStep: null,
        );
        logger.e('Initial sync failed: ${result.message}');
        return false;
      }
    } catch (e, stackTrace) {
      logger.e('Initial sync exception', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isSyncing: false,
        error: 'Ошибка синхронизации: ${e.toString()}',
        currentStep: null,
      );
      return false;
    }
  }

  /// Perform background sync (non-blocking, for subsequent launches)
  Future<void> performBackgroundSync() async {
    if (state.isSyncing) {
      logger.w('Sync already in progress');
      return;
    }

    // Check internet
    final hasInternet = await _connectivityService.hasInternet();
    if (!hasInternet) {
      logger.i('No internet, skipping background sync');
      return;
    }

    // Don't update UI state for background sync (silent)
    logger.i('Starting background sync...');

    try {
      final result = await _syncService.syncAllData();

      if (result.success) {
        // Update last sync time silently
        state = state.copyWith(lastSyncTime: DateTime.now());
        logger.i('Background sync completed successfully');
      } else {
        logger.w('Background sync failed: ${result.message}');
      }
    } catch (e, stackTrace) {
      logger.e('Background sync exception', error: e, stackTrace: stackTrace);
    }
  }

  /// Check if initial sync is needed
  Future<bool> needsInitialSync() async {
    return await _syncService.needsInitialSync();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force re-sync (from settings)
  Future<bool> forceResync() async {
    await _syncService.clearCacheAndResync();
    return await performInitialSync();
  }
}

/// Sync provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

/// Helper provider to check if needs initial sync
final needsInitialSyncProvider = FutureProvider<bool>((ref) async {
  final syncService = SyncService();
  return await syncService.needsInitialSync();
});

/// Helper provider to check internet connectivity
final hasInternetProvider = FutureProvider<bool>((ref) async {
  final connectivityService = ConnectivityService();
  return await connectivityService.hasInternet();
});
