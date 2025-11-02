import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';

class AdminHelpScreen extends StatelessWidget {
  const AdminHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Справка для администраторов'),
        ),
        body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Общие сведения',
            Icons.info_outline,
            Colors.blue,
            [
              _HelpItem(
                'О приложении',
                'Приложение для управления исламскими аудио-уроками. Позволяет администраторам управлять контентом: темами, книгами, авторами, преподавателями, сериями уроков и тестами.',
              ),
              _HelpItem(
                'Структура контента',
                'Иерархия: Тема → Автор книги → Книга → Серия уроков → Урок\n\n'
                'Каждая серия принадлежит определённой теме, книге и преподавателю. '
                'Уроки содержат аудио-файлы и могут иметь тесты для проверки знаний.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление темами',
            AppIcons.theme,
            AppIcons.themeColor,
            [
              _HelpItem(
                'Создание темы',
                '1. Откройте раздел "Темы"\n'
                '2. Нажмите кнопку "+" в правом нижнем углу\n'
                '3. Заполните название (обязательно) и описание\n'
                '4. Нажмите "Создать"',
              ),
              _HelpItem(
                'Редактирование',
                'Нажмите на карточку темы, измените данные и сохраните. '
                'Можно менять название, описание и статус активности.',
              ),
              _HelpItem(
                'Активация/деактивация',
                'Используйте переключатель рядом с темой. Неактивные темы скрыты от обычных пользователей, но видны администраторам.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление авторами',
            AppIcons.bookAuthor,
            AppIcons.bookAuthorColor,
            [
              _HelpItem(
                'Добавление автора',
                'Авторы книг - это классические исламские учёные. '
                'Укажите имя автора и краткую биографию.',
              ),
              _HelpItem(
                'Важно',
                'Перед добавлением книги убедитесь, что автор уже создан в системе.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление книгами',
            AppIcons.book,
            AppIcons.bookColor,
            [
              _HelpItem(
                'Создание книги',
                '1. Выберите автора из списка\n'
                '2. Выберите тему, к которой относится книга\n'
                '3. Введите название книги\n'
                '4. Добавьте описание (необязательно)',
              ),
              _HelpItem(
                'Связи',
                'Каждая книга должна быть связана с автором и темой. '
                'Это помогает пользователям находить нужный контент.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление преподавателями',
            AppIcons.teacher,
            AppIcons.teacherColor,
            [
              _HelpItem(
                'Добавление преподавателя',
                'Преподаватели - это современные учителя, которые ведут уроки. '
                'Укажите имя и краткую биографию.',
              ),
              _HelpItem(
                'Фото преподавателя',
                'Можно добавить URL фотографии преподавателя для отображения в приложении.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление сериями',
            AppIcons.series,
            AppIcons.seriesColor,
            [
              _HelpItem(
                'Создание серии',
                '1. Выберите книгу, по которой ведётся серия\n'
                '2. Выберите преподавателя\n'
                '3. Укажите год проведения\n'
                '4. Добавьте описание (необязательно)',
              ),
              _HelpItem(
                'Автоматическое заполнение',
                'При выборе книги, тема подставляется автоматически из выбранной книги.',
              ),
              _HelpItem(
                'Уникальность',
                'Комбинация книга + преподаватель + год должна быть уникальной.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление уроками',
            AppIcons.lesson,
            AppIcons.lessonColor,
            [
              _HelpItem(
                'Добавление урока',
                '1. Выберите серию уроков\n'
                '2. Укажите название урока\n'
                '3. Укажите номер урока в серии\n'
                '4. Загрузите аудио-файл (MP3)\n'
                '5. Добавьте описание (необязательно)',
              ),
              _HelpItem(
                'Аудио-файлы',
                'Поддерживаются файлы в формате MP3. '
                'Файлы должны быть загружены на сервер и доступны по URL.',
              ),
              _HelpItem(
                'Нумерация',
                'Рекомендуется нумеровать уроки последовательно (1, 2, 3...) для удобства пользователей.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Управление тестами',
            AppIcons.test,
            AppIcons.testColor,
            [
              _HelpItem(
                'Создание теста',
                '1. Выберите серию уроков\n'
                '2. Введите название теста\n'
                '3. Добавьте описание\n'
                '4. Укажите проходной балл (в процентах)',
              ),
              _HelpItem(
                'Ограничение',
                'Для каждой серии можно создать только ОДИН тест. '
                'Это обеспечивает целостность данных.',
              ),
              _HelpItem(
                'Вопросы',
                'После создания теста добавьте вопросы с вариантами ответов. '
                'Отметьте правильные ответы для автоматической проверки.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Пагинация',
            Icons.pages,
            Colors.purple,
            [
              _HelpItem(
                'Навигация по страницам',
                'Все списки показывают по 10 элементов на странице. '
                'Используйте кнопки ← и → внизу экрана для перехода между страницами.',
              ),
              _HelpItem(
                'Счётчик',
                'Внизу каждого списка отображается: "Всего: X | Страница Y из Z"',
              ),
            ],
          ),

          _buildSection(
            context,
            'Поиск',
            Icons.search,
            Colors.orange,
            [
              _HelpItem(
                'Как искать',
                'Введите текст в поле поиска вверху экрана. '
                'Поиск работает по названию и описанию элементов.',
              ),
              _HelpItem(
                'Очистка поиска',
                'Нажмите кнопку "×" в поле поиска или очистите текст вручную.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Статистика',
            Icons.bar_chart,
            Colors.cyan,
            [
              _HelpItem(
                'Общая статистика',
                'Раздел "Статистика" показывает:\n'
                '• Общее количество тем, книг, авторов\n'
                '• Количество преподавателей и серий\n'
                '• Общее количество уроков\n'
                '• Количество уроков с аудио-файлами\n'
                '• Количество тестов',
              ),
              _HelpItem(
                'Обновление',
                'Статистика обновляется автоматически при загрузке страницы.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Советы и рекомендации',
            Icons.lightbulb_outline,
            Colors.amber,
            [
              _HelpItem(
                'Порядок создания контента',
                '1. Создайте темы (Акыда, Фикх, Адаб и т.д.)\n'
                '2. Добавьте авторов книг\n'
                '3. Создайте книги, связав их с темами и авторами\n'
                '4. Добавьте преподавателей\n'
                '5. Создайте серии уроков\n'
                '6. Загрузите уроки с аудио-файлами\n'
                '7. Создайте тесты для проверки знаний',
              ),
              _HelpItem(
                'Проверка данных',
                'Перед публикацией нового контента проверьте:\n'
                '• Правильность написания названий\n'
                '• Корректность связей между элементами\n'
                '• Работоспособность аудио-файлов\n'
                '• Правильность ответов в тестах',
              ),
              _HelpItem(
                'Деактивация',
                'Вместо удаления элементов лучше их деактивировать. '
                'Это сохранит целостность данных и позволит при необходимости восстановить контент.',
              ),
            ],
          ),

          _buildSection(
            context,
            'Решение проблем',
            Icons.build,
            Colors.red,
            [
              _HelpItem(
                'Элемент не сохраняется',
                '1. Проверьте, что все обязательные поля заполнены\n'
                '2. Убедитесь, что выбраны все необходимые связи (тема, автор и т.д.)\n'
                '3. Проверьте подключение к интернету',
              ),
              _HelpItem(
                'Не загружается список',
                '1. Проверьте подключение к интернету\n'
                '2. Попробуйте обновить страницу (свайп вниз)\n'
                '3. Если проблема сохраняется, обратитесь к разработчикам',
              ),
              _HelpItem(
                'Ошибка при удалении',
                'Некоторые элементы нельзя удалить, если к ним привязаны другие данные. '
                'Например, нельзя удалить тему, если к ней привязаны книги. '
                'Сначала удалите или деактивируйте зависимые элементы.',
              ),
            ],
          ),

          const SizedBox(height: 32),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_support, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Нужна помощь?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Если у вас возникли вопросы или проблемы, которые не описаны в этой справке, обратитесь к техническому администратору или разработчикам приложения.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_HelpItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildHelpItem(context, item)),
      ],
    );
  }

  Widget _buildHelpItem(BuildContext context, _HelpItem item) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.content,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String title;
  final String content;

  _HelpItem(this.title, this.content);
}
