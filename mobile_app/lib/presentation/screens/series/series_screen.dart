import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/series_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../lessons/lessons_screen.dart';

/// Universal screen for showing lesson series
/// Works for all navigation paths
class SeriesScreen extends ConsumerStatefulWidget {
  final List<String> breadcrumbs;
  final int? themeId;
  final int? bookId;
  final int? teacherId;

  const SeriesScreen({
    super.key,
    required this.breadcrumbs,
    this.themeId,
    this.bookId,
    this.teacherId,
  });

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  @override
  void initState() {
    super.initState();
    // Load series with filters
    Future.microtask(() {
      ref
          .read(seriesProvider.notifier)
          .setFilters(
            themeId: widget.themeId,
            bookId: widget.bookId,
            teacherId: widget.teacherId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final seriesState = ref.watch(seriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Серии уроков')),
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Breadcrumbs(path: widget.breadcrumbs),
          ),

          // Series list
          Expanded(child: _buildSeriesList(seriesState)),
        ],
      ),
    );
  }

  Widget _buildSeriesList(SeriesState state) {
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
                ref.read(seriesProvider.notifier).refresh();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.series.isEmpty) {
      return const Center(child: Text('Серий не найдено'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(seriesProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: state.series.length,
        itemBuilder: (context, index) {
          final series = state.series[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.library_books, color: Colors.blue, size: 32),
              title: Text(
                series.displayName ?? series.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (series.teacher != null)
                    Text('Лектор: ${series.teacher!.name}'),
                  if (series.book != null) Text('Книга: ${series.book!.name}'),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to lessons
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LessonsScreen(
                      breadcrumbs: [
                        ...widget.breadcrumbs,
                        series.displayName ?? series.name,
                      ],
                      seriesId: series.id,
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
