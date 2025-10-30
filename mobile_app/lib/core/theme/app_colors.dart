import 'package:flutter/material.dart';

/// Цветовая палитра приложения для светлой и темной темы
/// Поддерживает глассморфизм с зелеными оттенками в исламском стиле
class AppColors {
  AppColors._(); // Приватный конструктор

  // ============================================================================
  // СВЕТЛАЯ ТЕМА
  // ============================================================================

  /// Градиент фона для светлой темы (сверху вниз)
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8F5E9), // Очень светло-зеленый
      Color(0xFFC8E6C9), // Светло-зеленый
      Color(0xFFA5D6A7), // Средне-светло-зеленый
      Color(0xFF81C784), // Средне-зеленый
    ],
  );

  /// Основной зеленый цвет (светлая тема)
  static const Color lightPrimary = Color(0xFF2E7D32); // Исламский зеленый
  static const Color lightPrimaryDark = Color(0xFF1B5E20);
  static const Color lightPrimaryLight = Color(0xFF4CAF50);

  /// Акцентный цвет (золотой)
  static const Color lightAccent = Color(0xFFFFB300);
  static const Color lightAccentLight = Color(0xFFFFD54F);

  /// Фон и поверхности
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;

  /// Текст
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF424242); // Темнее для лучшего контраста
  static const Color lightTextHint = Color(0xFF616161); // Темнее для лучшего контраста
  static const Color lightTextOnPrimary = Colors.white;

  /// Glass overlay для светлой темы
  static Color get lightGlassOverlay => Colors.white.withValues(alpha: 0.35); // Увеличена непрозрачность
  static Color get lightGlassBorder => Colors.white.withValues(alpha: 0.4); // Увеличена непрозрачность

  // ============================================================================
  // ТЕМНАЯ ТЕМА
  // ============================================================================

  /// Градиент фона для темной темы (сверху вниз)
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E20), // Темно-зеленый
      Color(0xFF0F3A14), // Очень темно-зеленый
      Color(0xFF0A2A0F), // Почти черный с зеленым
      Color(0xFF051F0A), // Очень темный зеленый
    ],
  );

  /// Основной зеленый цвет (темная тема)
  static const Color darkPrimary = Color(0xFF66BB6A); // Светло-зеленый
  static const Color darkPrimaryDark = Color(0xFF4CAF50);
  static const Color darkPrimaryLight = Color(0xFF81C784);

  /// Акцентный цвет (золотой) - более яркий для темной темы
  static const Color darkAccent = Color(0xFFFFD54F);
  static const Color darkAccentLight = Color(0xFFFFE082);

  /// Фон и поверхности
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  /// Текст
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE0E0E0); // Светлее для лучшего контраста
  static const Color darkTextHint = Color(0xFFBDBDBD); // Светлее для лучшего контраста
  static const Color darkTextOnPrimary = Color(0xFF000000);

  /// Glass overlay для темной темы
  static Color get darkGlassOverlay => Colors.white.withValues(alpha: 0.25); // Увеличена непрозрачность
  static Color get darkGlassBorder => Colors.white.withValues(alpha: 0.3); // Увеличена непрозрачность

  // ============================================================================
  // SEMANTIC COLORS (общие для обеих тем)
  // ============================================================================

  /// Цвета состояний
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFC62828);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ============================================================================
  // ICON COLORS (из AppIcons, но в цветовой палитре)
  // ============================================================================

  static const Color themeIconColor = Colors.blue;
  static const Color bookIconColor = Colors.orange;
  static const Color authorIconColor = Colors.brown;
  static const Color teacherIconColor = Colors.purple;
  static const Color seriesIconColor = Colors.teal;
  static const Color lessonIconColor = Colors.deepPurple;
  static const Color testIconColor = Colors.red;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Получить градиент для текущей темы
  static LinearGradient getGradient(bool isDark) {
    return isDark ? darkGradient : lightGradient;
  }

  /// Получить glass overlay для текущей темы
  static Color getGlassOverlay(bool isDark) {
    return isDark ? darkGlassOverlay : lightGlassOverlay;
  }

  /// Получить glass border для текущей темы
  static Color getGlassBorder(bool isDark) {
    return isDark ? darkGlassBorder : lightGlassBorder;
  }

  /// Получить primary color для текущей темы
  static Color getPrimary(bool isDark) {
    return isDark ? darkPrimary : lightPrimary;
  }

  /// Получить текстовый цвет для текущей темы
  static Color getTextPrimary(bool isDark) {
    return isDark ? darkTextPrimary : lightTextPrimary;
  }
}
