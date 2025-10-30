import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/books_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/theme.dart';
import 'teachers_by_theme_book_screen.dart';

/// Path A: Step 2 - Books by Theme
class BooksByThemeScreen extends ConsumerStatefulWidget {
  final AppThemeModel theme;

  const BooksByThemeScreen({
    super.key,
    required this.theme,
  });

  @override
  ConsumerState<BooksByThemeScreen> createState() => _BooksByThemeScreenState();
}

class _BooksByThemeScreenState extends ConsumerState<BooksByThemeScreen> {
  @override
  void initState() {
    super.initState();
    // Load books for this theme
    Future.microtask(() {
      ref.read(booksProvider.notifier).loadBooks(themeId: widget.theme.id);
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
            // Breadcrumbs
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Breadcrumbs(
                  path: ['Темы', widget.theme.name],
                ),
              ),
            ),

            // Books list
            Expanded(
              child: _buildBooksList(booksState),
            ),
          ],
        ),
        bottomNavigationBar: const MiniPlayer(),
      ),
    );
  }

  Widget _buildBooksList(BooksState state) {
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
                ref.read(booksProvider.notifier).loadBooks(themeId: widget.theme.id);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.books.isEmpty) {
      return const Center(
        child: Text('Книг по этой теме не найдено'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(booksProvider.notifier).loadBooks(themeId: widget.theme.id);
      },
      child: ListView.builder(
        itemCount: state.books.length,
        itemBuilder: (context, index) {
          final book = state.books[index];
          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.zero,
            onTap: () {
              // Navigate to teachers by theme + book
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TeachersByThemeBookScreen(
                    theme: widget.theme,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.author != null)
                    Text('Автор: ${book.author!.name}'),
                  if (book.description != null)
                    Text(
                      book.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              isThreeLine: book.author != null && book.description != null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
