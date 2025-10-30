import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider для управления темой приложения (светлая/темная)
/// Сохраняет выбор пользователя в локальное хранилище
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Notifier для управления состоянием темы
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Загружает сохраненную тему из локального хранилища
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        state = _stringToThemeMode(savedTheme);
      }
    } catch (e) {
      // Если не удалось загрузить, используем светлую тему по умолчанию
      debugPrint('Failed to load theme: $e');
    }
  }

  /// Переключает тему между светлой и темной
  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }

  /// Устанавливает конкретную тему
  Future<void> setTheme(ThemeMode themeMode) async {
    state = themeMode;
    await _saveTheme(themeMode);
  }

  /// Сохраняет тему в локальное хранилище
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(themeMode));
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }

  /// Проверяет, используется ли темная тема
  bool get isDarkMode => state == ThemeMode.dark;

  /// Преобразует ThemeMode в строку для сохранения
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Преобразует строку в ThemeMode
  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
