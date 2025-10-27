import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/breadcrumbs.dart';
import '../../../data/models/lesson.dart';
import '../../../config/api_config.dart';

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

  // Smooth interpolation для плавной анимации waveform (60 FPS как у Samsung)
  Ticker? _smoothTicker;
  Duration _lastRealPosition = Duration.zero;
  final ValueNotifier<Duration> _smoothPositionNotifier = ValueNotifier(Duration.zero);
  DateTime _lastTickTime = DateTime.now();

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

      // Подписка на playerStateStream для автоплея следующего урока
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _playNextLesson();
        }

        // Управление smooth ticker в зависимости от состояния плеера
        if (state.playing) {
          _startSmoothTicker();
        } else {
          _stopSmoothTicker();
        }
      });

      // Подписка на positionStream для коррекции smooth position
      _audioPlayer.positionStream.listen((position) {
        _lastRealPosition = position;
        // Корректируем smooth position для синхронизации
        if ((_smoothPositionNotifier.value - position).abs() > const Duration(milliseconds: 200)) {
          _smoothPositionNotifier.value = position;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки аудио: $e';
      });
    }
  }

  void _startSmoothTicker() {
    if (_smoothTicker != null && _smoothTicker!.isActive) return;

    _smoothTicker = createTicker(_onTick);
    _lastTickTime = DateTime.now();
    _smoothTicker!.start();
  }

  void _stopSmoothTicker() {
    _smoothTicker?.stop();
    _smoothTicker?.dispose();
    _smoothTicker = null;
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();
    final delta = now.difference(_lastTickTime);
    _lastTickTime = now;

    // Интерполируем позицию: добавляем время с учетом playback speed
    _smoothPositionNotifier.value += delta * _playbackSpeed;
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
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
    _stopSmoothTicker();
    _smoothPositionNotifier.dispose();
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade100,
              Colors.green.shade200,
              Colors.teal.shade100,
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

              // Breadcrumbs with lesson info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Breadcrumbs(
                  path: _getBreadcrumbsWithLesson(),
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
                      ? ValueListenableBuilder<Duration>(
                          valueListenable: _smoothPositionNotifier,
                          builder: (context, smoothPosition, child) {
                            // Используем smooth position для плавной анимации (60 FPS)
                            final duration = _audioPlayer.duration ?? Duration.zero;
                            final progress = duration.inMilliseconds > 0
                                ? smoothPosition.inMilliseconds / duration.inMilliseconds
                                : 0.0;

                            // Parse waveform data from lesson
                            List<int>? waveformData;
                            if (widget.lesson.waveformData != null) {
                              try {
                                final parsed = jsonDecode(widget.lesson.waveformData!);
                                if (parsed is List) {
                                  waveformData = parsed.cast<int>();
                                }
                              } catch (e) {
                                // If parsing fails, waveformData remains null
                              }
                            }

                            return CustomPaint(
                              painter: WaveformPainter(
                                waveformData: waveformData,
                                isPlaying: isPlaying,
                                progress: progress,
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
                        // Speed control button with glassmorphism
                        GestureDetector(
                          onTap: () => _showSpeedMenu(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.4),
                                      Colors.white.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
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

}

/// Custom painter for real waveform visualization
class WaveformPainter extends CustomPainter {
  final List<int>? waveformData;
  final bool isPlaying;
  final double progress; // Playback progress (0.0 to 1.0)

  WaveformPainter({
    this.waveformData,
    required this.isPlaying,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying || waveformData == null || waveformData!.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final centerY = size.height / 2;
    final totalPoints = waveformData!.length;

    // ОКНО ВОЛНЫ: показываем только 100 точек вокруг текущей позиции
    const windowSize = 100;

    // Вычисляем центр окна (текущая позиция)
    final centerIndex = (progress * totalPoints).floor();

    // Определяем границы окна
    int startIndex = (centerIndex - windowSize ~/ 2).clamp(0, totalPoints - windowSize);
    int endIndex = (startIndex + windowSize).clamp(windowSize, totalPoints);

    // Корректируем если дошли до конца
    if (endIndex == totalPoints) {
      startIndex = totalPoints - windowSize;
    }

    // Извлекаем только видимую часть waveform
    final visibleWaveform = waveformData!.sublist(startIndex, endIndex);
    final visibleCount = visibleWaveform.length;

    // Теперь рисуем только видимые точки, но на всю ширину контейнера
    final barWidth = (size.width / visibleCount) * 0.4; // Тонкие бары - 40% пространства
    final spacing = (size.width / visibleCount) * 0.6;

    for (int i = 0; i < visibleCount; i++) {
      final x = (i * (barWidth + spacing)) + barWidth / 2;

      // Get amplitude from visible waveform
      final amplitude = visibleWaveform[i];

      // Увеличиваем высоту: минимум 40px, максимум 200px
      final height = 40 + (amplitude / 100) * 160;

      // Определяем глобальный индекс для правильной подсветки
      final globalIndex = startIndex + i;

      // Color based on playback position (сравниваем с глобальным индексом)
      // Already played: darker green, current: bright green, upcoming: light green
      Color barColor;
      if (globalIndex < centerIndex) {
        // Already played - darker green
        barColor = Colors.green.shade800.withValues(alpha: 0.9);
      } else if (globalIndex == centerIndex) {
        // Current position - bright accent
        barColor = Colors.green.shade600;
      } else {
        // Not yet played - medium green
        barColor = Colors.green.shade500.withValues(alpha: 0.7);
      }

      paint.color = barColor;

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
    return waveformData != oldDelegate.waveformData ||
        isPlaying != oldDelegate.isPlaying ||
        progress != oldDelegate.progress;
  }
}
