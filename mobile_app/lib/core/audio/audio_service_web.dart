import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../data/models/lesson.dart';
import '../../config/api_config.dart';
import 'media_session_web.dart';

/// Singleton audio service for web platform
/// Keeps audio playing even when navigating away from player screen
class AudioServiceWeb {
  static final AudioServiceWeb _instance = AudioServiceWeb._internal();
  factory AudioServiceWeb() => _instance;
  AudioServiceWeb._internal() {
    _initializeListeners();
  }

  final AudioPlayer _player = AudioPlayer();
  List<Lesson> _playlist = [];
  int _currentIndex = 0;
  Lesson? _currentLesson;
  double _playbackSpeed = 1.0;

  // Stream for current lesson changes
  final _currentLessonController = StreamController<Lesson?>.broadcast();
  Stream<Lesson?> get currentLessonStream => _currentLessonController.stream;

  // Stream subscriptions
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

  // Callback when lesson completes (for auto-play next)
  Function()? onLessonCompleted;

  AudioPlayer get player => _player;
  Lesson? get currentLesson => _currentLesson;
  List<Lesson> get playlist => _playlist;
  int get currentIndex => _currentIndex;

  /// Update playlist without changing playback
  void updatePlaylist(List<Lesson> newPlaylist) {
    _playlist = newPlaylist;
  }

  void _initializeListeners() {
    // Listen for playback state changes (only once)
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      MediaSessionWeb.updatePlaybackState(isPlaying: state.playing);

      // Auto-play next on completion
      if (state.processingState == ProcessingState.completed) {
        if (_currentIndex < _playlist.length - 1) {
          skipToNext();
          onLessonCompleted?.call();
        }
      }
    });

    // Update position state (only once)
    _positionSubscription = _player.positionStream.listen((position) {
      final duration = _player.duration ?? Duration.zero;
      MediaSessionWeb.updatePositionState(
        duration: duration,
        position: position,
        playbackRate: _player.speed,
      );
    });
  }

  Future<void> playLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
  }) async {
    _playlist = playlist;
    final requestedIndex = playlist.indexWhere((l) => l.id == lesson.id);

    // If this lesson is already playing, don't restart it
    if (_currentLesson?.id == lesson.id && _player.playing) {
      // Just update the index in case playlist changed
      _currentIndex = requestedIndex;
      return;
    }

    _currentLesson = lesson;
    _currentIndex = requestedIndex;

    if (_currentIndex == -1) {
      _currentIndex = 0;
    }

    await _playLessonAtIndex(_currentIndex);
  }

  Future<void> _playLessonAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final lesson = _playlist[index];
    _currentLesson = lesson;
    _currentIndex = index;

    // Notify listeners about lesson change
    _currentLessonController.add(lesson);

    // Set audio source
    final audioUrl = '${ApiConfig.baseUrl}${lesson.audioUrl}';
    await _player.setUrl(audioUrl);

    // Set playback speed
    await _player.setSpeed(_playbackSpeed);

    // Start playing
    await _player.play();

    // Update web media session
    MediaSessionWeb.updateMetadata(lesson: lesson);
    _setupMediaSessionHandlers();
  }

  void _setupMediaSessionHandlers() {
    MediaSessionWeb.setActionHandlers(
      onPlay: () => _player.play(),
      onPause: () => _player.pause(),
      onSeekBackward: () {
        final newPosition = _player.position - const Duration(seconds: 10);
        _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
      },
      onSeekForward: () {
        final duration = _player.duration ?? Duration.zero;
        final newPosition = _player.position + const Duration(seconds: 10);
        _player.seek(newPosition > duration ? duration : newPosition);
      },
      onPreviousTrack: _currentIndex > 0 ? skipToPrevious : null,
      onNextTrack: _currentIndex < _playlist.length - 1 ? skipToNext : null,
      onSeek: (position) => _player.seek(position),
    );
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
  }

  Future<void> skipToNext() async {
    if (_currentIndex < _playlist.length - 1) {
      await _playLessonAtIndex(_currentIndex + 1);
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      await _playLessonAtIndex(_currentIndex - 1);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentLesson = null;
    _currentLessonController.add(null);
    MediaSessionWeb.clearHandlers();
  }

  void dispose() {
    // Cancel stream subscriptions
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();

    // Close stream controller
    _currentLessonController.close();

    // Dispose player
    _player.dispose();

    // Clear media session
    MediaSessionWeb.clearHandlers();
  }
}
