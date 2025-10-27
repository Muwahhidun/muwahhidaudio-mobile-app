import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/themes_provider.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/mini_player.dart';
import 'books_by_theme_screen.dart';

/// Path A: Step 1 - List of themes
class ThemesListScreen extends ConsumerWidget {
  const ThemesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesState = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Темы'),
      ),
      body: _buildThemesList(context, ref, themesState),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildThemesList(BuildContext context, WidgetRef ref, ThemesState state) {
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
                ref.read(themesProvider.notifier).refresh();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.themes.isEmpty) {
      return const Center(
        child: Text('Тем не найдено'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(themesProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.themes.length,
        itemBuilder: (context, index) {
          final theme = state.themes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                AppIcons.theme,
                color: AppIcons.themeColor,
                size: 32,
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
                // Navigate to books by theme
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BooksByThemeScreen(theme: theme),
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
