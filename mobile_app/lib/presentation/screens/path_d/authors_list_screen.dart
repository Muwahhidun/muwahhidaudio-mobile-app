import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/book_authors_provider.dart';
import '../../widgets/mini_player.dart';
import 'books_by_author_screen.dart';

class AuthorsListScreen extends ConsumerWidget {
  const AuthorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorsState = ref.watch(bookAuthorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
      ),
      body: _buildBody(context, ref, authorsState),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BookAuthorsState state) {
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
              onPressed: () => ref.read(bookAuthorsProvider.notifier).loadAuthors(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.authors.isEmpty) {
      return const Center(
        child: Text('Авторы не найдены'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(bookAuthorsProvider.notifier).loadAuthors(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.authors.length,
        itemBuilder: (context, index) {
          final author = state.authors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppIcons.bookAuthorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.bookAuthor,
                  color: AppIcons.bookAuthorColor,
                  size: 24,
                ),
              ),
              title: Text(
                author.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (author.biography != null)
                    Text(
                      author.biography!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (author.birthYear != null || author.deathYear != null)
                    Text(
                      '${author.birthYear ?? "?"} - ${author.deathYear ?? "?"}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
              isThreeLine: author.biography != null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BooksByAuthorScreen(author: author),
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
