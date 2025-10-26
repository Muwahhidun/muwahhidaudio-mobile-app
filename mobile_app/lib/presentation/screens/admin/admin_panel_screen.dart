import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Блок: Управление контентом
          Text(
            'Управление контентом',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.theme,
            title: 'Темы',
            subtitle: 'Управление темами уроков',
            color: AppIcons.themeColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/themes');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.book,
            title: 'Книги',
            subtitle: 'Управление книгами',
            color: AppIcons.bookColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/books');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.bookAuthor,
            title: 'Авторы',
            subtitle: 'Управление авторами книг',
            color: AppIcons.bookAuthorColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/authors');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.teacher,
            title: 'Преподаватели',
            subtitle: 'Управление преподавателями',
            color: AppIcons.teacherColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/teachers');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.series,
            title: 'Серии',
            subtitle: 'Управление сериями уроков',
            color: AppIcons.seriesColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/series');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.lesson,
            title: 'Уроки',
            subtitle: 'Управление аудио уроками',
            color: AppIcons.lessonColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/lessons');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: AppIcons.test,
            title: 'Тесты',
            subtitle: 'Управление тестами',
            color: AppIcons.testColor,
            onTap: () {
              Navigator.pushNamed(context, '/admin/tests');
            },
          ),

          // Блок: Общая информация
          const SizedBox(height: 32),
          Text(
            'Общая информация',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.people,
            title: 'Управление пользователями',
            subtitle: 'Роли, блокировка, удаление',
            color: Colors.indigo,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.mail_outline,
            title: 'Обращения',
            subtitle: 'Сообщения от пользователей',
            color: Colors.amber,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('В разработке')),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.bar_chart,
            title: 'Статистика',
            subtitle: 'Общая статистика по контенту',
            color: Colors.cyan,
            onTap: () {
              Navigator.pushNamed(context, '/admin/statistics');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.help_outline,
            title: 'Справка',
            subtitle: 'Инструкция для администраторов',
            color: Colors.blueGrey,
            onTap: () {
              Navigator.pushNamed(context, '/admin/help');
            },
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.settings,
            title: 'Системные',
            subtitle: 'Настройки системы и уведомлений',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.pushNamed(context, '/admin/system-settings');
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(AppIcons.chevronRight),
        onTap: onTap,
      ),
    );
  }
}
