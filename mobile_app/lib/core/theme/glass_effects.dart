import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Параметры эффектов глассморфизма (frosted glass)
/// Предоставляет унифицированные настройки для создания стеклянных элементов UI
class GlassEffects {
  GlassEffects._(); // Приватный конструктор

  // ============================================================================
  // ПАРАМЕТРЫ РАЗМЫТИЯ (Blur)
  // ============================================================================

  /// Выраженное размытие для основных элементов (карточки, контейнеры)
  static const double blurStrong = 30.0;

  /// Среднее размытие для вторичных элементов
  static const double blurMedium = 20.0;

  /// Легкое размытие для тонких акцентов
  static const double blurLight = 10.0;

  // ============================================================================
  // ПАРАМЕТРЫ ПРОЗРАЧНОСТИ (Opacity)
  // ============================================================================

  /// Прозрачность для светлой темы (frosted glass)
  static const double opacityLight = 0.2;

  /// Прозрачность для темной темы (более прозрачный для контраста)
  static const double opacityDark = 0.15;

  /// Прозрачность границы
  static const double borderOpacity = 0.3;

  // ============================================================================
  // ПАРАМЕТРЫ ГРАНИЦ (Border)
  // ============================================================================

  /// Стандартная толщина границы
  static const double borderWidth = 1.5;

  /// Тонкая граница для элементов меньшего размера
  static const double borderWidthThin = 1.0;

  /// Радиус скругления углов для карточек
  static const double borderRadiusCard = 16.0;

  /// Радиус скругления для кнопок
  static const double borderRadiusButton = 12.0;

  /// Радиус скругления для input полей
  static const double borderRadiusInput = 12.0;

  /// Радиус скругления для больших контейнеров
  static const double borderRadiusLarge = 24.0;

  // ============================================================================
  // ПАРАМЕТРЫ ТЕНЕЙ (Shadow)
  // ============================================================================

  /// Мягкая тень для карточек
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];

  /// Тень для поднятых элементов (elevated)
  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];

  /// Легкая тень для мелких элементов
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // ============================================================================
  // ГОТОВЫЕ ДЕКОРАЦИИ (BoxDecoration)
  // ============================================================================

  /// Создать glass decoration для карточки
  static BoxDecoration getGlassDecoration({
    required bool isDark,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
  }) {
    return BoxDecoration(
      color: AppColors.getGlassOverlay(isDark),
      borderRadius: borderRadius ?? BorderRadius.circular(borderRadiusCard),
      border: border ??
          Border.all(
            color: AppColors.getGlassBorder(isDark),
            width: borderWidth,
          ),
      boxShadow: shadows ?? cardShadow,
    );
  }

  /// Создать glass decoration для кнопки
  static BoxDecoration getGlassButtonDecoration({
    required bool isDark,
    Color? overlayColor,
  }) {
    return BoxDecoration(
      color: overlayColor ?? AppColors.getGlassOverlay(isDark),
      borderRadius: BorderRadius.circular(borderRadiusButton),
      border: Border.all(
        color: AppColors.getGlassBorder(isDark),
        width: borderWidth,
      ),
      boxShadow: lightShadow,
    );
  }

  /// Создать glass decoration для input поля
  static BoxDecoration getGlassInputDecoration({
    required bool isDark,
  }) {
    return BoxDecoration(
      color: AppColors.getGlassOverlay(isDark),
      borderRadius: BorderRadius.circular(borderRadiusInput),
      border: Border.all(
        color: AppColors.getGlassBorder(isDark),
        width: borderWidthThin,
      ),
    );
  }

  // ============================================================================
  // BACKDROP FILTER
  // ============================================================================

  /// Создать ImageFilter для размытия фона
  static ImageFilter getBlurFilter({double? sigmaX, double? sigmaY}) {
    return ImageFilter.blur(
      sigmaX: sigmaX ?? blurStrong,
      sigmaY: sigmaY ?? blurStrong,
    );
  }

  /// Виджет BackdropFilter с настройками glass
  static Widget createGlassBlur({
    required Widget child,
    double? blur,
  }) {
    return BackdropFilter(
      filter: getBlurFilter(sigmaX: blur, sigmaY: blur),
      child: child,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Создать полный glass container с размытием
  static Widget createGlassContainer({
    required bool isDark,
    required Widget child,
    double? blur,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: getGlassDecoration(
        isDark: isDark,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(borderRadiusCard),
        child: BackdropFilter(
          filter: getBlurFilter(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
