import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/system_settings.dart';
import '../../data/api/api_client.dart';
import '../../data/api/dio_provider.dart';

/// System settings state
class SystemSettingsState {
  final SMTPSettings? smtpSettings;
  final bool isLoading;
  final bool isSaving;
  final bool isTesting;
  final String? error;
  final String? successMessage;

  SystemSettingsState({
    this.smtpSettings,
    this.isLoading = false,
    this.isSaving = false,
    this.isTesting = false,
    this.error,
    this.successMessage,
  });

  SystemSettingsState copyWith({
    SMTPSettings? smtpSettings,
    bool? isLoading,
    bool? isSaving,
    bool? isTesting,
    String? error,
    String? successMessage,
  }) {
    return SystemSettingsState(
      smtpSettings: smtpSettings ?? this.smtpSettings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isTesting: isTesting ?? this.isTesting,
      error: error,
      successMessage: successMessage,
    );
  }

  SystemSettingsState clearMessages() {
    return SystemSettingsState(
      smtpSettings: smtpSettings,
      isLoading: isLoading,
      isSaving: isSaving,
      isTesting: isTesting,
    );
  }
}

/// System settings notifier
class SystemSettingsNotifier extends StateNotifier<SystemSettingsState> {
  final ApiClient _apiClient;

  SystemSettingsNotifier(this._apiClient) : super(SystemSettingsState());

  /// Load SMTP settings
  Future<void> loadSMTPSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final settings = await _apiClient.getSMTPSettings();

      state = state.copyWith(
        smtpSettings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки настроек: ${e.toString()}',
      );
    }
  }

  /// Save SMTP settings
  Future<bool> saveSMTPSettings(SMTPSettings settings) async {
    try {
      state = state.copyWith(isSaving: true, error: null, successMessage: null);

      final updatedSettings = await _apiClient.updateSMTPSettings(settings);

      state = state.copyWith(
        smtpSettings: updatedSettings,
        isSaving: false,
        successMessage: 'Настройки успешно сохранены',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Ошибка сохранения: ${e.toString()}',
      );
      return false;
    }
  }

  /// Send test email
  Future<bool> sendTestEmail(String testEmail) async {
    try {
      state = state.copyWith(isTesting: true, error: null, successMessage: null);

      final response = await _apiClient.sendTestEmail(
        TestEmailRequest(testEmail: testEmail),
      );

      state = state.copyWith(
        isTesting: false,
        successMessage: response.success
            ? response.message
            : null,
        error: !response.success
            ? response.message
            : null,
      );

      return response.success;
    } catch (e) {
      state = state.copyWith(
        isTesting: false,
        error: 'Ошибка отправки: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.clearMessages();
  }
}

/// System settings provider
final systemSettingsProvider =
    StateNotifierProvider<SystemSettingsNotifier, SystemSettingsState>((ref) {
  final apiClient = ApiClient(DioProvider.getDio());
  return SystemSettingsNotifier(apiClient);
});
