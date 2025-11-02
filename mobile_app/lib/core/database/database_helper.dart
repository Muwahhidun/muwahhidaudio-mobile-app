import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/downloaded_lesson.dart';
import '../logger.dart';

/// SQLite database helper for offline storage
/// Singleton pattern
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, 'muwahhid_audio.db');

      logger.i('Initializing database at: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to initialize database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    logger.i('Creating database tables...');

    // Downloaded lessons table
    await db.execute('''
      CREATE TABLE downloaded_lessons (
        lesson_id INTEGER PRIMARY KEY,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        download_date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    logger.i('Database tables created successfully');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    logger.i('Upgrading database from version $oldVersion to $newVersion');

    // Handle future schema upgrades here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE downloaded_lessons ADD COLUMN new_field TEXT');
    // }
  }

  // ==================== DOWNLOADED LESSONS CRUD ====================

  /// Insert or update downloaded lesson
  Future<void> insertDownloadedLesson(DownloadedLesson lesson) async {
    try {
      final db = await database;
      await db.insert(
        'downloaded_lessons',
        lesson.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logger.i('Inserted/updated downloaded lesson: ${lesson.lessonId}');
    } catch (e, stackTrace) {
      logger.e('Failed to insert downloaded lesson', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get downloaded lesson by ID
  Future<DownloadedLesson?> getDownloadedLesson(int lessonId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'downloaded_lessons',
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );

      if (maps.isEmpty) return null;

      return DownloadedLesson.fromMap(maps.first);
    } catch (e, stackTrace) {
      logger.e('Failed to get downloaded lesson', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get all downloaded lessons
  Future<List<DownloadedLesson>> getAllDownloadedLessons() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'downloaded_lessons',
        orderBy: 'download_date DESC',
      );

      return List.generate(maps.length, (i) => DownloadedLesson.fromMap(maps[i]));
    } catch (e, stackTrace) {
      logger.e('Failed to get all downloaded lessons', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get downloaded lessons by status
  Future<List<DownloadedLesson>> getDownloadedLessonsByStatus(DownloadStatus status) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'downloaded_lessons',
        where: 'status = ?',
        whereArgs: [status.name],
      );

      return List.generate(maps.length, (i) => DownloadedLesson.fromMap(maps[i]));
    } catch (e, stackTrace) {
      logger.e('Failed to get downloaded lessons by status', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Check if lesson is downloaded
  Future<bool> isLessonDownloaded(int lessonId) async {
    try {
      final lesson = await getDownloadedLesson(lessonId);
      return lesson != null && lesson.status == DownloadStatus.completed;
    } catch (e) {
      logger.e('Failed to check if lesson is downloaded', error: e);
      return false;
    }
  }

  /// Update download status
  Future<void> updateDownloadStatus(int lessonId, DownloadStatus status) async {
    try {
      final db = await database;
      await db.update(
        'downloaded_lessons',
        {'status': status.name},
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );
      logger.i('Updated download status for lesson $lessonId to ${status.name}');
    } catch (e, stackTrace) {
      logger.e('Failed to update download status', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete downloaded lesson
  Future<void> deleteDownloadedLesson(int lessonId) async {
    try {
      final db = await database;
      await db.delete(
        'downloaded_lessons',
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
      );
      logger.i('Deleted downloaded lesson: $lessonId');
    } catch (e, stackTrace) {
      logger.e('Failed to delete downloaded lesson', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get total size of downloaded files
  Future<int> getTotalDownloadedSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(file_size) as total FROM downloaded_lessons WHERE status = ?',
        [DownloadStatus.completed.name],
      );

      return (result.first['total'] as int?) ?? 0;
    } catch (e, stackTrace) {
      logger.e('Failed to get total downloaded size', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get count of downloaded lessons
  Future<int> getDownloadedLessonsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM downloaded_lessons WHERE status = ?',
        [DownloadStatus.completed.name],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, stackTrace) {
      logger.e('Failed to get downloaded lessons count', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Clear all downloaded lessons data (for testing/cleanup)
  Future<void> clearAllDownloads() async {
    try {
      final db = await database;
      await db.delete('downloaded_lessons');
      logger.i('Cleared all downloaded lessons');
    } catch (e, stackTrace) {
      logger.e('Failed to clear downloads', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    logger.i('Database closed');
  }
}
