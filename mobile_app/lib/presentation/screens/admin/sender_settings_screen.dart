import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/system_settings_provider.dart';
import '../../../data/models/system_settings.dart';
import '../../../core/utils/validators.dart';

class SenderSettingsScreen extends ConsumerStatefulWidget {
  const SenderSettingsScreen({super.key});

  @override
  ConsumerState<SenderSettingsScreen> createState() => _SenderSettingsScreenState();
}

class _SenderSettingsScreenState extends ConsumerState<SenderSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for sender settings
  late TextEditingController _emailFromNameController;
  late TextEditingController _emailFromAddressController;
  late TextEditingController _frontendUrlController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _emailFromNameController = TextEditingController();
    _emailFromAddressController = TextEditingController();
    _frontendUrlController = TextEditingController();

    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(systemSettingsProvider.notifier).loadSMTPSettings();
    });
  }

  @override
  void dispose() {
    _emailFromNameController.dispose();
    _emailFromAddressController.dispose();
    _frontendUrlController.dispose();
    super.dispose();
  }

  void _populateFields(SMTPSettings settings) {
    _emailFromNameController.text = settings.emailFromName;
    _emailFromAddressController.text = settings.emailFromAddress;
    _frontendUrlController.text = settings.frontendUrl;
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Get existing settings to preserve SMTP fields
    final existingSettings = ref.read(systemSettingsProvider).smtpSettings;
    if (existingSettings == null) return;

    final settings = SMTPSettings(
      smtpHost: existingSettings.smtpHost,
      smtpPort: existingSettings.smtpPort,
      smtpUsername: existingSettings.smtpUsername,
      smtpPassword: existingSettings.smtpPassword,
      smtpUseSsl: existingSettings.smtpUseSsl,
      emailFromName: _emailFromNameController.text.trim(),
      emailFromAddress: _emailFromAddressController.text.trim(),
      frontendUrl: _frontendUrlController.text.trim(),
    );

    final success =
        await ref.read(systemSettingsProvider.notifier).saveSMTPSettings(settings);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки отправителя успешно сохранены'),
          backgroundColor: Colors.green,
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
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (settingsState.error != null && settingsState.smtpSettings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Настройка отправителя')),
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка отправителя'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: settingsState.isSaving ? null : _handleSave,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Эти данные будут отображаться как отправитель в email-уведомлениях',
                          style: TextStyle(color: Colors.green.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sender Settings
              Text(
                'Информация об отправителе',
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
                  helperText: 'Будет показано в поле "От кого" в письме',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
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
                  helperText: 'Email адрес отправителя (обычно должен совпадать с SMTP пользователем)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
                  helperText: 'Используется в ссылках для верификации email и восстановления пароля',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.validateURL,
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
      ),
    );
  }
}
