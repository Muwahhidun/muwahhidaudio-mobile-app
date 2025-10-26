import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/themes_provider.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesState = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Темы'),
      ),
      body: themesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : themesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка загрузки',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        themesState.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(themesProvider.notifier).refresh();
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : themesState.themes.isEmpty
                  ? const Center(
                      child: Text('Нет доступных тем'),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(themesProvider.notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: themesState.themes.length,
                        itemBuilder: (context, index) {
                          final theme = themesState.themes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  theme.name[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                theme.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (theme.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(theme.description!),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (theme.lessonsCount != null) ...[
                                        const Icon(Icons.headphones, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${theme.lessonsCount} уроков'),
                                        const SizedBox(width: 16),
                                      ],
                                      if (theme.seriesCount != null) ...[
                                        const Icon(Icons.library_books, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${theme.seriesCount} серий'),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // TODO: Navigate to lessons by theme
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Открыть тему: ${theme.name}'),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
