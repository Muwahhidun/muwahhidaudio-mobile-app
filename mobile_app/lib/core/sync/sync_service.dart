import 'package:dio/dio.dart';
import '../database/database_helper.dart';
import '../logger.dart';
import '../../data/api/dio_provider.dart';

/// Service for syncing metadata from API to local cache
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  bool _isSyncing = false;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Sync all metadata from API to local cache
  /// This downloads lightweight data (themes, books, authors, teachers, series, lessons metadata)
  /// Does NOT download audio files
  Future<SyncResult> syncAllData({
    void Function(String)? onProgress,
  }) async {
    if (_isSyncing) {
      logger.w('Sync already in progress');
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    logger.i('Starting full sync...');

    try {
      final dio = DioProvider.getDio();
      int totalItems = 0;

      // 1. Sync themes
      onProgress?.call('Синхронизация тем...');
      final themesCount = await _syncThemes(dio);
      totalItems += themesCount;
      logger.i('Synced $themesCount themes');

      // 2. Sync book authors
      onProgress?.call('Синхронизация авторов...');
      final authorsCount = await _syncBookAuthors(dio);
      totalItems += authorsCount;
      logger.i('Synced $authorsCount book authors');

      // 3. Sync books
      onProgress?.call('Синхронизация книг...');
      final booksCount = await _syncBooks(dio);
      totalItems += booksCount;
      logger.i('Synced $booksCount books');

      // 4. Sync teachers
      onProgress?.call('Синхронизация лекторов...');
      final teachersCount = await _syncTeachers(dio);
      totalItems += teachersCount;
      logger.i('Synced $teachersCount teachers');

      // 5. Sync series
      onProgress?.call('Синхронизация серий...');
      final seriesCount = await _syncSeries(dio);
      totalItems += seriesCount;
      logger.i('Synced $seriesCount series');

      // 6. Sync lessons for all series
      onProgress?.call('Синхронизация уроков...');
      final lessonsCount = await _syncAllLessons(dio);
      totalItems += lessonsCount;
      logger.i('Synced $lessonsCount lessons');

      onProgress?.call('Синхронизация завершена');
      logger.i('Full sync completed successfully. Total items: $totalItems');

      return SyncResult(
        success: true,
        message: 'Успешно синхронизировано $totalItems элементов',
        itemsSynced: totalItems,
      );
    } catch (e, stackTrace) {
      logger.e('Sync failed', error: e, stackTrace: stackTrace);
      return SyncResult(
        success: false,
        message: 'Ошибка синхронизации: ${e.toString()}',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync themes from API
  Future<int> _syncThemes(Dio dio) async {
    try {
      final response = await dio.get('/themes', queryParameters: {
        'skip': 0,
        'limit': 1000, // Get all themes
      });

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;

      for (final item in items) {
        await _db.cacheTheme(item as Map<String, dynamic>);
      }

      return items.length;
    } catch (e) {
      logger.e('Failed to sync themes', error: e);
      rethrow;
    }
  }

  /// Sync book authors from API
  Future<int> _syncBookAuthors(Dio dio) async {
    try {
      final response = await dio.get('/book-authors', queryParameters: {
        'skip': 0,
        'limit': 1000, // Get all authors
      });

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;

      for (final item in items) {
        await _db.cacheBookAuthor(item as Map<String, dynamic>);
      }

      return items.length;
    } catch (e) {
      logger.e('Failed to sync book authors', error: e);
      rethrow;
    }
  }

  /// Sync books from API
  Future<int> _syncBooks(Dio dio) async {
    try {
      final response = await dio.get('/books', queryParameters: {
        'skip': 0,
        'limit': 1000, // Get all books
      });

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;

      for (final item in items) {
        await _db.cacheBook(item as Map<String, dynamic>);
      }

      return items.length;
    } catch (e) {
      logger.e('Failed to sync books', error: e);
      rethrow;
    }
  }

  /// Sync teachers from API
  Future<int> _syncTeachers(Dio dio) async {
    try {
      final response = await dio.get('/teachers', queryParameters: {
        'skip': 0,
        'limit': 1000, // Get all teachers
      });

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;

      for (final item in items) {
        await _db.cacheTeacher(item as Map<String, dynamic>);
      }

      return items.length;
    } catch (e) {
      logger.e('Failed to sync teachers', error: e);
      rethrow;
    }
  }

  /// Sync series from API
  Future<int> _syncSeries(Dio dio) async {
    try {
      final response = await dio.get('/series', queryParameters: {
        'skip': 0,
        'limit': 1000, // Get all series
      });

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List;

      for (final item in items) {
        await _db.cacheSeries(item as Map<String, dynamic>);
      }

      return items.length;
    } catch (e) {
      logger.e('Failed to sync series', error: e);
      rethrow;
    }
  }

  /// Sync all lessons for all series
  Future<int> _syncAllLessons(Dio dio) async {
    try {
      // Get all cached series IDs (including inactive ones for complete sync)
      final seriesList = await _db.getAllCachedSeries(includeInactive: true);
      int totalLessons = 0;

      for (final series in seriesList) {
        final seriesId = series['id'] as int;

        try {
          // Get lessons for this series
          // Note: This endpoint returns a direct List, not a paginated response
          final response = await dio.get('/series/$seriesId/lessons');

          final items = response.data as List;

          // Batch cache lessons for efficiency
          // IMPORTANT: Add series_id to each lesson because API doesn't include it
          final lessonsData = items.map((e) {
            final lesson = e as Map<String, dynamic>;
            lesson['series_id'] = seriesId; // Add series_id from context
            return lesson;
          }).toList();
          await _db.cacheLessonsBatch(lessonsData);

          totalLessons += items.length;
          logger.d('Synced ${items.length} lessons for series $seriesId');
        } catch (e) {
          logger.w('Failed to sync lessons for series $seriesId', error: e);
          // Continue with next series even if one fails
          continue;
        }
      }

      return totalLessons;
    } catch (e) {
      logger.e('Failed to sync lessons', error: e);
      rethrow;
    }
  }

  /// Sync lessons for a specific series
  Future<int> syncSeriesLessons(int seriesId) async {
    try {
      final dio = DioProvider.getDio();

      // Note: This endpoint returns a direct List, not a paginated response
      final response = await dio.get('/series/$seriesId/lessons');

      final items = response.data as List;

      // IMPORTANT: Add series_id to each lesson because API doesn't include it
      final lessonsData = items.map((e) {
        final lesson = e as Map<String, dynamic>;
        lesson['series_id'] = seriesId; // Add series_id from context
        return lesson;
      }).toList();
      await _db.cacheLessonsBatch(lessonsData);

      logger.i('Synced ${items.length} lessons for series $seriesId');
      return items.length;
    } catch (e) {
      logger.e('Failed to sync lessons for series $seriesId', error: e);
      rethrow;
    }
  }

  /// Check if initial sync is needed
  Future<bool> needsInitialSync() async {
    return !(await _db.hasCachedData());
  }

  /// Clear cache and force re-sync
  Future<void> clearCacheAndResync() async {
    await _db.clearAllCache();
    logger.i('Cache cleared, ready for re-sync');
  }
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final String message;
  final int itemsSynced;

  SyncResult({
    required this.success,
    required this.message,
    this.itemsSynced = 0,
  });
}
