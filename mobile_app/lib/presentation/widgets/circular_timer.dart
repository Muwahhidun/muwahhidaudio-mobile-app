import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Circular countdown timer widget
/// Shows remaining time with color changes and warning at 5 seconds
class CircularTimer extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final double size;

  const CircularTimer({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final isWarning = remainingSeconds <= 5;
    final color = isWarning ? Colors.red : Colors.green;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: 1.0,
              color: Colors.white.withValues(alpha: 0.2),
              strokeWidth: 8,
            ),
          ),
          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _CircleProgressPainter(
              progress: progress,
              color: color,
              strokeWidth: 8,
            ),
          ),
          // Time text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'сек',
                style: TextStyle(
                  fontSize: size * 0.12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          // Warning pulse effect
          if (isWarning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Container(
                  width: size + (value * 10),
                  height: size + (value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 1.0 - value),
                      width: 2,
                    ),
                  ),
                );
              },
              onEnd: () {
                // Restart animation
              },
            ),
        ],
      ),
    );
  }
}

/// Custom painter for circular progress
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc (from top, clockwise)
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
