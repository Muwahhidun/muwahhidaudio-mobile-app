import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/breadcrumbs.dart';
import '../../../data/models/lesson.dart';
import '../../../config/api_config.dart';
import 'dart:math' as math;

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
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String? _error;
  double _playbackSpeed = 1.0;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _audioPlayer = AudioPlayer();

    try {
      final audioUrl = '${ApiConfig.baseUrl}${widget.lesson.audioUrl}';
      await _audioPlayer.setUrl(audioUrl);

      setState(() {
        _isInitialized = true;
      });

      _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _playNextLesson();
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки аудио: $e';
      });
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

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _audioPlayer.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.green.shade100,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
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

              // Breadcrumbs
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Breadcrumbs(
                  path: widget.breadcrumbs,
                ),
              ),

              // Player UI
              Expanded(
                child: _error != null
                    ? _buildErrorView()
                    : !_isInitialized
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
          const SizedBox(height: 32),

          // Lesson title
          Text(
            widget.lesson.displayTitle ??
                widget.lesson.title ??
                'Урок ${widget.lesson.lessonNumber}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Lesson info
          if (widget.lesson.teacher != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Лектор: ${widget.lesson.teacher!.name}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Progress bar with glassmorphism
          _buildProgressBar(),
          const SizedBox(height: 32),

          // Playback controls
          _buildPlaybackControls(),
          const SizedBox(height: 32),

          // Playback speed control
          _buildSpeedControl(),
          const SizedBox(height: 24),

          // Playlist info
          if (widget.playlist.isNotEmpty) _buildPlaylistInfo(),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;

        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
            // Animated pulsating rings when playing
            if (isPlaying) ...[
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 240 + (_pulseController.value * 40),
                    height: 240 + (_pulseController.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green
                            .withValues(alpha: 0.3 - (_pulseController.value * 0.3)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final offset = 0.3;
                  final value =
                      ((_pulseController.value + offset) % 1.0);
                  return Container(
                    width: 240 + (value * 40),
                    height: 240 + (value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3 - (value * 0.3)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Main glassmorphism container with wave visualizer
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: isPlaying
                      ? AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: WaveformPainter(
                                animation: _waveController.value,
                                isPlaying: isPlaying,
                              ),
                              size: const Size(260, 260),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.headset,
                            size: 100,
                            color: Colors.green,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _audioPlayer.duration ?? Duration.zero;

        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
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
                      inactiveTrackColor: Colors.grey.shade300,
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
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final isPlaying = playerState?.playing ?? false;
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
                    _audioPlayer.position - const Duration(seconds: 10);
                _audioPlayer.seek(
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
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = _audioPlayer.duration ?? Duration.zero;
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
                                strokeWidth: 3,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade600,
                                ),
                              ),
                            ),
                            Container(
                              width: 64,
                              height: 64,
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
                                onPressed: () {
                                  if (isPlaying) {
                                    _audioPlayer.pause();
                                  } else {
                                    _audioPlayer.play();
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
                final duration = _audioPlayer.duration ?? Duration.zero;
                final newPosition =
                    _audioPlayer.position + const Duration(seconds: 10);
                _audioPlayer
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
          color: enabled ? Colors.green.shade700 : Colors.grey,
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }

  Widget _buildSpeedControl() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Скорость воспроизведения',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  Text(
                    '${_playbackSpeed}x',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                  return ChoiceChip(
                    label: Text('${speed}x'),
                    selected: _playbackSpeed == speed,
                    selectedColor: Colors.green.shade600,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    labelStyle: TextStyle(
                      color: _playbackSpeed == speed
                          ? Colors.white
                          : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _changeSpeed(speed);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Плейлист',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Урок ${widget.playlist.indexOf(widget.lesson) + 1} из ${widget.playlist.length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for animated waveform visualization
class WaveformPainter extends CustomPainter {
  final double animation;
  final bool isPlaying;

  WaveformPainter({
    required this.animation,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final centerY = size.height / 2;
    final barCount = 30;
    final barWidth = size.width / (barCount * 2);
    final spacing = barWidth;

    for (int i = 0; i < barCount; i++) {
      final x = (i * (barWidth + spacing)) + spacing;

      // Create varied heights using sine waves (reduced amplitude)
      final heightFactor = (math.sin((i / barCount) * math.pi * 2 + animation * math.pi * 2) + 1) / 2;
      final height = 30 + (heightFactor * 40);

      // Gradient color based on position
      final colorValue = (i / barCount);
      paint.color = Color.lerp(
        Colors.green.shade400,
        Colors.green.shade700,
        colorValue,
      )!.withValues(alpha: 0.7);

      // Draw vertical bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: barWidth,
          height: height,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return animation != oldDelegate.animation || isPlaying != oldDelegate.isPlaying;
  }
}
