import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// API configuration for the application.
class ApiConfig {
  /// Base URL for the API
  /// For Web: localhost works directly
  /// For Android emulator: 10.0.2.2 maps to host machine's localhost
  /// For iOS simulator: localhost works directly
  static String get baseUrl {
    // For web platform, use localhost
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    // For Android device, use local network IP
    if (Platform.isAndroid) {
      return 'http://192.168.3.216:8000';
    }

    // For iOS simulator and desktop, use localhost
    return 'http://localhost:8000';
  }

  /// API version prefix
  static const String apiPrefix = '/api';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

  /// Content endpoints
  static const String themesEndpoint = '/themes';
  static const String teachersEndpoint = '/teachers';
  static const String seriesEndpoint = '/series';
  static const String lessonsEndpoint = '/lessons';
  static const String testsEndpoint = '/tests';

  /// API timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
