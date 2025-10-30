import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import '../../widgets/breadcrumbs.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/bookmark.dart';
import '../../../data/api/dio_provider.dart';
import '../../../main.dart' as app;
import '../../../core/audio/audio_handler.dart';
import '../../../core/audio/audio_service_web.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

/// Enhanced Audio Player Screen with modern UI and animations
class PlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Lesson> playlist;
  final List<String> breadcrumbs;

  const PlayerScreen({
    super.key,
    required this.lesson,
    this.playlist = const [],
    required this.breadcrumbs,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  String? _error;
  double _playbackSpeed = 1.0;
  late AnimationController _pulseController;

  // Bookmark state
  Bookmark? _bookmark;
  bool _loadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializePlayer();
    _loadBookmark();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    app.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    setState(() {
      _loadingBookmark = true;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/bookmarks/check/${widget.lesson.id}');

      if (response.data != null && response.data is Map) {
        try {
          // Try to parse the bookmark
          final data = response.data as Map<String, dynamic>;
          // Remove the nested lesson object to avoid parsing issues
          data.remove('lesson');
          final bookmark = Bookmark.fromJson(data);

          setState(() {
            _bookmark = bookmark;
            _loadingBookmark = false;
          });
        } catch (parseError) {
          print('Error parsing bookmark: $parseError');
          setState(() {
            _bookmark = null;
            _loadingBookmark = false;
          });
        }
      } else {
        setState(() {
          _bookmark = null;
          _loadingBookmark = false;
        });
      }
    } catch (e) {
      print('Error loading bookmark: $e');
      setState(() {
        _loadingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final dio = DioProvider.getDio();
      final response = await dio.post(
        '/bookmarks/toggle',
        data: {
          'lesson_id': widget.lesson.id,
          'custom_name': null,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final action = data['action'] as String;

      setState(() {
        if (action == 'added') {
          _bookmark = Bookmark.fromJson(data['bookmark'] as Map<String, dynamic>);
        } else {
          _bookmark = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'added'
                  ? 'Добавлено в закладки'
                  : 'Удалено из закладок',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (kIsWeb) {
        // Web: Use singleton AudioServiceWeb for persistent playback
        final audioService = AudioServiceWeb();

        // Just connect to the player, don't start playing automatically
        _audioPlayer = audioService.player;

        // Update playlist reference in case user navigates to different series
        audioService.updatePlaylist(widget.playlist);

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }

        // Set callback for auto-play next when lesson completes
        audioService.onLessonCompleted = () {
          // Navigate to next lesson screen
          if (mounted) {
            _playNextLesson();
          }
        };
      } else {
        // Mobile: Use AudioHandler for background playback
        final handler = app.audioHandler as LessonAudioHandler;
        await handler.playLesson(
          lesson: widget.lesson,
          playlist: widget.playlist,
        );

        // Get the underlying player for UI updates
        _audioPlayer = handler.player;

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }

        // Listen for completion to play next
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted && state.processingState == ProcessingState.completed) {
            _playNextLesson();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки аудио: $e';
        });
      }
    }
  }

  void _playNextLesson() {
    final currentIndex = widget.playlist.indexOf(widget.lesson);
    if (currentIndex >= 0 && currentIndex < widget.playlist.length - 1) {
      final nextLesson = widget.playlist[currentIndex + 1];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            lesson: nextLesson,
            playlist: widget.playlist,
            breadcrumbs: widget.breadcrumbs,
          ),
        ),
      );
    }
  }

  void _playPreviousLesson() {
    final currentIndex = widget.playlist.indexOf(widget.lesson);
    if (currentIndex > 0) {
      final previousLesson = widget.playlist[currentIndex - 1];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            lesson: previousLesson,
            playlist: widget.playlist,
            breadcrumbs: widget.breadcrumbs,
          ),
        ),
      );
    }
  }

  void _changeSpeed(double speed) async {
    setState(() {
      _playbackSpeed = speed;
    });

    if (kIsWeb) {
      // On web, use AudioServiceWeb
      await AudioServiceWeb().setSpeed(speed);
    } else {
      // On mobile, use AudioHandler which updates both player and notification
      final handler = app.audioHandler as LessonAudioHandler;
      await handler.setSpeed(speed);
    }
  }

  void _showSpeedMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<double>(
      context: context,
      position: position,
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          padding: EdgeInsets.zero,
          child: GlassCard(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${speed}x',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                if (_playbackSpeed == speed)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ).then((speed) {
      if (speed != null) {
        _changeSpeed(speed);
      }
    });
  }

  @override
  void dispose() {
    // Unsubscribe from route observer
    app.routeObserver.unsubscribe(this);

    _pulseController.dispose();

    // Clean up based on platform
    if (kIsWeb) {
      // Don't dispose the player - AudioServiceWeb keeps it alive for background playback
      // Only clear the callback
      AudioServiceWeb().onLessonCompleted = null;
    }
    // On mobile, AudioHandler manages the player lifecycle
    // Don't dispose the player as it's owned by AudioHandler

    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '$minutes:${twoDigits(seconds)}';
  }

  /// Формирует breadcrumbs с заменой последнего элемента на "Урок X из Y"
  List<String> _getBreadcrumbsWithLesson() {
    if (widget.breadcrumbs.isEmpty || widget.playlist.isEmpty) {
      return widget.breadcrumbs;
    }

    // Берем все элементы кроме последнего
    final breadcrumbsWithoutLast = widget.breadcrumbs.sublist(0, widget.breadcrumbs.length - 1);

    // Добавляем "Урок X из Y" как последний элемент
    final lessonNumber = widget.playlist.indexOf(widget.lesson) + 1;
    final totalLessons = widget.playlist.length;

    return [
      ...breadcrumbsWithoutLast,
      'Урок $lessonNumber из $totalLessons',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // App bar with back button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Плеер',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Breadcrumbs with lesson info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Breadcrumbs(
                  path: _getBreadcrumbsWithLesson(),
                  textColor: Colors.green.shade800,
                ),
              ),

              // Player UI
              Expanded(
                child: _error != null
                    ? _buildErrorView()
                    : (!_isInitialized || _audioPlayer == null)
                        ? const Center(child: CircularProgressIndicator())
                        : _buildPlayerView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
              _initializePlayer();
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Animated audio visualizer with glassmorphism
          _buildAudioVisualizer(),
          const SizedBox(height: 16),

          // Track info (lesson name, teacher, series)
          _buildTrackInfo(),
          const SizedBox(height: 24),

          // Progress bar with glassmorphism
          _buildProgressBar(),
          const SizedBox(height: 32),

          // Playback controls
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Center(
        child: GlassCard(
          width: 260,
          height: 260,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Icon(
              Icons.headset,
              size: 100,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    // Build title: "Книга - Урок X"
    String title = 'Урок ${widget.lesson.lessonNumber}';
    if (widget.lesson.book != null) {
      title = '${widget.lesson.book!.name} - Урок ${widget.lesson.lessonNumber}';
    }

    final isBookmarked = _bookmark != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Lesson title with book name and bookmark star
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lesson title - large and bold
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              // Bookmark star button
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.star : Icons.star_border,
                  color: isBookmarked ? Colors.amber : Colors.grey[600],
                  size: 32,
                ),
                onPressed: _loadingBookmark ? null : _toggleBookmark,
                tooltip: isBookmarked ? 'Удалить из закладок' : 'Добавить в закладки',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teacher name only (without "Лектор:")
          if (widget.lesson.teacher != null)
            Text(
              widget.lesson.teacher!.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer!.positionStream,
      builder: (context, snapshot) {
        // Check INSIDE StreamBuilder so it updates on rebuild!
        final isCurrentLesson = kIsWeb
            ? AudioServiceWeb().currentLesson?.id == widget.lesson.id
            : true; // On mobile, always show progress

        // If not current lesson, show static UI
        final position = isCurrentLesson ? (snapshot.data ?? Duration.zero) : Duration.zero;
        final duration = isCurrentLesson ? (_audioPlayer!.duration ?? Duration.zero) : (widget.lesson.durationSeconds != null ? Duration(seconds: widget.lesson.durationSeconds!) : Duration.zero);

        return GlassCard(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  activeTrackColor: Colors.green.shade600,
                  inactiveTrackColor: Colors.black.withValues(alpha: 0.3),
                  thumbColor: Colors.green.shade700,
                  overlayColor: Colors.green.withValues(alpha: 0.2),
                ),
                child: Slider(
                  min: 0.0,
                  max: duration.inSeconds.toDouble(),
                  value: position.inSeconds
                      .toDouble()
                      .clamp(0.0, duration.inSeconds.toDouble()),
                  onChanged: (value) {
                    _audioPlayer!.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    // Speed control button with glassmorphism
                    GestureDetector(
                      onTap: () => _showSpeedMenu(context),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(10),
                        blur: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, size: 14, color: Colors.green.shade800),
                            const SizedBox(width: 4),
                            Text(
                              '${_playbackSpeed}x',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer!.playerStateStream,
      builder: (context, snapshot) {
        // Check INSIDE StreamBuilder so it updates on rebuild!
        final isCurrentLesson = kIsWeb
            ? AudioServiceWeb().currentLesson?.id == widget.lesson.id
            : true; // On mobile, always show real state

        final playerState = snapshot.data;
        // If not current lesson, show paused state
        final isPlaying = isCurrentLesson ? (playerState?.playing ?? false) : false;
        final processingState = playerState?.processingState;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous lesson button
            _buildControlButton(
              icon: Icons.skip_previous,
              size: 48,
              enabled: widget.playlist.indexOf(widget.lesson) > 0,
              onPressed: _playPreviousLesson,
            ),
            const SizedBox(width: 16),

            // Rewind 10s
            _buildControlButton(
              icon: Icons.replay_10,
              size: 40,
              enabled: true,
              onPressed: () {
                final newPosition =
                    _audioPlayer!.position - const Duration(seconds: 10);
                _audioPlayer!.seek(
                    newPosition < Duration.zero ? Duration.zero : newPosition);
              },
            ),
            const SizedBox(width: 24),

            // Play/Pause button with circular progress
            processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering
                ? const SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  )
                : StreamBuilder<Duration>(
                    stream: _audioPlayer!.positionStream,
                    builder: (context, snapshot) {
                      // If not current lesson, show 0 progress
                      final position = isCurrentLesson ? (snapshot.data ?? Duration.zero) : Duration.zero;
                      final duration = isCurrentLesson ? (_audioPlayer!.duration ?? Duration.zero) : Duration.zero;
                      final progress = duration.inSeconds > 0
                          ? position.inSeconds / duration.inSeconds
                          : 0.0;

                      return SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 5,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade600,
                                ),
                              ),
                            ),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                iconSize: 36,
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  if (kIsWeb) {
                                    final audioService = AudioServiceWeb();

                                    // Check if we need to switch to a different lesson
                                    if (audioService.currentLesson?.id != widget.lesson.id) {
                                      // Different lesson - start playing it
                                      await audioService.playLesson(
                                        lesson: widget.lesson,
                                        playlist: widget.playlist,
                                      );
                                      // Update UI to reflect new current lesson
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    } else {
                                      // Same lesson - just toggle play/pause
                                      if (isPlaying) {
                                        await _audioPlayer!.pause();
                                      } else {
                                        await _audioPlayer!.play();
                                      }
                                      // StreamBuilder will automatically update UI - no setState needed
                                    }
                                  } else {
                                    if (isPlaying) {
                                      await _audioPlayer!.pause();
                                    } else {
                                      await _audioPlayer!.play();
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(width: 24),

            // Forward 10s
            _buildControlButton(
              icon: Icons.forward_10,
              size: 40,
              enabled: true,
              onPressed: () {
                final duration = _audioPlayer!.duration ?? Duration.zero;
                final newPosition =
                    _audioPlayer!.position + const Duration(seconds: 10);
                _audioPlayer!
                    .seek(newPosition > duration ? duration : newPosition);
              },
            ),
            const SizedBox(width: 16),

            // Next lesson button
            _buildControlButton(
              icon: Icons.skip_next,
              size: 48,
              enabled: widget.playlist.indexOf(widget.lesson) <
                  widget.playlist.length - 1,
              onPressed: _playNextLesson,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        iconSize: size,
        icon: Icon(
          icon,
          color: enabled ? Colors.green.shade700 : Colors.black.withValues(alpha: 0.3),
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

}
