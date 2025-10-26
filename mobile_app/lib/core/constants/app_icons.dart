import 'package:flutter/material.dart';

/// Константы иконок для моделей данных приложения
/// Использование единого источника истины для иконок обеспечивает единообразие UI
class AppIcons {
  AppIcons._(); // Приватный конструктор для предотвращения создания экземпляров

  // === Иконки контентных моделей ===

  /// Иконка для Тем (Theme)
  /// Категория / тематика уроков
  static const IconData theme = Icons.category;

  /// Иконка для Книг (Book)
  /// Книги, по которым ведутся уроки
  static const IconData book = Icons.book;

  /// Иконка для Авторов книг (BookAuthor)
  /// Авторы исламских книг (перо/писатель)
  static const IconData bookAuthor = Icons.edit;

  /// Иконка для Преподавателей (Teacher)
  /// Лекторы, которые ведут уроки
  static const IconData teacher = Icons.mic;

  /// Иконка для Серий уроков (Series)
  /// Серии/циклы связанных уроков
  static const IconData series = Icons.collections_bookmark;

  /// Иконка для Уроков (Lesson)
  /// Отдельные аудио уроки
  static const IconData lesson = Icons.headset;

  /// Иконка для Тестов (Test)
  /// Тесты для проверки знаний (шапочка выпускника)
  static const IconData test = Icons.school;

  // === Цвета для контентных моделей ===

  /// Цвет для Тем
  static const Color themeColor = Colors.blue;

  /// Цвет для Книг
  static const Color bookColor = Colors.orange;

  /// Цвет для Авторов
  static const Color bookAuthorColor = Colors.brown;

  /// Цвет для Преподавателей
  static const Color teacherColor = Colors.purple;

  /// Цвет для Серий
  static const Color seriesColor = Colors.teal;

  /// Цвет для Уроков
  static const Color lessonColor = Colors.deepPurple;

  /// Цвет для Тестов
  static const Color testColor = Colors.red;

  // === Иконки UI действий ===

  /// Добавить новый элемент
  static const IconData add = Icons.add;

  /// Редактировать элемент
  static const IconData edit = Icons.edit;

  /// Удалить элемент
  static const IconData delete = Icons.delete;

  /// Поиск
  static const IconData search = Icons.search;

  /// Очистить поле/фильтр
  static const IconData clear = Icons.clear;

  /// Очистить все фильтры
  static const IconData clearAll = Icons.clear_all;

  /// Навигация вперед
  static const IconData chevronRight = Icons.chevron_right;

  /// Воспроизведение аудио
  static const IconData play = Icons.play_arrow;

  /// Пауза аудио
  static const IconData pause = Icons.pause;

  /// Закладка
  static const IconData bookmark = Icons.bookmark;

  /// Закладка (не активная)
  static const IconData bookmarkBorder = Icons.bookmark_border;

  /// Настройки
  static const IconData settings = Icons.settings;

  /// Выход
  static const IconData logout = Icons.logout;

  /// Профиль пользователя
  static const IconData profile = Icons.person;

  /// Домашняя страница
  static const IconData home = Icons.home;

  /// Админ панель
  static const IconData admin = Icons.admin_panel_settings;
}
