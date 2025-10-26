import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/lessons_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../player/player_screen.dart';

/// Universal screen for showing lessons in a series
class LessonsScreen extends ConsumerStatefulWidget {
  final List<String> breadcrumbs;
  final int seriesId;

  const LessonsScreen({
    super.key,
    required this.breadcrumbs,
    required this.seriesId,
  });

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  @override
  void initState() {
    super.initState();
    // Load lessons for this series
    Future.microtask(() {
      ref.read(lessonsProvider.notifier).loadLessons(widget.seriesId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonsState = ref.watch(lessonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уроки'),
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

          // Lessons list
          Expanded(
            child: _buildLessonsList(lessonsState),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList(LessonsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(lessonsProvider.notifier).refresh();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.lessons.isEmpty) {
      return const Center(
        child: Text('Уроков не найдено'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(lessonsProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: state.lessons.length,
        itemBuilder: (context, index) {
          final lesson = state.lessons[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  '${lesson.lessonNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: lesson.formattedDuration != null
                  ? Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(lesson.formattedDuration!),
                      ],
                    )
                  : null,
              trailing: const Icon(Icons.play_arrow, size: 32, color: Colors.green),
              onTap: () {
                // Navigate to player with full playlist
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      lesson: lesson,
                      playlist: state.lessons, // Pass all lessons as playlist
                      breadcrumbs: [...widget.breadcrumbs, lesson.displayTitle ?? lesson.title ?? 'Урок ${lesson.lessonNumber}'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
