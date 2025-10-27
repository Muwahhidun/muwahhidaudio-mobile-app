import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/models/lesson.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific media session integration using browser's Media Session API
/// Only works on web platform
class MediaSessionWeb {
  static html.MediaSession? get _mediaSession {
    if (!kIsWeb) return null;
    return html.window.navigator.mediaSession;
  }

  /// Update media metadata for browser controls
  static void updateMetadata({
    required Lesson lesson,
    String? artworkUrl,
  }) {
    if (!kIsWeb) return;

    final session = _mediaSession;
    if (session == null) return;

    // Build title: "Книга - Урок X"
    String title = 'Урок ${lesson.lessonNumber}';
    if (lesson.book != null) {
      title = '${lesson.book!.name} - Урок ${lesson.lessonNumber}';
    }

    // Artist: Teacher name
    String artist = lesson.teacher?.name ?? 'Лектор';

    // Album: Series name
    String album = 'Аудиоуроки';
    if (lesson.series != null) {
      album = lesson.series!.displayName;
    }

    // Set metadata
    session.metadata = html.MediaMetadata({
      'title': title,
      'artist': artist,
      'album': album,
      'artwork': [
        {
          'src': 'assets/icons/app_icon.png',
          'sizes': '512x512',
          'type': 'image/png',
        }
      ]
    });
  }

  /// Set action handlers for media session controls
  static void setActionHandlers({
    Function? onPlay,
    Function? onPause,
    Function? onSeekBackward,
    Function? onSeekForward,
    Function? onPreviousTrack,
    Function? onNextTrack,
    Function(Duration)? onSeek,
  }) {
    if (!kIsWeb) return;

    final session = _mediaSession;
    if (session == null) return;

    // Register play handler
    if (onPlay != null) {
      session.setActionHandler('play', () {
        onPlay();
      });
    }

    // Register pause handler
    if (onPause != null) {
      session.setActionHandler('pause', () {
        onPause();
      });
    }

    // Register seek backward handler (10 seconds)
    if (onSeekBackward != null) {
      session.setActionHandler('seekbackward', () {
        onSeekBackward();
      });
    }

    // Register seek forward handler (10 seconds)
    if (onSeekForward != null) {
      session.setActionHandler('seekforward', () {
        onSeekForward();
      });
    }

    // Register previous track handler
    if (onPreviousTrack != null) {
      session.setActionHandler('previoustrack', () {
        onPreviousTrack();
      });
    }

    // Register next track handler
    if (onNextTrack != null) {
      session.setActionHandler('nexttrack', () {
        onNextTrack();
      });
    }

    // Note: seekto handler requires more complex implementation with JS interop
    // Skipping for now as basic controls are sufficient
  }

  /// Update playback state (playing/paused)
  static void updatePlaybackState({required bool isPlaying}) {
    if (!kIsWeb) return;

    final session = _mediaSession;
    if (session == null) return;

    session.playbackState = isPlaying ? 'playing' : 'paused';
  }

  /// Update position state for seeking
  /// Note: dart:html doesn't expose setPositionState, would need JS interop
  static void updatePositionState({
    required Duration duration,
    required Duration position,
    required double playbackRate,
  }) {
    if (!kIsWeb) return;
    // Skip for now - requires more complex JS interop
    // Most browsers update position automatically from audio element
  }

  /// Clear all action handlers
  static void clearHandlers() {
    if (!kIsWeb) return;

    final session = _mediaSession;
    if (session == null) return;

    session.setActionHandler('play', null);
    session.setActionHandler('pause', null);
    session.setActionHandler('seekbackward', null);
    session.setActionHandler('seekforward', null);
    session.setActionHandler('previoustrack', null);
    session.setActionHandler('nexttrack', null);
    session.setActionHandler('seekto', null);
  }
}
