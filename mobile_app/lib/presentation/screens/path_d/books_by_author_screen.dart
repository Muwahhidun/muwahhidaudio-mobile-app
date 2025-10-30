import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/book_author.dart';
import '../../providers/books_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import 'teachers_by_author_book_screen.dart';

class BooksByAuthorScreen extends ConsumerStatefulWidget {
  final BookAuthorModel author;

  const BooksByAuthorScreen({super.key, required this.author});

  @override
  ConsumerState<BooksByAuthorScreen> createState() => _BooksByAuthorScreenState();
}

class _BooksByAuthorScreenState extends ConsumerState<BooksByAuthorScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(booksProvider.notifier).loadBooks(authorId: widget.author.id);
    });
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Breadcrumbs(path: ['Авторы', widget.author.name]),
              ),
            ),
            Expanded(child: _buildBody(context, ref, booksState)),
          ],
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BooksState state) {
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
              onPressed: () => ref.read(booksProvider.notifier).loadBooks(authorId: widget.author.id),
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
      onRefresh: () => ref.read(booksProvider.notifier).loadBooks(authorId: widget.author.id),
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
                  builder: (context) => TeachersByAuthorBookScreen(
                    author: widget.author,
                    book: book,
                  ),
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
                  if (book.theme != null)
                    Text('Тема: ${book.theme!.name}'),
                ],
              ),
              isThreeLine: book.description != null && book.theme != null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
