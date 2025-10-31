import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/lesson.dart';
import '../../config/api_config.dart';

/// Audio handler for background audio playback
/// Integrates audio_service with just_audio
class LessonAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  // Playlist management
  List<Lesson> _playlist = [];
  int _currentIndex = 0;

  // Playback speed
  double _playbackSpeed = 1.0;

  LessonAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to player state changes and update audio_service
    _player.playerStateStream.listen((state) {
      _broadcastState();
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      _broadcastState();
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });

    // Auto-play next lesson when current finishes
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  /// Play a lesson with playlist context
  Future<void> playLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
  }) async {
    _playlist = playlist;
    _currentIndex = playlist.indexWhere((l) => l.id == lesson.id);

    if (_currentIndex == -1) {
      _currentIndex = 0;
    }

    await _playLessonAtIndex(_currentIndex);
  }

  Future<void> _playLessonAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final lesson = _playlist[index];
    _currentIndex = index;

    // Build MediaItem for system UI
    final mediaItem = _buildMediaItem(lesson);
    this.mediaItem.add(mediaItem);

    // Set audio source
    final audioUrl = '${ApiConfig.baseUrl}${lesson.audioUrl}';
    await _player.setUrl(audioUrl);

    // Set playback speed
    await _player.setSpeed(_playbackSpeed);

    // Start playing
    await _player.play();

    _broadcastState();
  }

  MediaItem _buildMediaItem(Lesson lesson) {
    // Build title: "Книга - Урок X"
    String title = 'Урок ${lesson.lessonNumber}';
    if (lesson.book != null) {
      title = '${lesson.book!.name} - Урок ${lesson.lessonNumber}';
    }

    // Artist: Teacher name
    String artist = lesson.teacher?.name ?? 'Лектор';

    // Album: Series name (from breadcrumbs or series)
    String album = 'Аудиоуроки';
    if (lesson.series != null) {
      album = lesson.series!.displayName;
    }

    return MediaItem(
      id: lesson.id.toString(),
      title: title,
      artist: artist,
      album: album,
      duration: lesson.durationSeconds != null
          ? Duration(seconds: lesson.durationSeconds!)
          : null,
      // Don't use artUri as it may cause initialization errors
      artUri: null,
    );
  }

  void _broadcastState() {
    final playing = _player.playing;
    final processingState = _mapProcessingState(_player.processingState);

    playbackState.add(playbackState.value.copyWith(
      controls: _getControls(),
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  List<MediaControl> _getControls() {
    final playing = _player.playing;

    return [
      // Previous
      if (_currentIndex > 0)
        MediaControl(
          androidIcon: 'drawable/ic_skip_previous',
          label: 'Previous',
          action: MediaAction.skipToPrevious,
        ),

      // Rewind 10s
      MediaControl(
        androidIcon: 'drawable/ic_rewind',
        label: 'Rewind',
        action: MediaAction.rewind,
      ),

      // Play/Pause
      if (playing)
        MediaControl(
          androidIcon: 'drawable/ic_pause',
          label: 'Pause',
          action: MediaAction.pause,
        )
      else
        MediaControl(
          androidIcon: 'drawable/ic_play_arrow',
          label: 'Play',
          action: MediaAction.play,
        ),

      // Forward 10s
      MediaControl(
        androidIcon: 'drawable/ic_fast_forward',
        label: 'Forward',
        action: MediaAction.fastForward,
      ),

      // Next
      if (_currentIndex < _playlist.length - 1)
        MediaControl(
          androidIcon: 'drawable/ic_skip_next',
          label: 'Next',
          action: MediaAction.skipToNext,
        ),
    ];
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _playlist.length - 1) {
      await _playLessonAtIndex(_currentIndex + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      await _playLessonAtIndex(_currentIndex - 1);
    }
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
    _broadcastState();
  }

  @override
  Future<void> fastForward() async {
    final duration = _player.duration ?? Duration.zero;
    final newPosition = _player.position + const Duration(seconds: 10);
    await _player.seek(newPosition > duration ? duration : newPosition);
    _broadcastState();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    _broadcastState();
  }

  @override
  Future<void> onTaskRemoved() async {
    // Stop playback when app is swiped away
    await stop();
  }

  /// Get current audio player for UI synchronization
  AudioPlayer get player => _player;

  /// Get current playlist
  List<Lesson> get playlist => _playlist;

  /// Get current index
  int get currentIndex => _currentIndex;
}
