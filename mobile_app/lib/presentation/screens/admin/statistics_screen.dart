import 'package:flutter/material.dart';
import '../../../data/api/dio_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioProvider.getDio();
      final response = await dio.get('/statistics');

      setState(() {
        _statistics = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Статистика'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStatistics,
              tooltip: 'Обновить',
            ),
          ],
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatistics,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Контент',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        Text(
                          'Детальная информация',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailedInfo(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_statistics == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Темы',
          _statistics!['themes']['total'],
          _statistics!['themes']['active'],
          Colors.purple,
          Icons.category,
        ),
        _buildStatCard(
          'Книги',
          _statistics!['books']['total'],
          _statistics!['books']['active'],
          Colors.blue,
          Icons.book,
        ),
        _buildStatCard(
          'Авторы',
          _statistics!['authors']['total'],
          _statistics!['authors']['active'],
          Colors.orange,
          Icons.person,
        ),
        _buildStatCard(
          'Преподаватели',
          _statistics!['teachers']['total'],
          _statistics!['teachers']['active'],
          Colors.green,
          Icons.school,
        ),
        _buildStatCard(
          'Серии',
          _statistics!['series']['total'],
          _statistics!['series']['active'],
          Colors.teal,
          Icons.video_library,
        ),
        _buildStatCard(
          'Уроки',
          _statistics!['lessons']['total'],
          _statistics!['lessons']['active'],
          Colors.indigo,
          Icons.headphones,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int total,
    int active,
    Color color,
    IconData icon,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Активных: $active',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    if (_statistics == null) return const SizedBox();

    return Column(
      children: [
        _buildDetailCard(
          'Серии',
          Icons.video_library,
          Colors.teal,
          [
            _buildDetailRow('Завершённых', _statistics!['series']['completed']),
            _buildDetailRow('В процессе', _statistics!['series']['in_progress']),
            _buildDetailRow('Неактивных', _statistics!['series']['inactive']),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailCard(
          'Уроки',
          Icons.headphones,
          Colors.indigo,
          [
            _buildDetailRow('С аудио', _statistics!['lessons']['with_audio']),
            _buildDetailRow('Без аудио', _statistics!['lessons']['without_audio']),
            _buildDetailRow('Неактивных', _statistics!['lessons']['inactive']),
            const Divider(),
            _buildDetailRow(
              'Общая длительность',
              '${_statistics!['lessons']['total_duration_hours']} ч',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailCard(
          'Пользователи',
          Icons.people,
          Colors.indigo,
          [
            _buildDetailRow('Всего', _statistics!['users']['total']),
            _buildDetailRow('Активных', _statistics!['users']['active']),
            _buildDetailRow('Неактивных', _statistics!['users']['inactive']),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
