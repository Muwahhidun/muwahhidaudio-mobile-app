import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

/// Offline mode indicator for AppBar
/// Shows a badge when device is offline
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);

    // Don't show anything while checking initial status
    if (connectivityState.isChecking) {
      return const SizedBox.shrink();
    }

    // Only show indicator when offline
    if (connectivityState.hasInternet) {
      return const SizedBox.shrink();
    }

    // Show offline badge
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        avatar: const Icon(
          Icons.cloud_off,
          size: 16,
          color: Colors.white70,
        ),
        label: const Text(
          'Offline',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
