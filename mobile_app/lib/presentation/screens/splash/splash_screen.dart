import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/gradient_background.dart';
import '../../providers/sync_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/logger.dart';

/// Splash screen shown while checking authentication and syncing data
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _syncChecked = false;

  @override
  void initState() {
    super.initState();
    // Check and perform sync if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSync();
    });
  }

  Future<void> _checkAndSync() async {
    if (_syncChecked) return;
    _syncChecked = true;

    // Sync is now handled automatically by SyncProvider on initialization
    // Just wait for auth to complete
    try {
      // Wait for auth provider to finish loading
      var authState = ref.read(authProvider);
      while (authState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        authState = ref.read(authProvider);
      }

      logger.i('Auth check complete, isAuthenticated=${authState.isAuthenticated}');
    } catch (e, stackTrace) {
      logger.e('Error during auth check', error: e, stackTrace: stackTrace);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка синхронизации'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry sync
              setState(() {
                _syncChecked = false;
              });
              _checkAndSync();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon or logo
              Icon(
                Icons.headphones,
                size: 100,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 24),
              // App title
              Text(
                'Исламские аудио уроки',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              // Show sync progress if syncing
              if (syncState.isSyncing && syncState.currentStep != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    syncState.currentStep!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
