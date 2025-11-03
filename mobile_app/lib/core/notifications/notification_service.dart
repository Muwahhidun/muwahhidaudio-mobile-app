import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import '../logger.dart';

/// Service for managing download notifications and app badge
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static const int _downloadChannelId = 1000;
  static const String _downloadChannelIdString = 'downloads';
  static const String _downloadChannelName = 'Загрузки';
  static const String _downloadChannelDescription = 'Уведомления о загрузке уроков';

  // Track active downloads for badge counter
  final Set<int> _activeDownloads = {};

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android settings
      const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_music_note');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for downloads
      const androidChannel = AndroidNotificationChannel(
        _downloadChannelIdString,
        _downloadChannelName,
        description: _downloadChannelDescription,
        importance: Importance.low, // Low importance = no sound
        enableVibration: false,
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
      logger.i('NotificationService initialized');
    } catch (e) {
      logger.e('Failed to initialize NotificationService', error: e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    logger.i('Notification tapped: ${response.id}');
    // TODO: Navigate to downloads screen or specific lesson
  }

  /// Show download notification with progress
  Future<void> showDownloadProgress({
    required int lessonId,
    required String lessonTitle,
    required int progress, // 0-100
    required int downloaded,
    required int total,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Track this download
      _activeDownloads.add(lessonId);
      await _updateBadge();

      final androidDetails = AndroidNotificationDetails(
        _downloadChannelIdString,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        ongoing: true, // Cannot be dismissed while downloading
        autoCancel: false,
        showWhen: false,
        icon: '@drawable/ic_stat_music_note',
        subText: 'Загрузка урока',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadChannelId + lessonId,
        lessonTitle,
        _formatProgressText(downloaded, total, progress),
        notificationDetails,
      );
    } catch (e) {
      logger.e('Failed to show download progress notification', error: e);
    }
  }

  /// Show download completed notification
  Future<void> showDownloadCompleted({
    required int lessonId,
    required String lessonTitle,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Remove from active downloads
      _activeDownloads.remove(lessonId);
      await _updateBadge();

      const androidDetails = AndroidNotificationDetails(
        _downloadChannelIdString,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@drawable/ic_stat_music_note',
        subText: 'Урок загружен',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadChannelId + lessonId,
        lessonTitle,
        '✓ Загрузка завершена',
        notificationDetails,
      );

      // Auto-dismiss after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        cancelDownloadNotification(lessonId);
      });
    } catch (e) {
      logger.e('Failed to show download completed notification', error: e);
    }
  }

  /// Show download failed notification
  Future<void> showDownloadFailed({
    required int lessonId,
    required String lessonTitle,
    String? errorMessage,
  }) async {
    if (!_initialized) await initialize();

    try {
      // Remove from active downloads
      _activeDownloads.remove(lessonId);
      await _updateBadge();

      const androidDetails = AndroidNotificationDetails(
        _downloadChannelIdString,
        _downloadChannelName,
        channelDescription: _downloadChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@drawable/ic_stat_music_note',
        subText: 'Ошибка загрузки',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _downloadChannelId + lessonId,
        lessonTitle,
        '✗ ${errorMessage ?? "Ошибка загрузки"}',
        notificationDetails,
      );
    } catch (e) {
      logger.e('Failed to show download failed notification', error: e);
    }
  }

  /// Cancel download notification
  Future<void> cancelDownloadNotification(int lessonId) async {
    try {
      await _notifications.cancel(_downloadChannelId + lessonId);
      _activeDownloads.remove(lessonId);
      await _updateBadge();
    } catch (e) {
      logger.e('Failed to cancel notification', error: e);
    }
  }

  /// Cancel all download notifications
  Future<void> cancelAllDownloadNotifications() async {
    try {
      await _notifications.cancelAll();
      _activeDownloads.clear();
      await _updateBadge();
    } catch (e) {
      logger.e('Failed to cancel all notifications', error: e);
    }
  }

  /// Update app badge with active downloads count
  Future<void> _updateBadge() async {
    try {
      final count = _activeDownloads.length;

      if (count > 0) {
        // Show badge with count
        await AppBadgePlus.updateBadge(count);
      } else {
        // Remove badge
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      logger.e('Failed to update badge', error: e);
    }
  }

  /// Format progress text
  String _formatProgressText(int downloaded, int total, int progress) {
    final downloadedMB = (downloaded / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
    return '$downloadedMB МБ из $totalMB МБ ($progress%)';
  }

  /// Get active downloads count
  int get activeDownloadsCount => _activeDownloads.length;

  /// Check if badge is supported
  Future<bool> isBadgeSupported() async {
    try {
      final isSupported = await AppBadgePlus.isSupported();
      return isSupported;
    } catch (e) {
      return false;
    }
  }
}
