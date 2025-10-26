import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../providers/books_provider.dart';
import 'teachers_by_book_screen.dart';

class BooksListScreen extends ConsumerWidget {
  const BooksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
      ),
      body: _buildBody(context, ref, booksState),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppIcons.bookColor.withValues(alpha: 0.1),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeachersByBookScreen(book: book),
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
