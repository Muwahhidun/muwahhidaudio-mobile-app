import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../data/models/lesson.dart';
import '../../data/models/downloaded_lesson.dart';
import '../../config/api_config.dart';
import '../database/database_helper.dart';
import '../logger.dart';

/// Download manager for audio files
/// Handles downloading, progress tracking, and file management
class DownloadManager {
  final Dio _dio;
  final DatabaseHelper _db;
  final Map<int, CancelToken> _cancelTokens = {};

  DownloadManager({
    Dio? dio,
    DatabaseHelper? db,
  })  : _dio = dio ?? Dio(),
        _db = db ?? DatabaseHelper();

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

    try {
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

      // Create pending record in database
      await _db.insertDownloadedLesson(DownloadedLesson(
        lessonId: lessonId,
        filePath: filePath,
        fileSize: 0,
        downloadDate: DateTime.now(),
        status: DownloadStatus.downloading,
      ));

      // Download with progress
      await _dio.download(
        audioUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            logger.d('Download progress for lesson $lessonId: ${(progress * 100).toStringAsFixed(1)}%');

            // Don't await - just fire and forget
            _db.insertDownloadedLesson(DownloadedLesson(
              lessonId: lessonId,
              filePath: filePath,
              fileSize: total,
              downloadDate: DateTime.now(),
              status: DownloadStatus.downloading,
            )).catchError((e) {
              logger.e('Failed to update download progress in DB', error: e);
            });
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
        ));

        logger.i('Download completed for lesson $lessonId: ${fileSize} bytes');
      });

      // Cleanup cancel token
      _cancelTokens.remove(lessonId);

      // Emit final progress
      final downloadedLesson = await _db.getDownloadedLesson(lessonId);
      if (downloadedLesson != null) {
        yield DownloadProgress(
          lessonId: lessonId,
          downloaded: downloadedLesson.fileSize,
          total: downloadedLesson.fileSize,
          progress: 1.0,
          status: DownloadStatus.completed,
        );
      }
    } on DioException catch (e) {
      logger.e('Download failed for lesson $lessonId', error: e);

      // Update status to failed
      await _db.updateDownloadStatus(lessonId, DownloadStatus.failed);

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
}
