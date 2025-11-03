import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/models/lesson.dart';
import '../../data/models/downloaded_lesson.dart';
import '../../data/models/series.dart';
import '../../config/api_config.dart';
import '../database/database_helper.dart';
import '../notifications/notification_service.dart';
import '../logger.dart';

/// Download manager for audio files
/// Handles downloading, progress tracking, and file management
class DownloadManager {
  final Dio _dio;
  final DatabaseHelper _db;
  final NotificationService _notificationService;
  final Map<int, CancelToken> _cancelTokens = {};

  DownloadManager({
    Dio? dio,
    DatabaseHelper? db,
    NotificationService? notificationService,
  })  : _dio = dio ?? Dio(),
        _db = db ?? DatabaseHelper(),
        _notificationService = notificationService ?? NotificationService();

  /// Get download directory for audio files
  Future<Directory> _getDownloadDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory downloadDir = Directory(path.join(appDir.path, 'downloaded_lessons'));

    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir;
  }

  /// Get local file path for a lesson
  Future<String> _getFilePath(int lessonId) async {
    final downloadDir = await _getDownloadDirectory();
    return path.join(downloadDir.path, 'lesson_$lessonId.mp3');
  }

  /// Download a lesson
  /// Returns Stream<DownloadProgress> for progress updates
  Stream<DownloadProgress> downloadLesson(Lesson lesson) async* {
    final lessonId = lesson.id;
    final lessonTitle = lesson.displayTitle ?? 'Урок ${lesson.lessonNumber}';

    try {
      // Initialize notification service
      await _notificationService.initialize();

      // Check if already downloaded
      final existing = await _db.getDownloadedLesson(lessonId);
      if (existing != null && existing.status == DownloadStatus.completed) {
        logger.i('Lesson $lessonId already downloaded');
        yield DownloadProgress(
          lessonId: lessonId,
          downloaded: existing.fileSize,
          total: existing.fileSize,
          progress: 1.0,
          status: DownloadStatus.completed,
        );
        return;
      }

      // Build audio URL
      final audioUrl = lesson.audioUrl!.startsWith('http')
          ? lesson.audioUrl!
          : '${ApiConfig.baseUrl}${lesson.audioUrl}';

      logger.i('Starting download for lesson $lessonId from $audioUrl');

      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[lessonId] = cancelToken;

      // Get local file path
      final filePath = await _getFilePath(lessonId);

      // Create pending record in database with series_id and lesson data
      final lessonJson = jsonEncode(lesson.toJson());
      await _db.insertDownloadedLesson(DownloadedLesson(
        lessonId: lessonId,
        filePath: filePath,
        fileSize: 0,
        downloadDate: DateTime.now(),
        status: DownloadStatus.downloading,
        seriesId: lesson.seriesId,
        lessonData: lessonJson,
      ));

      // Show initial notification
      await _notificationService.showDownloadProgress(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        progress: 0,
        downloaded: 0,
        total: 1,
      );

      // Create stream controller for progress
      final progressController = StreamController<DownloadProgress>();

      // Download with progress
      _dio.download(
        audioUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toInt();
            logger.d('Download progress for lesson $lessonId: $progress%');

            // Update database (fire and forget)
            _db.insertDownloadedLesson(DownloadedLesson(
              lessonId: lessonId,
              filePath: filePath,
              fileSize: total,
              downloadDate: DateTime.now(),
              status: DownloadStatus.downloading,
              seriesId: lesson.seriesId,
              lessonData: lessonJson,
            )).catchError((e) {
              logger.e('Failed to update download progress in DB', error: e);
            });

            // Update notification (fire and forget)
            _notificationService.showDownloadProgress(
              lessonId: lessonId,
              lessonTitle: lessonTitle,
              progress: progress,
              downloaded: received,
              total: total,
            ).catchError((e) {
              logger.e('Failed to update notification', error: e);
            });

            // Emit progress
            progressController.add(DownloadProgress(
              lessonId: lessonId,
              downloaded: received,
              total: total,
              progress: received / total,
              status: DownloadStatus.downloading,
            ));
          }
        },
        deleteOnError: true,
      ).then((response) async {
        // Download completed successfully
        final file = File(filePath);
        final fileSize = await file.length();

        await _db.insertDownloadedLesson(DownloadedLesson(
          lessonId: lessonId,
          filePath: filePath,
          fileSize: fileSize,
          downloadDate: DateTime.now(),
          status: DownloadStatus.completed,
          seriesId: lesson.seriesId,
          lessonData: lessonJson,
        ));

        // Cache navigation metadata for offline access
        await _cacheNavigationMetadata(lesson);

        logger.i('Download completed for lesson $lessonId: ${fileSize} bytes');

        // Show completion notification
        await _notificationService.showDownloadCompleted(
          lessonId: lessonId,
          lessonTitle: lessonTitle,
        );

        // Emit completion
        progressController.add(DownloadProgress(
          lessonId: lessonId,
          downloaded: fileSize,
          total: fileSize,
          progress: 1.0,
          status: DownloadStatus.completed,
        ));
        progressController.close();
      }).catchError((error) async {
        // Handle download error
        if (error is DioException && error.type == DioExceptionType.cancel) {
          // Download cancelled
          logger.i('Download cancelled for lesson $lessonId');
          await _notificationService.cancelDownloadNotification(lessonId);
        } else {
          // Download failed
          logger.e('Download failed for lesson $lessonId', error: error);
          await _db.updateDownloadStatus(lessonId, DownloadStatus.failed);
          await _notificationService.showDownloadFailed(
            lessonId: lessonId,
            lessonTitle: lessonTitle,
            errorMessage: 'Ошибка загрузки',
          );

          progressController.add(DownloadProgress(
            lessonId: lessonId,
            downloaded: 0,
            total: 0,
            progress: 0.0,
            status: DownloadStatus.failed,
          ));
        }
        progressController.close();
      });

      // Yield all progress updates
      yield* progressController.stream;

      // Cleanup cancel token
      _cancelTokens.remove(lessonId);
    } on DioException catch (e) {
      logger.e('Download failed for lesson $lessonId', error: e);

      // Update status to failed
      await _db.updateDownloadStatus(lessonId, DownloadStatus.failed);

      // Show error notification
      if (e.type != DioExceptionType.cancel) {
        await _notificationService.showDownloadFailed(
          lessonId: lessonId,
          lessonTitle: lessonTitle,
          errorMessage: 'Ошибка сети',
        );
      }

      // Cleanup cancel token
      _cancelTokens.remove(lessonId);

      yield DownloadProgress(
        lessonId: lessonId,
        downloaded: 0,
        total: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
      );

      rethrow;
    } catch (e, stackTrace) {
      logger.e('Unexpected error during download', error: e, stackTrace: stackTrace);

      await _db.updateDownloadStatus(lessonId, DownloadStatus.failed);
      await _notificationService.showDownloadFailed(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        errorMessage: 'Ошибка загрузки',
      );

      _cancelTokens.remove(lessonId);

      yield DownloadProgress(
        lessonId: lessonId,
        downloaded: 0,
        total: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
      );

      rethrow;
    }
  }

  /// Cancel download
  Future<void> cancelDownload(int lessonId) async {
    try {
      final cancelToken = _cancelTokens[lessonId];
      if (cancelToken != null && !cancelToken.isCancelled) {
        cancelToken.cancel('Download cancelled by user');
        _cancelTokens.remove(lessonId);
        logger.i('Cancelled download for lesson $lessonId');
      }

      // Update status
      await _db.updateDownloadStatus(lessonId, DownloadStatus.failed);

      // Cancel notification
      await _notificationService.cancelDownloadNotification(lessonId);

      // Delete partial file
      final filePath = await _getFilePath(lessonId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('Deleted partial file for lesson $lessonId');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to cancel download', error: e, stackTrace: stackTrace);
    }
  }

  /// Delete downloaded lesson
  Future<void> deleteDownload(int lessonId) async {
    try {
      // Get downloaded lesson info
      final downloadedLesson = await _db.getDownloadedLesson(lessonId);
      if (downloadedLesson == null) {
        logger.w('Lesson $lessonId not found in database');
        return;
      }

      // Delete file
      final file = File(downloadedLesson.filePath);
      if (await file.exists()) {
        await file.delete();
        logger.i('Deleted file: ${downloadedLesson.filePath}');
      }

      // Delete from database
      await _db.deleteDownloadedLesson(lessonId);

      logger.i('Successfully deleted download for lesson $lessonId');
    } catch (e, stackTrace) {
      logger.e('Failed to delete download', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if lesson is downloaded
  Future<bool> isLessonDownloaded(int lessonId) async {
    try {
      return await _db.isLessonDownloaded(lessonId);
    } catch (e) {
      logger.e('Failed to check if lesson is downloaded', error: e);
      return false;
    }
  }

  /// Get local file path for downloaded lesson
  Future<String?> getLocalFilePath(int lessonId) async {
    try {
      final downloadedLesson = await _db.getDownloadedLesson(lessonId);
      if (downloadedLesson != null && downloadedLesson.status == DownloadStatus.completed) {
        final file = File(downloadedLesson.filePath);
        if (await file.exists()) {
          return downloadedLesson.filePath;
        }
      }
      return null;
    } catch (e) {
      logger.e('Failed to get local file path', error: e);
      return null;
    }
  }

  /// Get all downloaded lessons
  Future<List<DownloadedLesson>> getAllDownloads() async {
    try {
      return await _db.getAllDownloadedLessons();
    } catch (e) {
      logger.e('Failed to get all downloads', error: e);
      return [];
    }
  }

  /// Get total downloaded size in bytes
  Future<int> getTotalDownloadedSize() async {
    try {
      return await _db.getTotalDownloadedSize();
    } catch (e) {
      logger.e('Failed to get total downloaded size', error: e);
      return 0;
    }
  }

  /// Get count of downloaded lessons
  Future<int> getDownloadedCount() async {
    try {
      return await _db.getDownloadedLessonsCount();
    } catch (e) {
      logger.e('Failed to get downloaded count', error: e);
      return 0;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Cache navigation metadata for offline access
  /// Caches theme -> book -> author -> teacher -> series chain
  /// Cache series metadata for offline access
  Future<void> cacheSeriesMetadata(SeriesModel series) async {
    try {
      logger.i('=== Caching metadata for series ${series.id}: ${series.displayName ?? series.name} ===');

      // Cache theme if present
      if (series.theme != null) {
        logger.i('Theme found: ${series.theme!.name} (ID: ${series.theme!.id})');
        final themeData = {
          'id': series.theme!.id,
          'name': series.theme!.name,
          'display_name': series.theme!.name,
          'description': series.theme!.description,
          'is_active': series.theme!.isActive ?? true,
        };
        await _db.cacheTheme(themeData);
        logger.i('✓ Successfully cached theme: ${series.theme!.name}');
      } else {
        logger.w('⚠ Theme is NULL - cannot cache');
      }

      // Cache book author if present
      if (series.book?.author != null) {
        logger.i('Book author found: ${series.book!.author!.name} (ID: ${series.book!.author!.id})');
        final authorData = {
          'id': series.book!.author!.id,
          'name': series.book!.author!.name,
          'biography': series.book!.author!.biography,
          'birth_year': series.book!.author!.birthYear,
          'death_year': series.book!.author!.deathYear,
          'is_active': series.book!.author!.isActive ?? true,
        };
        await _db.cacheBookAuthor(authorData);
        logger.i('✓ Successfully cached book author: ${series.book!.author!.name}');
      } else {
        logger.w('⚠ Book author is NULL - cannot cache');
      }

      // Cache book if present
      if (series.book != null) {
        logger.i('Book found: ${series.book!.name} (ID: ${series.book!.id})');
        final bookData = {
          'id': series.book!.id,
          'name': series.book!.name,
          'description': series.book!.description,
          'author_id': series.book!.authorId,
          'theme_id': series.themeId,
          'is_active': series.book!.isActive ?? true,
        };
        await _db.cacheBook(bookData);
        logger.i('✓ Successfully cached book: ${series.book!.name}');
      } else {
        logger.w('⚠ Book is NULL - cannot cache');
      }

      // Cache teacher if present
      if (series.teacher != null) {
        logger.i('Teacher found: ${series.teacher!.name} (ID: ${series.teacher!.id})');
        final teacherData = {
          'id': series.teacher!.id,
          'name': series.teacher!.name,
          'biography': series.teacher!.biography,
          'is_active': series.teacher!.isActive ?? true,
        };
        await _db.cacheTeacher(teacherData);
        logger.i('✓ Successfully cached teacher: ${series.teacher!.name}');
      } else {
        logger.w('⚠ Teacher is NULL - cannot cache');
      }

      // Cache series itself
      logger.i('Caching series itself (ID: ${series.id})');
      final seriesData = {
        'id': series.id,
        'name': series.name,
        'year': series.year,
        'display_name': series.displayName ?? series.name,
        'description': series.description,
        'teacher_id': series.teacherId,
        'book_id': series.bookId,
        'theme_id': series.themeId,
        'is_active': series.isActive ?? true,
        'series_order': series.order,
      };
      await _db.cacheSeries(seriesData);
      logger.i('✓ Successfully cached series: ${series.displayName ?? series.name}');

      logger.i('=== Metadata caching completed for series ${series.id} ===');
    } catch (e, stackTrace) {
      logger.e('Failed to cache series metadata', error: e, stackTrace: stackTrace);
      // Don't throw - caching failure shouldn't stop the download
    }
  }

  Future<void> _cacheNavigationMetadata(Lesson lesson) async {
    try {
      // Cache theme if present
      if (lesson.theme != null) {
        final themeData = {
          'id': lesson.theme!.id,
          'name': lesson.theme!.name,
          'display_name': lesson.theme!.name,
          'is_active': true,
        };
        await _db.cacheTheme(themeData);
        logger.d('Cached theme: ${lesson.theme!.name}');
      }

      // Cache book author if present
      if (lesson.book?.author != null) {
        final authorData = {
          'id': lesson.book!.author!.id,
          'name': lesson.book!.author!.name,
          'is_active': true,
        };
        await _db.cacheBookAuthor(authorData);
        logger.d('Cached author: ${lesson.book!.author!.name}');
      }

      // Cache book if present
      if (lesson.book != null) {
        final bookData = {
          'id': lesson.book!.id,
          'name': lesson.book!.name,
          'author_id': lesson.book!.author?.id,
          'theme_id': lesson.themeId,
          'is_active': true,
        };
        await _db.cacheBook(bookData);
        logger.d('Cached book: ${lesson.book!.name}');
      }

      // Cache teacher if present
      if (lesson.teacher != null) {
        final teacherData = {
          'id': lesson.teacher!.id,
          'name': lesson.teacher!.name,
          'is_active': true,
        };
        await _db.cacheTeacher(teacherData);
        logger.d('Cached teacher: ${lesson.teacher!.name}');
      }

      // Cache series if present
      if (lesson.series != null) {
        final seriesData = {
          'id': lesson.series!.id,
          'name': lesson.series!.name,
          'year': lesson.series!.year,
          'display_name': lesson.series!.displayName,
          'teacher_id': lesson.teacherId,
          'book_id': lesson.bookId,
          'theme_id': lesson.themeId,
          'is_active': true,
        };
        await _db.cacheSeries(seriesData);
        logger.d('Cached series: ${lesson.series!.displayName}');
      }

      // Cache ALL lessons for this series (critical for offline mode!)
      if (lesson.seriesId != null) {
        try {
          logger.i('Fetching and caching all lessons for series ${lesson.seriesId}...');

          final response = await _dio.get(
            '${ApiConfig.baseUrl}/api/series/${lesson.seriesId}/lessons',
            queryParameters: {'limit': 1000},
          );

          final data = response.data as Map<String, dynamic>;
          final items = data['items'] as List;

          if (items.isNotEmpty) {
            final lessonsData = items.map((e) => e as Map<String, dynamic>).toList();
            await _db.cacheLessonsBatch(lessonsData);
            logger.i('✓ Cached ${items.length} lessons for series ${lesson.seriesId}');
          }
        } catch (e) {
          logger.w('Failed to cache series lessons (non-critical): $e');
          // Non-critical - don't fail the download
        }
      }

      logger.i('Successfully cached navigation metadata for lesson ${lesson.id}');
    } catch (e, stackTrace) {
      logger.e('Failed to cache navigation metadata', error: e, stackTrace: stackTrace);
      // Don't throw - caching failure shouldn't stop the download
    }
  }
}
