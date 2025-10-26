import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../themes/themes_screen.dart';
import '../feedback/feedback_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Audio Lessons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
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

            // Themes Card
            _MenuCard(
              icon: Icons.category,
              title: 'Темы',
              subtitle: 'Акыда, Фикх, Сира',
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ThemesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Teachers Card
            _MenuCard(
              icon: Icons.person,
              title: 'Учителя',
              subtitle: 'Преподаватели уроков',
              color: Colors.blue,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро...')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Bookmarks Card
            _MenuCard(
              icon: Icons.bookmark,
              title: 'Закладки',
              subtitle: 'Избранные уроки',
              color: Colors.orange,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скоро...')),
                );
              },
            ),
            const SizedBox(height: 12),

            // Profile/Data Card
            _MenuCard(
              icon: Icons.account_circle,
              title: 'Данные',
              subtitle: 'Профиль пользователя',
              color: Colors.teal,
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
              color: Colors.purple,
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
                color: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, '/admin');
                },
              ),
            ],
          ],
        ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                      style: const TextStyle(
                        fontSize: 18,
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
        ),
      ),
    );
  }
}
