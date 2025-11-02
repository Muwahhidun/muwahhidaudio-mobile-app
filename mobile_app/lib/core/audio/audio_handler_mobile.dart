import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/lesson.dart';
import '../download/download_manager.dart';
import '../logger.dart';

/// Audio handler for mobile background playback
/// Integrates just_audio with audio_service for background playback
class LessonAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final DownloadManager _downloadManager = DownloadManager();

  Lesson? _currentLesson;
  List<Lesson> _playlist = [];
  String _baseUrl = '';

  AudioPlayer get player => _player;
  Lesson? get currentLesson => _currentLesson;
  List<Lesson> get playlist => _playlist;

  // Stream for current lesson changes
  final _currentLessonController = StreamController<Lesson?>.broadcast();
  Stream<Lesson?> get currentLessonStream => _currentLessonController.stream;

  LessonAudioHandler() {
    _init();
  }

  void _init() async {
    // Request notification permission for Android 13+
    await _requestNotificationPermission();

    // Set initial playback state for Android 12+ notification
    playbackState.add(PlaybackState(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: [
        MediaControl.play,
      ],
      systemActions: const {
        MediaAction.seek,
      },
    ));

    // Listen to player state changes and update audio_service state
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      // Convert just_audio processing state to audio_service state
      AudioProcessingState state;
      switch (processingState) {
        case ProcessingState.idle:
          state = AudioProcessingState.idle;
          break;
        case ProcessingState.loading:
          state = AudioProcessingState.loading;
          break;
        case ProcessingState.buffering:
          state = AudioProcessingState.buffering;
          break;
        case ProcessingState.ready:
          state = AudioProcessingState.ready;
          break;
        case ProcessingState.completed:
          state = AudioProcessingState.completed;
          break;
      }

      // Update audio_service state
      playbackState.add(playbackState.value.copyWith(
        playing: isPlaying,
        processingState: state,
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          const MediaControl(
            androidIcon: 'drawable/ic_action_cancel',
            label: 'Закрыть',
            action: MediaAction.stop,
          ),
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ));
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ));
    });
  }

  /// Load a lesson without starting playback
  Future<void> loadLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
    required String baseUrl,
  }) async {
    _currentLesson = lesson;
    _playlist = playlist;
    _baseUrl = baseUrl;

    // Notify listeners
    _currentLessonController.add(lesson);

    // Check if lesson is downloaded locally
    final localFilePath = await _downloadManager.getLocalFilePath(lesson.id);

    String audioUrl;
    if (localFilePath != null) {
      // Play from local file
      audioUrl = localFilePath;
      logger.i('AudioHandler: Loading audio from local file: $audioUrl');
    } else {
      // Stream from server
      audioUrl = lesson.audioUrl!.startsWith('http')
          ? lesson.audioUrl!
          : '$baseUrl${lesson.audioUrl}';
      logger.i('AudioHandler: Streaming audio from server: $audioUrl');
    }

    // Update media item for notification
    final mediaItemData = MediaItem(
      id: lesson.id.toString(),
      title: lesson.book != null
          ? '${lesson.book!.name} - Урок ${lesson.lessonNumber}'
          : 'Урок ${lesson.lessonNumber}',
      artist: lesson.teacher?.name ?? 'Неизвестен',
      duration: lesson.durationSeconds != null
          ? Duration(seconds: lesson.durationSeconds!)
          : null,
    );
    logger.i('AudioHandler: Setting MediaItem - title: ${mediaItemData.title}, artist: ${mediaItemData.artist}');
    mediaItem.add(mediaItemData);

    // Load audio
    await _player.setUrl(audioUrl);

    // Set initial playback state with controls after loading media
    playbackState.add(PlaybackState(
      playing: false,
      processingState: AudioProcessingState.ready,
      controls: [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        const MediaControl(
          androidIcon: 'drawable/ic_action_cancel',
          label: 'Закрыть',
          action: MediaAction.stop,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
    ));
  }

  /// Play a lesson with playlist context
  Future<void> playLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
    required String baseUrl,
  }) async {
    await loadLesson(
      lesson: lesson,
      playlist: playlist,
      baseUrl: baseUrl,
    );
    await play();
  }

  @override
  Future<void> play() async {
    logger.i('AudioHandler: play() called');
    logger.i('AudioHandler: Current MediaItem: ${mediaItem.value?.title}');
    logger.i('AudioHandler: Current PlaybackState: playing=${playbackState.value.playing}, processingState=${playbackState.value.processingState}');

    // Ensure initial playback state is set
    if (playbackState.value.processingState == AudioProcessingState.idle) {
      logger.i('AudioHandler: Setting initial playback state');
      playbackState.add(PlaybackState(
        playing: true,
        processingState: AudioProcessingState.ready,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          const MediaControl(
            androidIcon: 'drawable/ic_action_cancel',
            label: 'Закрыть',
            action: MediaAction.stop,
          ),
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ));
    }
    logger.i('AudioHandler: Starting player.play()');
    await _player.play();
    logger.i('AudioHandler: player.play() completed');
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    logger.i('AudioHandler: stop() called - stopping playback and closing notification');

    await _player.stop();
    _currentLesson = null;
    _currentLessonController.add(null);

    // Clear media item
    mediaItem.add(null);

    // Update state to stopped with no controls
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      controls: [], // Remove all controls
    ));

    // Close foreground service and notification
    await super.stop();
    logger.i('AudioHandler: Notification closed');
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    final currentIndex = _playlist.indexOf(_currentLesson!);
    if (currentIndex >= 0 && currentIndex < _playlist.length - 1) {
      await playLesson(
        lesson: _playlist[currentIndex + 1],
        playlist: _playlist,
        baseUrl: _baseUrl,
      );
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _playlist.indexOf(_currentLesson!);
    if (currentIndex > 0) {
      await playLesson(
        lesson: _playlist[currentIndex - 1],
        playlist: _playlist,
        baseUrl: _baseUrl,
      );
    }
  }

  @override
  Future<void> fastForward() async {
    final duration = _player.duration ?? Duration.zero;
    final newPosition = _player.position + const Duration(seconds: 10);
    await _player.seek(newPosition > duration ? duration : newPosition);
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Update playlist (for navigation)
  void updatePlaylist(List<Lesson> playlist) {
    _playlist = playlist;
  }

  /// Request notification permission for Android 13+
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _currentLessonController.close();
    await _player.dispose();
  }
}
