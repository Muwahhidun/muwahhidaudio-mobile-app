import 'package:flutter/material.dart';
import 'notifications_settings_tab.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Системные настройки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_outlined),
              text: 'Уведомления',
            ),
            // Можно добавить больше вкладок в будущем
            // Tab(icon: Icon(Icons.security), text: 'Безопасность'),
            // Tab(icon: Icon(Icons.backup), text: 'Резервные копии'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          NotificationsSettingsTab(),
          // Добавить другие вкладки здесь
        ],
      ),
    );
  }
}
