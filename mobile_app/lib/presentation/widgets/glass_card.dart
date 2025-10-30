import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_effects.dart';

/// Карточка с эффектом глассморфизма (frosted glass)
/// Основной компонент UI для отображения контента с прозрачностью и размытием
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double? blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.blur,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(GlassEffects.borderRadiusCard);

    Widget content = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: GlassEffects.getBlurFilter(
          sigmaX: blur ?? GlassEffects.blurStrong,
          sigmaY: blur ?? GlassEffects.blurStrong,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? AppColors.getGlassOverlay(isDark),
            borderRadius: effectiveBorderRadius,
            border: border ??
                Border.all(
                  color: AppColors.getGlassBorder(isDark),
                  width: GlassEffects.borderWidth,
                ),
            boxShadow: boxShadow ?? GlassEffects.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
