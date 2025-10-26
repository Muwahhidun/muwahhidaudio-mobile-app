import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/system_settings_provider.dart';
import '../../../data/models/system_settings.dart';
import '../../../core/utils/validators.dart';

class NotificationsSettingsTab extends ConsumerStatefulWidget {
  const NotificationsSettingsTab({super.key});

  @override
  ConsumerState<NotificationsSettingsTab> createState() =>
      _NotificationsSettingsTabState();
}

class _NotificationsSettingsTabState
    extends ConsumerState<NotificationsSettingsTab> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for SMTP settings
  late TextEditingController _smtpHostController;
  late TextEditingController _smtpPortController;
  late TextEditingController _smtpUsernameController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _emailFromNameController;
  late TextEditingController _emailFromAddressController;
  late TextEditingController _frontendUrlController;
  late TextEditingController _testEmailController;

  bool _smtpUseSsl = true;
  bool _obscurePassword = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _smtpHostController = TextEditingController();
    _smtpPortController = TextEditingController();
    _smtpUsernameController = TextEditingController();
    _smtpPasswordController = TextEditingController();
    _emailFromNameController = TextEditingController();
    _emailFromAddressController = TextEditingController();
    _frontendUrlController = TextEditingController();
    _testEmailController = TextEditingController();

    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemSettingsProvider.notifier).loadSMTPSettings();
    });
  }

  @override
  void dispose() {
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUsernameController.dispose();
    _smtpPasswordController.dispose();
    _emailFromNameController.dispose();
    _emailFromAddressController.dispose();
    _frontendUrlController.dispose();
    _testEmailController.dispose();
    super.dispose();
  }

  void _populateFields(SMTPSettings settings) {
    _smtpHostController.text = settings.smtpHost;
    _smtpPortController.text = settings.smtpPort.toString();
    _smtpUsernameController.text = settings.smtpUsername;
    _smtpPasswordController.text = settings.smtpPassword;
    _emailFromNameController.text = settings.emailFromName;
    _emailFromAddressController.text = settings.emailFromAddress;
    _frontendUrlController.text = settings.frontendUrl;
    _smtpUseSsl = settings.smtpUseSsl;
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = SMTPSettings(
      smtpHost: _smtpHostController.text.trim(),
      smtpPort: int.parse(_smtpPortController.text.trim()),
      smtpUsername: _smtpUsernameController.text.trim(),
      smtpPassword: _smtpPasswordController.text,
      smtpUseSsl: _smtpUseSsl,
      emailFromName: _emailFromNameController.text.trim(),
      emailFromAddress: _emailFromAddressController.text.trim(),
      frontendUrl: _frontendUrlController.text.trim(),
    );

    final success =
        await ref.read(systemSettingsProvider.notifier).saveSMTPSettings(settings);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки успешно сохранены'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleTestEmail() async {
    final testEmail = _testEmailController.text.trim();

    if (testEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите email для тестирования'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final emailError = Validators.validateEmail(testEmail);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success =
        await ref.read(systemSettingsProvider.notifier).sendTestEmail(testEmail);

    if (mounted) {
      final state = ref.read(systemSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? state.successMessage ?? 'Тестовое письмо отправлено'
                : state.error ?? 'Ошибка отправки',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(systemSettingsProvider);

    // Populate fields when settings are loaded
    if (settingsState.smtpSettings != null && !_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateFields(settingsState.smtpSettings!);
        setState(() {});
      });
    }

    if (settingsState.isLoading && settingsState.smtpSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (settingsState.error != null && settingsState.smtpSettings == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(settingsState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(systemSettingsProvider.notifier).loadSMTPSettings();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Настройки SMTP для отправки email-уведомлений (верификация, восстановление пароля)',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SMTP Server Settings
            Text(
              'Настройки SMTP сервера',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _smtpHostController,
              decoration: const InputDecoration(
                labelText: 'SMTP хост *',
                hintText: 'smtp.mail.ru',
                prefixIcon: Icon(Icons.dns),
              ),
              validator: Validators.validateSMTPHost,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _smtpPortController,
              decoration: const InputDecoration(
                labelText: 'SMTP порт *',
                hintText: '465',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
              validator: Validators.validateSMTPPort,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _smtpUsernameController,
              decoration: const InputDecoration(
                labelText: 'SMTP пользователь *',
                hintText: 'user@mail.ru',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'SMTP пользователь'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _smtpPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'SMTP пароль *',
                hintText: 'Пароль приложения',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'SMTP пароль'),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Использовать SSL'),
              subtitle: const Text('Рекомендуется для безопасного соединения'),
              value: _smtpUseSsl,
              onChanged: (value) {
                setState(() {
                  _smtpUseSsl = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Email Settings
            Text(
              'Настройки отправителя',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailFromNameController,
              decoration: const InputDecoration(
                labelText: 'Имя отправителя *',
                hintText: 'Muwahhid',
                prefixIcon: Icon(Icons.badge),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'Имя отправителя'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailFromAddressController,
              decoration: const InputDecoration(
                labelText: 'Email отправителя *',
                hintText: 'noreply@muwahhid.ru',
                prefixIcon: Icon(Icons.email),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 32),

            // Frontend URL
            Text(
              'URL приложения',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _frontendUrlController,
              decoration: const InputDecoration(
                labelText: 'URL фронтенда *',
                hintText: 'http://localhost:3065',
                helperText: 'Используется в ссылках для верификации email',
                prefixIcon: Icon(Icons.link),
              ),
              validator: Validators.validateURL,
            ),
            const SizedBox(height: 32),

            // Test Email Section
            Text(
              'Тестирование',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _testEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Тестовый email',
                      hintText: 'test@example.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: settingsState.isTesting ? null : _handleTestEmail,
                  icon: settingsState.isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    settingsState.isTesting ? 'Отправка...' : 'Тест',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: settingsState.isSaving ? null : _handleSave,
                icon: settingsState.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    settingsState.isSaving
                        ? 'Сохранение...'
                        : 'Сохранить настройки',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
