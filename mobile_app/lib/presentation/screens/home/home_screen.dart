import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../library/library_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../tests/statistics_screen.dart';
import '../feedback/feedback_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Islamic Audio Lessons'),
          actions: [
            // Theme toggle button
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              tooltip: 'Переключить тему',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              tooltip: 'Выход',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Browse Section
              Text(
                'Обзор',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),

              // Library Card
              _MenuCard(
                icon: Icons.library_books,
                title: 'Библиотека',
                subtitle: 'Темы, Лекторы, Книги, Авторы',
                color: AppColors.success,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LibraryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Bookmarks Card
              _MenuCard(
                icon: Icons.bookmark,
                title: 'Закладки',
                subtitle: 'Избранные уроки',
                color: AppColors.warning,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookmarksScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Statistics Card
              _MenuCard(
                icon: Icons.assessment,
                title: 'Статистика',
                subtitle: 'Результаты тестов',
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Profile Card
              _MenuCard(
                icon: Icons.account_circle,
                title: 'Профиль',
                subtitle: 'Данные пользователя',
                color: AppColors.info,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Feedback Card
              _MenuCard(
                icon: Icons.feedback,
                title: 'Обратная связь',
                subtitle: 'Связаться с администрацией',
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackListScreen(),
                    ),
                  );
                },
              ),

              // Admin Panel Card (only for admins)
              if (user?.isAdmin ?? false) ...[
                const SizedBox(height: 24),
                Text(
                  'Управление',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Администрирование',
                  subtitle: 'Управление контентом',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 32),
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
