import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/dio_provider.dart';

class EmailVerifiedScreen extends ConsumerStatefulWidget {
  final String? token;

  const EmailVerifiedScreen({
    super.key,
    this.token,
  });

  @override
  ConsumerState<EmailVerifiedScreen> createState() =>
      _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends ConsumerState<EmailVerifiedScreen> {
  bool _isVerifying = true;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _email;
  String? _username;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    if (widget.token == null) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _errorMessage = 'Токен верификации не найден';
      });
      return;
    }

    try {
      final apiClient = ApiClient(DioProvider.getDio());
      final response = await apiClient.verifyEmail(widget.token!);

      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
          _email = response.email;
          _username = response.username;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccess = false;
          _errorMessage = 'Ошибка верификации. Возможно, ссылка устарела или уже использована.';
        });
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
            child: _isVerifying
                ? _buildVerifyingState(theme)
                : _isSuccess
                    ? _buildSuccessState(theme)
                    : _buildErrorState(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyingState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          'Проверяем ваш email...',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Email подтвержден!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Success message
        Text(
          'Ваш email успешно подтвержден.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        if (_username != null) ...[
          Text(
            'Логин: $_username',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],

        if (_email != null) ...[
          Text(
            'Email: $_email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Теперь вы можете войти в приложение используя свой логин или email',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Login button
        ElevatedButton(
          onPressed: () {
            // Navigate back to login
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Text('Войти в приложение'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Error icon
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Ошибка верификации',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Error message
        Text(
          _errorMessage ?? 'Не удалось подтвердить email',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Info box
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
                  Icon(Icons.help_outline, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Возможные причины:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• Ссылка устарела (действительна 30 дней)\n'
                '• Email уже был подтвержден ранее\n'
                '• Некорректная ссылка',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back button
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
    );
  }
}
