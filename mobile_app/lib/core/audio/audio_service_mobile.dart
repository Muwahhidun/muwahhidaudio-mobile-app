import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../data/models/lesson.dart';

/// Singleton audio service for mobile platforms (Android/iOS)
/// Provides persistent audio playback with background support via audio_session
class AudioServiceMobile {
  // Singleton instance
  static final AudioServiceMobile _instance = AudioServiceMobile._internal();
  factory AudioServiceMobile() => _instance;
  AudioServiceMobile._internal() {
    _initializeAudioSession();
  }

  // Audio player instance
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  // Current playback state
  Lesson? _currentLesson;
  List<Lesson> _playlist = [];

  // Stream for current lesson changes (like web version)
  final _currentLessonController = StreamController<Lesson?>.broadcast();
  Stream<Lesson?> get currentLessonStream => _currentLessonController.stream;

  // Getters
  AudioPlayer get player => _player;
  Lesson? get currentLesson => _currentLesson;
  List<Lesson> get playlist => _playlist;

  // Callback for when lesson completes
  void Function()? onLessonCompleted;

  /// Initialize audio session for background playback
  Future<void> _initializeAudioSession() async {
    if (_isInitialized) return;

    try {
      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle interruptions (phone calls, etc)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Pause when interrupted
          _player.pause();
        }
      });

      // Handle becoming noisy (headphones unplugged)
      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });

      _isInitialized = true;
      print('AudioServiceMobile: Initialized with audio_session');
    } catch (e) {
      print('AudioServiceMobile: Failed to initialize audio_session: $e');
      _isInitialized = false;
    }
  }

  /// Ensure audio session is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeAudioSession();
    }
  }

  /// Load a lesson without starting playback
  Future<void> loadLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
    required String baseUrl,
  }) async {
    await _ensureInitialized();

    _currentLesson = lesson;
    _playlist = playlist;

    // Notify listeners about lesson change
    _currentLessonController.add(lesson);

    // Build audio URL
    final audioUrl = lesson.audioUrl!.startsWith('http')
        ? lesson.audioUrl!
        : '$baseUrl${lesson.audioUrl}';

    print('AudioServiceMobile: Loading audio from $audioUrl');

    // Load but don't play
    await _player.setUrl(audioUrl);
  }

  /// Play a lesson with playlist context
  Future<void> playLesson({
    required Lesson lesson,
    required List<Lesson> playlist,
    required String baseUrl,
  }) async {
    await _ensureInitialized();

    _currentLesson = lesson;
    _playlist = playlist;

    // Notify listeners about lesson change
    _currentLessonController.add(lesson);

    // Build audio URL
    final audioUrl = lesson.audioUrl!.startsWith('http')
        ? lesson.audioUrl!
        : '$baseUrl${lesson.audioUrl}';

    print('AudioServiceMobile: Playing lesson ${lesson.id}');

    // Load and play
    await _player.setUrl(audioUrl);
    await _player.play();
  }

  /// Stop playback and clear current lesson
  Future<void> stop() async {
    await _player.stop();
    _currentLesson = null;
    _currentLessonController.add(null);
  }

  /// Update playlist (for navigation)
  void updatePlaylist(List<Lesson> playlist) {
    _playlist = playlist;
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Dispose (only call when app is closing)
  Future<void> dispose() async {
    _currentLessonController.close();
    await _player.dispose();
  }
}
