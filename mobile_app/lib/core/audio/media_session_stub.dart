import '../../data/models/lesson.dart';

/// Stub implementation for non-web platforms
/// Media Session API is only available on web
class MediaSessionWeb {
  /// Update media metadata - no-op on non-web platforms
  static void updateMetadata({
    required Lesson lesson,
    String? artworkUrl,
  }) {
    // No-op on non-web platforms
  }

  /// Set action handlers - no-op on non-web platforms
  static void setActionHandlers({
    Function? onPlay,
    Function? onPause,
    Function? onSeekBackward,
    Function? onSeekForward,
    Function? onPreviousTrack,
    Function? onNextTrack,
    Function(Duration)? onSeek,
  }) {
    // No-op on non-web platforms
  }

  /// Update playback state - no-op on non-web platforms
  static void updatePlaybackState({required bool isPlaying}) {
    // No-op on non-web platforms
  }

  /// Update position state - no-op on non-web platforms
  static void updatePositionState({
    required Duration duration,
    required Duration position,
    required double playbackRate,
  }) {
    // No-op on non-web platforms
  }

  /// Clear all action handlers - no-op on non-web platforms
  static void clearHandlers() {
    // No-op on non-web platforms
  }
}
