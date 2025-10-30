import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'glass_effects.dart';

/// Конфигурация темы приложения с поддержкой глассморфизма
/// Поддерживает светлую и темную тему
class AppTheme {
  AppTheme._(); // Приватный конструктор

  // ============================================================================
  // СВЕТЛАЯ ТЕМА
  // ============================================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Цветовая схема
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        primaryContainer: AppColors.lightPrimaryLight,
        secondary: AppColors.lightAccent,
        secondaryContainer: AppColors.lightAccentLight,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightBackground,
        error: AppColors.error,
        onPrimary: AppColors.lightTextOnPrimary,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),

      // Фон приложения (будет перекрыт градиентом)
      scaffoldBackgroundColor: AppColors.lightBackground,

      // AppBar с glass-эффектом
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Карточки с glass-эффектом
      cardTheme: CardThemeData(
        color: AppColors.lightGlassOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusCard),
          side: BorderSide(
            color: AppColors.lightGlassBorder,
            width: GlassEffects.borderWidth,
          ),
        ),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassEffects.borderRadiusButton),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.2),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: BorderSide(color: AppColors.lightPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassEffects.borderRadiusButton),
          ),
        ),
      ),

      // Поля ввода с glass-эффектом
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGlassOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.lightGlassBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.lightGlassBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Типографика
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // Улучшенная читаемость
          color: AppColors.lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.lightTextHint,
        ),
      ),

      // Иконки
      iconTheme: IconThemeData(
        color: AppColors.lightPrimary,
        size: 24,
      ),

      // Диалоги
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusLarge),
        ),
      ),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GlassEffects.borderRadiusLarge),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ТЕМНАЯ ТЕМА
  // ============================================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Цветовая схема
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        primaryContainer: AppColors.darkPrimaryDark,
        secondary: AppColors.darkAccent,
        secondaryContainer: AppColors.darkAccentLight,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkBackground,
        error: AppColors.error,
        onPrimary: AppColors.darkTextOnPrimary,
        onSecondary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),

      // Фон приложения (будет перекрыт градиентом)
      scaffoldBackgroundColor: AppColors.darkBackground,

      // AppBar с glass-эффектом
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Карточки с glass-эффектом
      cardTheme: CardThemeData(
        color: AppColors.darkGlassOverlay,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusCard),
          side: BorderSide(
            color: AppColors.darkGlassBorder,
            width: GlassEffects.borderWidth,
          ),
        ),
      ),

      // Кнопки
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassEffects.borderRadiusButton),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.4),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: BorderSide(color: AppColors.darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassEffects.borderRadiusButton),
          ),
        ),
      ),

      // Поля ввода с glass-эффектом
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGlassOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.darkGlassBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.darkGlassBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusInput),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Типографика
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // Улучшенная читаемость
          color: AppColors.darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.darkTextHint,
        ),
      ),

      // Иконки
      iconTheme: IconThemeData(
        color: AppColors.darkPrimary,
        size: 24,
      ),

      // Диалоги
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassEffects.borderRadiusLarge),
        ),
      ),

      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GlassEffects.borderRadiusLarge),
          ),
        ),
      ),
    );
  }
}
