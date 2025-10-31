import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../../data/models/lesson.dart';
import '../../core/audio/audio_service_web.dart';
import '../../main.dart' as app;
import '../../core/audio/audio_handler.dart';
import '../screens/player/player_screen.dart';
import 'glass_card.dart';

/// Floating mini player that appears at the bottom of all screens
/// Shows current playing lesson with controls
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebMiniPlayer();
    } else {
      return _MobileMiniPlayer();
    }
  }
}

class _WebMiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioService = AudioServiceWeb();

    // Listen to current lesson changes
    return StreamBuilder<Lesson?>(
      stream: audioService.currentLessonStream,
      initialData: audioService.currentLesson,
      builder: (context, lessonSnapshot) {
        final currentLesson = lessonSnapshot.data;

        // Don't show if no lesson is playing
        if (currentLesson == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlayerState>(
          stream: audioService.player.playerStateStream,
          builder: (context, playerSnapshot) {
            final playerState = playerSnapshot.data;
            final isPlaying = playerState?.playing ?? false;

            return _MiniPlayerUI(
              lesson: currentLesson,
              isPlaying: isPlaying,
              player: audioService.player,
              onTap: () {
                // Navigate to full player
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      lesson: currentLesson,
                      playlist: audioService.playlist,
                      breadcrumbs: ['Лекторы', currentLesson.teacher?.name ?? '', 'Плеер'],
                    ),
                  ),
                );
              },
              onPlayPause: () {
                if (isPlaying) {
                  audioService.pause();
                } else {
                  audioService.play();
                }
              },
              onPrevious: audioService.currentIndex > 0
                  ? () => audioService.skipToPrevious()
                  : null,
              onNext: audioService.currentIndex < audioService.playlist.length - 1
                  ? () => audioService.skipToNext()
                  : null,
            );
          },
        );
      },
    );
  }
}

class _MobileMiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check if audioHandler is initialized
    if (app.audioHandler == null) {
      return const SizedBox.shrink();
    }

    final handler = app.audioHandler as LessonAudioHandler;

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;

        // Don't show if no lesson is playing
        if (mediaItem == null || handler.playlist.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentLesson = handler.playlist[handler.currentIndex];

        return StreamBuilder<PlayerState>(
          stream: handler.player.playerStateStream,
          builder: (context, playerStateSnapshot) {
            final playerState = playerStateSnapshot.data;
            final isPlaying = playerState?.playing ?? false;

            return _MiniPlayerUI(
              lesson: currentLesson,
              isPlaying: isPlaying,
              player: handler.player,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      lesson: currentLesson,
                      playlist: handler.playlist,
                      breadcrumbs: ['Лекторы', currentLesson.teacher?.name ?? '', 'Плеер'],
                    ),
                  ),
                );
              },
              onPlayPause: () {
                if (isPlaying) {
                  handler.pause();
                } else {
                  handler.play();
                }
              },
              onPrevious: handler.currentIndex > 0
                  ? () => handler.skipToPrevious()
                  : null,
              onNext: handler.currentIndex < handler.playlist.length - 1
                  ? () => handler.skipToNext()
                  : null,
            );
          },
        );
      },
    );
  }
}

class _MiniPlayerUI extends StatelessWidget {
  final Lesson lesson;
  final bool isPlaying;
  final AudioPlayer player;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _MiniPlayerUI({
    required this.lesson,
    required this.isPlaying,
    required this.player,
    required this.onTap,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return GlassCard(
      height: 80,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
      child: Column(
        children: [
          // Progress bar
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;
              final progress = duration.inSeconds > 0
                  ? position.inSeconds / duration.inSeconds
                  : 0.0;

              return LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                minHeight: 2,
              );
            },
          ),

          // Controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Icon and Lesson info - wrapped in GestureDetector for navigation
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.headset,
                              color: Colors.green.shade800,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Lesson info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  lesson.book != null
                                      ? '${lesson.book!.name} - Урок ${lesson.lessonNumber}'
                                      : 'Урок ${lesson.lessonNumber}',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lesson.teacher?.name ?? '',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Controls - wide screen
                  if (isWide) ...[
                    // Previous
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: Colors.green.shade800),
                      onPressed: onPrevious,
                      iconSize: 32,
                    ),

                    // Rewind 10s
                    IconButton(
                      icon: Icon(Icons.replay_10, color: Colors.green.shade800),
                      onPressed: () {
                        final newPosition = player.position - const Duration(seconds: 10);
                        player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                      },
                      iconSize: 28,
                    ),
                  ],

                  // Play/Pause - always visible
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: onPlayPause,
                      iconSize: 28,
                    ),
                  ),

                  // Controls - wide screen
                  if (isWide) ...[
                    // Forward 10s
                    IconButton(
                      icon: Icon(Icons.forward_10, color: Colors.green.shade800),
                      onPressed: () {
                        final duration = player.duration ?? Duration.zero;
                        final newPosition = player.position + const Duration(seconds: 10);
                        player.seek(newPosition > duration ? duration : newPosition);
                      },
                      iconSize: 28,
                    ),

                    // Next
                    IconButton(
                      icon: Icon(Icons.skip_next, color: Colors.green.shade800),
                      onPressed: onNext,
                      iconSize: 32,
                    ),
                  ],

                  // Close button - always visible
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.green.shade800),
                    onPressed: () {
                      if (kIsWeb) {
                        AudioServiceWeb().stop();
                      } else if (app.audioHandler != null) {
                        (app.audioHandler as LessonAudioHandler).stop();
                      }
                    },
                    iconSize: 24,
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
