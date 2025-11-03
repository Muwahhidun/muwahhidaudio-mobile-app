import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/book_authors_provider.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import 'books_by_author_screen.dart';

class AuthorsListScreen extends ConsumerStatefulWidget {
  const AuthorsListScreen({super.key});

  @override
  ConsumerState<AuthorsListScreen> createState() => _AuthorsListScreenState();
}

class _AuthorsListScreenState extends ConsumerState<AuthorsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load authors
    Future.microtask(() {
      ref.read(bookAuthorsProvider.notifier).loadAuthors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authorsState = ref.watch(bookAuthorsProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Авторы'),
        ),
        body: _buildBody(context, authorsState),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookAuthorsState state) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск авторов...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(bookAuthorsProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
                ref.read(bookAuthorsProvider.notifier).search(value);
              },
            ),
          ),
        ),
        // List
        Expanded(
          child: _buildAuthorsList(context, state),
        ),
      ],
    );
  }

  Widget _buildAuthorsList(BuildContext context, BookAuthorsState state) {
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
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BooksByAuthorScreen(author: author),
                ),
              );
            },
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppIcons.bookAuthorColor.withValues(alpha: 0.15),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                ],
              ),
              isThreeLine: author.biography != null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
