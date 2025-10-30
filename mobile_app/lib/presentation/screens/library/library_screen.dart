import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../path_a/themes_list_screen.dart';
import '../path_b/teachers_list_screen.dart';
import '../path_c/books_list_screen.dart';
import '../path_d/authors_list_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Библиотека'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LibraryCard(
              icon: AppIcons.theme,
              iconColor: AppIcons.themeColor,
              title: 'Темы',
              subtitle: 'Акыда, Фикх, Сира',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemesListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _LibraryCard(
              icon: AppIcons.teacher,
              iconColor: AppIcons.teacherColor,
              title: 'Лекторы',
              subtitle: 'Преподаватели уроков',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TeachersListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _LibraryCard(
              icon: AppIcons.book,
              iconColor: AppIcons.bookColor,
              title: 'Книги',
              subtitle: 'Исламские книги',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BooksListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _LibraryCard(
              icon: AppIcons.bookAuthor,
              iconColor: AppIcons.bookAuthorColor,
              title: 'Авторы',
              subtitle: 'Авторы книг',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AuthorsListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LibraryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
