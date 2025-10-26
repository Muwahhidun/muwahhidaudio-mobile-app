import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../widgets/breadcrumbs.dart';
import '../../../data/models/lesson.dart';
import '../../../config/api_config.dart';

/// Audio Player Screen with just_audio
class PlayerScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Lesson> playlist; // All lessons in the series
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

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String? _error;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _audioPlayer = AudioPlayer();

    try {
      // Build full audio URL
      final audioUrl = '${ApiConfig.baseUrl}${widget.lesson.audioUrl}';

      await _audioPlayer.setUrl(audioUrl);

      setState(() {
        _isInitialized = true;
      });

      // Auto-play
      _audioPlayer.play();

      // Listen for completion to auto-play next lesson
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
      appBar: AppBar(
        title: const Text('Плеер'),
      ),
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Breadcrumbs(
              path: widget.breadcrumbs,
            ),
          ),

          // Player UI
          Expanded(
            child: _error != null
                ? Center(
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
                  )
                : !_isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),

                            // Album art placeholder
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.headset,
                                size: 100,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Lesson title
                            Text(
                              widget.lesson.displayTitle ?? widget.lesson.title ?? 'Урок ${widget.lesson.lessonNumber}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Lesson info
                            if (widget.lesson.teacher != null)
                              Text(
                                'Лектор: ${widget.lesson.teacher!.name}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            const SizedBox(height: 32),

                            // Progress bar
                            StreamBuilder<Duration>(
                              stream: _audioPlayer.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final duration = _audioPlayer.duration ?? Duration.zero;

                                return Column(
                                  children: [
                                    Slider(
                                      min: 0.0,
                                      max: duration.inSeconds.toDouble(),
                                      value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                                      onChanged: (value) {
                                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_formatDuration(position)),
                                          Text(_formatDuration(duration)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Playback controls
                            StreamBuilder<PlayerState>(
                              stream: _audioPlayer.playerStateStream,
                              builder: (context, snapshot) {
                                final playerState = snapshot.data;
                                final isPlaying = playerState?.playing ?? false;
                                final processingState = playerState?.processingState;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Previous lesson button
                                    IconButton(
                                      iconSize: 48,
                                      icon: Icon(
                                        Icons.skip_previous,
                                        color: widget.playlist.indexOf(widget.lesson) > 0
                                            ? null
                                            : Colors.grey,
                                      ),
                                      onPressed: widget.playlist.indexOf(widget.lesson) > 0
                                          ? _playPreviousLesson
                                          : null,
                                    ),
                                    const SizedBox(width: 16),

                                    // Rewind 10s
                                    IconButton(
                                      iconSize: 36,
                                      icon: const Icon(Icons.replay_10),
                                      onPressed: () {
                                        final newPosition = _audioPlayer.position - const Duration(seconds: 10);
                                        _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                                      },
                                    ),
                                    const SizedBox(width: 16),

                                    // Play/Pause button
                                    processingState == ProcessingState.loading ||
                                            processingState == ProcessingState.buffering
                                        ? const CircularProgressIndicator()
                                        : IconButton(
                                            iconSize: 64,
                                            icon: Icon(
                                              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                            ),
                                            onPressed: () {
                                              if (isPlaying) {
                                                _audioPlayer.pause();
                                              } else {
                                                _audioPlayer.play();
                                              }
                                            },
                                          ),
                                    const SizedBox(width: 16),

                                    // Forward 10s
                                    IconButton(
                                      iconSize: 36,
                                      icon: const Icon(Icons.forward_10),
                                      onPressed: () {
                                        final duration = _audioPlayer.duration ?? Duration.zero;
                                        final newPosition = _audioPlayer.position + const Duration(seconds: 10);
                                        _audioPlayer.seek(newPosition > duration ? duration : newPosition);
                                      },
                                    ),
                                    const SizedBox(width: 16),

                                    // Next lesson button
                                    IconButton(
                                      iconSize: 48,
                                      icon: Icon(
                                        Icons.skip_next,
                                        color: widget.playlist.indexOf(widget.lesson) < widget.playlist.length - 1
                                            ? null
                                            : Colors.grey,
                                      ),
                                      onPressed: widget.playlist.indexOf(widget.lesson) < widget.playlist.length - 1
                                          ? _playNextLesson
                                          : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Playback speed control
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Скорость воспроизведения',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${_playbackSpeed}x',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
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
                            const SizedBox(height: 24),

                            // Playlist info
                            if (widget.playlist.isNotEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Плейлист',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Урок ${widget.playlist.indexOf(widget.lesson) + 1} из ${widget.playlist.length}',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
