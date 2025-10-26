import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/system_settings.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;

  Future<void> _resendVerification() async {
    setState(() {
      _isResending = true;
    });

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final response = await apiClient.resendVerification(
        ResendVerificationRequest(email: widget.email),
      );

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Проверьте вашу почту',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'Мы отправили письмо с подтверждением на адрес:',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Что делать дальше:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInstruction('1', 'Откройте вашу почту'),
                      const SizedBox(height: 8),
                      _buildInstruction('2', 'Найдите письмо от нас'),
                      const SizedBox(height: 8),
                      _buildInstruction(
                          '3', 'Нажмите на ссылку подтверждения'),
                      const SizedBox(height: 8),
                      _buildInstruction('4',
                          'Вернитесь и войдите в приложение'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Resend section
                Text(
                  'Не получили письмо?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isResending ? null : _resendVerification,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isResending
                      ? 'Отправка...'
                      : 'Отправить письмо повторно'),
                ),
                const SizedBox(height: 32),

                // Back to login button
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to login
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                    child: Text('Вернуться к входу'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
