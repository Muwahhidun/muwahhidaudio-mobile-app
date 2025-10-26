import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../data/models/book.dart';
import '../../providers/teachers_provider.dart';
import '../../widgets/breadcrumbs.dart';
import '../series/series_screen.dart';

class TeachersByBookScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const TeachersByBookScreen({super.key, required this.book});

  @override
  ConsumerState<TeachersByBookScreen> createState() => _TeachersByBookScreenState();
}

class _TeachersByBookScreenState extends ConsumerState<TeachersByBookScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(teachersProvider.notifier).loadTeachers(bookId: widget.book.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachersState = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Лекторы'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Breadcrumbs(path: ['Книги', widget.book.name]),
          ),
          Expanded(child: _buildBody(context, ref, teachersState)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TeachersState state) {
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
              onPressed: () => ref.read(teachersProvider.notifier).loadTeachers(bookId: widget.book.id),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.teachers.isEmpty) {
      return const Center(
        child: Text('Лекторы не найдены'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teachersProvider.notifier).loadTeachers(bookId: widget.book.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.teachers.length,
        itemBuilder: (context, index) {
          final teacher = state.teachers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppIcons.teacherColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIcons.teacher,
                  color: AppIcons.teacherColor,
                  size: 24,
                ),
              ),
              title: Text(
                teacher.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: teacher.biography != null
                  ? Text(
                      teacher.biography!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeriesScreen(
                      breadcrumbs: [
                        'Книги',
                        widget.book.name,
                        teacher.name,
                      ],
                      bookId: widget.book.id,
                      teacherId: teacher.id,
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
