import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Системные настройки'),
        ),
        body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Настройки Email',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          _SystemSettingsMenuItem(
            icon: Icons.email_outlined,
            title: 'Настройка SMTP',
            subtitle: 'Сервер, порт, SSL, аутентификация',
            color: Colors.blue,
            onTap: () {
              Navigator.pushNamed(context, '/admin/smtp-settings');
            },
          ),
          const SizedBox(height: 12),
          _SystemSettingsMenuItem(
            icon: Icons.person_outline,
            title: 'Настройка отправителя',
            subtitle: 'Имя отправителя, email адрес',
            color: Colors.green,
            onTap: () {
              Navigator.pushNamed(context, '/admin/sender-settings');
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _SystemSettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SystemSettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
