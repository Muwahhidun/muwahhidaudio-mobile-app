/// Validation utilities for form fields
class Validators {
  // Regex patterns
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final _passwordLetterRegex = RegExp(r'[A-Za-z]');
  static final _passwordDigitRegex = RegExp(r'\d');
  static final _passwordAllowedCharsRegex = RegExp(r'^[A-Za-z\d@$!%*?&]+$');
  static final _englishOnlyRegex = RegExp(r'^[a-zA-Z0-9\s@$!%*?&._+\-]+$');

  /// Validates username
  /// - 3-20 characters
  /// - Only English letters, digits, and underscore
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Логин обязателен';
    }

    if (!_usernameRegex.hasMatch(value)) {
      if (value.length < 3) {
        return 'Логин должен быть минимум 3 символа';
      }
      if (value.length > 20) {
        return 'Логин должен быть максимум 20 символов';
      }
      return 'Логин может содержать только английские буквы, цифры и подчеркивание';
    }

    return null;
  }

  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязателен';
    }

    if (!_emailRegex.hasMatch(value)) {
      return 'Некорректный email адрес';
    }

    // Check for English characters only
    if (!_englishOnlyRegex.hasMatch(value)) {
      return 'Email должен содержать только английские символы';
    }

    return null;
  }

  /// Validates password
  /// - Minimum 8 characters
  /// - Must contain at least one letter
  /// - Must contain at least one digit
  /// - Only English letters, digits, and special characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    }

    if (value.length < 8) {
      return 'Пароль должен быть минимум 8 символов';
    }

    if (!_passwordLetterRegex.hasMatch(value)) {
      return 'Пароль должен содержать хотя бы одну букву';
    }

    if (!_passwordDigitRegex.hasMatch(value)) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }

    if (!_passwordAllowedCharsRegex.hasMatch(value)) {
      return 'Пароль должен содержать только английские буквы, цифры и спецсимволы (@\$!%*?&)';
    }

    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Подтверждение пароля обязательно';
    }

    if (value != password) {
      return 'Пароли не совпадают';
    }

    return null;
  }

  /// Validates login or email field
  /// Can be either username or email
  static String? validateLoginOrEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Логин или email обязателен';
    }

    // Check for English characters only
    if (!_englishOnlyRegex.hasMatch(value)) {
      return 'Можно вводить только английские символы';
    }

    return null;
  }

  /// Validates that field contains only English characters
  static String? validateEnglishOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle this
    }

    if (!_englishOnlyRegex.hasMatch(value)) {
      return '$fieldName должен содержать только английские символы';
    }

    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName обязателен';
    }
    return null;
  }

  /// Validates SMTP host
  static String? validateSMTPHost(String? value) {
    if (value == null || value.isEmpty) {
      return 'SMTP хост обязателен';
    }
    return null;
  }

  /// Validates SMTP port
  static String? validateSMTPPort(String? value) {
    if (value == null || value.isEmpty) {
      return 'SMTP порт обязателен';
    }

    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return 'Порт должен быть от 1 до 65535';
    }

    return null;
  }

  /// Validates URL
  static String? validateURL(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL обязателен';
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'URL должен начинаться с http:// или https://';
      }
    } catch (e) {
      return 'Некорректный URL';
    }

    return null;
  }
}
