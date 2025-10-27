import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/teachers_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/theme.dart';
import '../../../data/models/book.dart';
import '../series/series_screen.dart';

/// Path A: Step 3 - Teachers by Theme + Book
class TeachersByThemeBookScreen extends ConsumerStatefulWidget {
  final AppThemeModel theme;
  final BookModel book;

  const TeachersByThemeBookScreen({
    super.key,
    required this.theme,
    required this.book,
  });

  @override
  ConsumerState<TeachersByThemeBookScreen> createState() => _TeachersByThemeBookScreenState();
}

class _TeachersByThemeBookScreenState extends ConsumerState<TeachersByThemeBookScreen> {
  @override
  void initState() {
    super.initState();
    // Load teachers for this theme + book
    Future.microtask(() {
      ref.read(teachersProvider.notifier).loadTeachers(
        themeId: widget.theme.id,
        bookId: widget.book.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachersState = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лекторы'),
      ),
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Breadcrumbs(
              path: ['Темы', widget.theme.name, widget.book.name],
            ),
          ),

          // Teachers list
          Expanded(
            child: _buildTeachersList(teachersState),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildTeachersList(TeachersState state) {
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
                ref.read(teachersProvider.notifier).loadTeachers(
                  themeId: widget.theme.id,
                  bookId: widget.book.id,
                );
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.teachers.isEmpty) {
      return const Center(
        child: Text('Лекторов не найдено'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(teachersProvider.notifier).loadTeachers(
          themeId: widget.theme.id,
          bookId: widget.book.id,
        );
      },
      child: ListView.builder(
        itemCount: state.teachers.length,
        itemBuilder: (context, index) {
          final teacher = state.teachers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                AppIcons.teacher,
                color: AppIcons.teacherColor,
                size: 32,
              ),
              title: Text(
                teacher.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: teacher.biography != null
                  ? Text(
                      teacher.biography!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to series
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeriesScreen(
                      breadcrumbs: ['Темы', widget.theme.name, widget.book.name, teacher.name],
                      themeId: widget.theme.id,
                      bookId: widget.book.id,
                      teacherId: teacher.id,
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
