import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/teacher.dart';
import '../../../data/models/theme.dart';
import '../../providers/books_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../series/series_screen.dart';

class BooksByTeacherThemeScreen extends ConsumerStatefulWidget {
  final TeacherModel teacher;
  final AppThemeModel theme;

  const BooksByTeacherThemeScreen({
    super.key,
    required this.teacher,
    required this.theme,
  });

  @override
  ConsumerState<BooksByTeacherThemeScreen> createState() => _BooksByTeacherThemeScreenState();
}

class _BooksByTeacherThemeScreenState extends ConsumerState<BooksByTeacherThemeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(booksProvider.notifier).loadBooks(
        teacherId: widget.teacher.id,
        themeId: widget.theme.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Breadcrumbs(path: [
              'Лекторы',
              widget.teacher.name,
              widget.theme.name,
            ]),
          ),
          Expanded(child: _buildBody(context, ref, booksState)),
        ],
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
              onPressed: () => ref.read(booksProvider.notifier).loadBooks(
                teacherId: widget.teacher.id,
                themeId: widget.theme.id,
              ),
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
      onRefresh: () => ref.read(booksProvider.notifier).loadBooks(
        teacherId: widget.teacher.id,
        themeId: widget.theme.id,
      ),
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
                ],
              ),
              isThreeLine: book.description != null && book.author != null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeriesScreen(
                      breadcrumbs: [
                        'Лекторы',
                        widget.teacher.name,
                        widget.theme.name,
                        book.name,
                      ],
                      teacherId: widget.teacher.id,
                      themeId: widget.theme.id,
                      bookId: book.id,
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
