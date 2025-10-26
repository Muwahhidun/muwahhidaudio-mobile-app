/// Application-wide constants.
class AppConstants {
  /// Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  /// App info
  static const String appName = 'Islamic Audio Lessons';
  static const String appVersion = '1.0.0';

  /// Bookmarks
  static const int maxBookmarks = 20;

  /// Audio player
  static const double minPlaybackSpeed = 0.5;
  static const double maxPlaybackSpeed = 2.0;
  static const double defaultPlaybackSpeed = 1.0;

  /// Pagination
  static const int defaultPageSize = 20;

  /// Cache
  static const Duration cacheDuration = Duration(hours: 1);
}
