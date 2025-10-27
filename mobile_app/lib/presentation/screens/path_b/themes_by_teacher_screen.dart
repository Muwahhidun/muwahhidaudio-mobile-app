import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/teacher.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import 'books_by_teacher_theme_screen.dart';

class ThemesByTeacherScreen extends ConsumerStatefulWidget {
  final TeacherModel teacher;

  const ThemesByTeacherScreen({super.key, required this.teacher});

  @override
  ConsumerState<ThemesByTeacherScreen> createState() => _ThemesByTeacherScreenState();
}

class _ThemesByTeacherScreenState extends ConsumerState<ThemesByTeacherScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(themesProvider.notifier).loadThemes(teacherId: widget.teacher.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themesState = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Темы'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Breadcrumbs(path: ['Лекторы', widget.teacher.name]),
          ),
          Expanded(child: _buildBody(context, ref, themesState)),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ThemesState state) {
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
              onPressed: () => ref.read(themesProvider.notifier).loadThemes(teacherId: widget.teacher.id),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.themes.isEmpty) {
      return const Center(
        child: Text('Темы не найдены'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(themesProvider.notifier).loadThemes(teacherId: widget.teacher.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.themes.length,
        itemBuilder: (context, index) {
          final theme = state.themes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppIcons.themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.theme,
                  color: AppIcons.themeColor,
                  size: 24,
                ),
              ),
              title: Text(
                theme.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: theme.description != null
                  ? Text(
                      theme.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BooksByTeacherThemeScreen(
                      teacher: widget.teacher,
                      theme: theme,
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
