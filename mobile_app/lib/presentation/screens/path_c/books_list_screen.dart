import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/books_provider.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/mini_player.dart';
import 'teachers_by_book_screen.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Книги'),
        ),
        body: _buildBody(context, booksState),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BooksState state) {
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
                hintText: 'Поиск книг...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          ref.read(booksProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
                ref.read(booksProvider.notifier).search(value);
              },
            ),
          ),
        ),
        // List
        Expanded(
          child: _buildBooksList(context, state),
        ),
      ],
    );
  }

  Widget _buildBooksList(BuildContext context, BooksState state) {
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
              onPressed: () => ref.read(booksProvider.notifier).loadBooks(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.books.isEmpty) {
      return const Center(
        child: Text('Книги не найдены'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(booksProvider.notifier).loadBooks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.books.length,
        itemBuilder: (context, index) {
          final book = state.books[index];
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TeachersByBookScreen(book: book),
                ),
              );
            },
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppIcons.bookColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.book,
                  color: AppIcons.bookColor,
                  size: 24,
                ),
              ),
              title: Text(
                book.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.description != null)
                    Text(
                      book.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (book.author != null)
                    Text('Автор: ${book.author!.name}'),
                  if (book.theme != null)
                    Text('Тема: ${book.theme!.name}'),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
