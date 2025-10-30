import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Градиентный фон с декоративными элементами
/// Используется как основной фон для всех экранов приложения
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showDecorations;

  const GradientBackground({
    super.key,
    required this.child,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = AppColors.getGradient(isDark);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        children: [
          // Декоративные круги для глубины (опционально)
          if (showDecorations) ...[
            Positioned(
              top: -100,
              right: -100,
              child: _DecorativeCircle(
                size: 300,
                opacity: isDark ? 0.03 : 0.05,
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: _DecorativeCircle(
                size: 400,
                opacity: isDark ? 0.02 : 0.04,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              right: -80,
              child: _DecorativeCircle(
                size: 200,
                opacity: isDark ? 0.025 : 0.045,
              ),
            ),
          ],
          // Основной контент
          child,
        ],
      ),
    );
  }
}

/// Декоративный круг для создания глубины фона
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
