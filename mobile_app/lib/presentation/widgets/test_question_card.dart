import 'package:flutter/material.dart';
import '../../data/models/test.dart';
import 'glass_card.dart';

/// Card widget for displaying a test question with answer options
class TestQuestionCard extends StatelessWidget {
  final TestQuestion question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;
  final bool enabled;

  const TestQuestionCard({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question text
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Answer options
          ...List.generate(
            question.options.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnswerOption(
                context: context,
                index: index,
                text: question.options[index],
                isSelected: selectedAnswer == index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption({
    required BuildContext context,
    required int index,
    required String text,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onAnswerSelected(index) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Option letter (A, B, C, D)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Option text
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              // Selected checkmark
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
