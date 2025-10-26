import 'package:flutter/material.dart';

/// Breadcrumbs widget to show navigation path
/// Supports multiline wrapping if path doesn't fit
class Breadcrumbs extends StatelessWidget {
  final List<String> path;
  final Color? textColor;
  final double? fontSize;

  const Breadcrumbs({
    super.key,
    required this.path,
    this.textColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = textColor ?? Theme.of(context).textTheme.bodySmall?.color;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (int i = 0; i < path.length; i++) ...[
          Text(
            path[i],
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: i == path.length - 1 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (i < path.length - 1)
            Text(
              ' > ',
              style: TextStyle(
                fontSize: fontSize,
                color: color,
              ),
            ),
        ],
      ],
    );
  }
}
