import 'dart:convert';
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
        version: 3,
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
        status TEXT NOT NULL,
        series_id INTEGER,
        lesson_data TEXT
      )
    ''');

    // Cached themes table
    await db.execute('''
      CREATE TABLE cached_themes (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cached book authors table
    await db.execute('''
      CREATE TABLE cached_book_authors (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        biography TEXT,
        birth_year INTEGER,
        death_year INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cached books table
    await db.execute('''
      CREATE TABLE cached_books (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        theme_id INTEGER,
        author_id INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (theme_id) REFERENCES cached_themes (id),
        FOREIGN KEY (author_id) REFERENCES cached_book_authors (id)
      )
    ''');

    // Cached teachers table
    await db.execute('''
      CREATE TABLE cached_teachers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        biography TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cached series table
    await db.execute('''
      CREATE TABLE cached_series (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        display_name TEXT,
        description TEXT,
        year INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        teacher_id INTEGER,
        book_id INTEGER,
        theme_id INTEGER,
        series_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES cached_teachers (id),
        FOREIGN KEY (book_id) REFERENCES cached_books (id),
        FOREIGN KEY (theme_id) REFERENCES cached_themes (id)
      )
    ''');

    // Cached lessons table
    await db.execute('''
      CREATE TABLE cached_lessons (
        id INTEGER PRIMARY KEY,
        title TEXT,
        display_title TEXT,
        lesson_number INTEGER NOT NULL,
        duration_seconds INTEGER,
        formatted_duration TEXT,
        audio_url TEXT,
        audio_file_path TEXT,
        description TEXT,
        tags TEXT,
        waveform_data TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        series_id INTEGER,
        teacher_id INTEGER,
        book_id INTEGER,
        theme_id INTEGER,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (series_id) REFERENCES cached_series (id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_downloaded_lessons_series ON downloaded_lessons(series_id)');
    await db.execute('CREATE INDEX idx_books_theme ON cached_books(theme_id)');
    await db.execute('CREATE INDEX idx_books_author ON cached_books(author_id)');
    await db.execute('CREATE INDEX idx_series_theme ON cached_series(theme_id)');
    await db.execute('CREATE INDEX idx_series_book ON cached_series(book_id)');
    await db.execute('CREATE INDEX idx_series_teacher ON cached_series(teacher_id)');
    await db.execute('CREATE INDEX idx_lessons_series ON cached_lessons(series_id)');
    await db.execute('CREATE INDEX idx_lessons_book ON cached_lessons(book_id)');
    await db.execute('CREATE INDEX idx_lessons_teacher ON cached_lessons(teacher_id)');
    await db.execute('CREATE INDEX idx_lessons_theme ON cached_lessons(theme_id)');

    logger.i('Database tables created successfully');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    logger.i('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Upgrade from version 1 to 2: Add cache tables and columns
      logger.i('Upgrading to version 2: Adding cache tables...');

      // Add new columns to downloaded_lessons
      await db.execute('ALTER TABLE downloaded_lessons ADD COLUMN series_id INTEGER');
      await db.execute('ALTER TABLE downloaded_lessons ADD COLUMN lesson_data TEXT');

      // Create cache tables (same as in _createDatabase)
      await db.execute('''
        CREATE TABLE cached_themes (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          sort_order INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_book_authors (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          biography TEXT,
          birth_year INTEGER,
          death_year INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_books (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          theme_id INTEGER,
          author_id INTEGER,
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (theme_id) REFERENCES cached_themes (id),
          FOREIGN KEY (author_id) REFERENCES cached_book_authors (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_teachers (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          biography TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_series (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          display_name TEXT,
          description TEXT,
          year INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0,
          teacher_id INTEGER,
          book_id INTEGER,
          theme_id INTEGER,
          series_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (teacher_id) REFERENCES cached_teachers (id),
          FOREIGN KEY (book_id) REFERENCES cached_books (id),
          FOREIGN KEY (theme_id) REFERENCES cached_themes (id)
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX idx_downloaded_lessons_series ON downloaded_lessons(series_id)');
      await db.execute('CREATE INDEX idx_books_theme ON cached_books(theme_id)');
      await db.execute('CREATE INDEX idx_books_author ON cached_books(author_id)');
      await db.execute('CREATE INDEX idx_series_theme ON cached_series(theme_id)');
      await db.execute('CREATE INDEX idx_series_book ON cached_series(book_id)');
      await db.execute('CREATE INDEX idx_series_teacher ON cached_series(teacher_id)');

      logger.i('Database upgraded to version 2 successfully');
    }

    if (oldVersion < 3) {
      // Upgrade from version 2 to 3: Add cached_lessons table
      logger.i('Upgrading to version 3: Adding cached_lessons table...');

      await db.execute('''
        CREATE TABLE cached_lessons (
          id INTEGER PRIMARY KEY,
          title TEXT,
          display_title TEXT,
          lesson_number INTEGER NOT NULL,
          duration_seconds INTEGER,
          formatted_duration TEXT,
          audio_url TEXT,
          audio_file_path TEXT,
          description TEXT,
          tags TEXT,
          waveform_data TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          series_id INTEGER,
          teacher_id INTEGER,
          book_id INTEGER,
          theme_id INTEGER,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (series_id) REFERENCES cached_series (id)
        )
      ''');

      // Create indexes for cached_lessons
      await db.execute('CREATE INDEX idx_lessons_series ON cached_lessons(series_id)');
      await db.execute('CREATE INDEX idx_lessons_book ON cached_lessons(book_id)');
      await db.execute('CREATE INDEX idx_lessons_teacher ON cached_lessons(teacher_id)');
      await db.execute('CREATE INDEX idx_lessons_theme ON cached_lessons(theme_id)');

      logger.i('Database upgraded to version 3 successfully');
    }
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

  // ==================== CACHE CRUD ====================

  /// Cache series metadata
  Future<void> cacheSeries(Map<String, dynamic> seriesData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_series',
        {
          'id': seriesData['id'],
          'name': seriesData['name'],
          'display_name': seriesData['display_name'],
          'description': seriesData['description'],
          'year': seriesData['year'],
          'is_completed': seriesData['is_completed'] == true ? 1 : 0,
          'teacher_id': seriesData['teacher']?['id'],
          'book_id': seriesData['book']?['id'],
          'theme_id': seriesData['theme']?['id'],
          'series_order': seriesData['order'] ?? 0,
          'is_active': seriesData['is_active'] == true ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logger.i('Cached series: ${seriesData['id']}');
    } catch (e, stackTrace) {
      logger.e('Failed to cache series', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache theme metadata
  Future<void> cacheTheme(Map<String, dynamic> themeData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_themes',
        {
          'id': themeData['id'],
          'name': themeData['name'],
          'description': themeData['description'],
          'is_active': themeData['is_active'] == true ? 1 : 0,
          'sort_order': themeData['sort_order'] ?? 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to cache theme', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache book metadata
  Future<void> cacheBook(Map<String, dynamic> bookData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_books',
        {
          'id': bookData['id'],
          'name': bookData['name'],
          'description': bookData['description'],
          'theme_id': bookData['theme_id'] ?? bookData['theme']?['id'],
          'author_id': bookData['author_id'] ?? bookData['author']?['id'],
          'sort_order': bookData['sort_order'] ?? 0,
          'is_active': bookData['is_active'] == true ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to cache book', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache book author metadata
  Future<void> cacheBookAuthor(Map<String, dynamic> authorData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_book_authors',
        {
          'id': authorData['id'],
          'name': authorData['name'],
          'biography': authorData['biography'],
          'birth_year': authorData['birth_year'],
          'death_year': authorData['death_year'],
          'is_active': authorData['is_active'] == true ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to cache book author', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache teacher metadata
  Future<void> cacheTeacher(Map<String, dynamic> teacherData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_teachers',
        {
          'id': teacherData['id'],
          'name': teacherData['name'],
          'biography': teacherData['biography'],
          'is_active': teacherData['is_active'] == true ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to cache teacher', error: e, stackTrace: stackTrace);
    }
  }

  /// Cache lesson metadata
  Future<void> cacheLesson(Map<String, dynamic> lessonData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_lessons',
        {
          'id': lessonData['id'],
          'title': lessonData['title'],
          'display_title': lessonData['display_title'],
          'lesson_number': lessonData['lesson_number'],
          'duration_seconds': lessonData['duration_seconds'],
          'formatted_duration': lessonData['formatted_duration'],
          'audio_url': lessonData['audio_url'],
          'audio_file_path': lessonData['audio_file_path'],
          'description': lessonData['description'],
          'tags': lessonData['tags'],
          'waveform_data': lessonData['waveform_data'],
          'is_active': lessonData['is_active'] == true ? 1 : 0,
          'series_id': lessonData['series_id'] ?? lessonData['series']?['id'],
          'teacher_id': lessonData['teacher_id'] ?? lessonData['teacher']?['id'],
          'book_id': lessonData['book_id'] ?? lessonData['book']?['id'],
          'theme_id': lessonData['theme_id'] ?? lessonData['theme']?['id'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to cache lesson', error: e, stackTrace: stackTrace);
    }
  }

  /// Batch cache multiple lessons (more efficient)
  /// Uses transactions and splits into smaller batches to prevent database locks
  Future<void> cacheLessonsBatch(List<Map<String, dynamic>> lessonsData) async {
    if (lessonsData.isEmpty) return;

    try {
      final db = await database;

      // Split into smaller batches to avoid database locks
      const batchSize = 50;
      for (int i = 0; i < lessonsData.length; i += batchSize) {
        final end = (i + batchSize < lessonsData.length) ? i + batchSize : lessonsData.length;
        final currentBatch = lessonsData.sublist(i, end);

        // Use transaction to ensure atomic operations and prevent locks
        await db.transaction((txn) async {
          final batch = txn.batch();

          for (final lessonData in currentBatch) {
            // Convert waveform_data from List to JSON string if needed
            String? waveformDataStr;
            final waveformData = lessonData['waveform_data'];
            if (waveformData != null) {
              if (waveformData is List) {
                waveformDataStr = jsonEncode(waveformData);
              } else if (waveformData is String) {
                waveformDataStr = waveformData;
              }
            }

            batch.insert(
              'cached_lessons',
              {
                'id': lessonData['id'],
                'title': lessonData['title'],
                'display_title': lessonData['display_title'],
                'lesson_number': lessonData['lesson_number'],
                'duration_seconds': lessonData['duration_seconds'],
                'formatted_duration': lessonData['formatted_duration'],
                'audio_url': lessonData['audio_url'],
                'audio_file_path': lessonData['audio_file_path'],
                'description': lessonData['description'],
                'tags': lessonData['tags'],
                'waveform_data': waveformDataStr,
                'is_active': lessonData['is_active'] == true ? 1 : 0,
                'series_id': lessonData['series_id'] ?? lessonData['series']?['id'],
                'teacher_id': lessonData['teacher_id'] ?? lessonData['teacher']?['id'],
                'book_id': lessonData['book_id'] ?? lessonData['book']?['id'],
                'theme_id': lessonData['theme_id'] ?? lessonData['theme']?['id'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await batch.commit(noResult: true);
        });

        logger.d('Cached batch ${i ~/ batchSize + 1} (${currentBatch.length} lessons)');
      }

      logger.i('Batch cached ${lessonsData.length} lessons successfully');
    } catch (e, stackTrace) {
      logger.e('Failed to batch cache lessons', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get cached themes that have downloaded series
  Future<List<Map<String, dynamic>>> getCachedThemesWithDownloads() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT DISTINCT t.*
        FROM cached_themes t
        INNER JOIN cached_series s ON t.id = s.theme_id
        INNER JOIN downloaded_lessons l ON s.id = l.series_id
        WHERE l.status = ?
        ORDER BY t.sort_order, t.name
      ''', [DownloadStatus.completed.name]);

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached themes with downloads', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get cached books (with optional theme filter) that have downloaded series
  Future<List<Map<String, dynamic>>> getCachedBooksWithDownloads({int? themeId}) async {
    try {
      final db = await database;

      String whereClause = 'l.status = ?';
      List<dynamic> whereArgs = [DownloadStatus.completed.name];

      if (themeId != null) {
        whereClause = 'b.theme_id = ? AND $whereClause';
        whereArgs.insert(0, themeId);
      }

      final result = await db.rawQuery('''
        SELECT DISTINCT b.*
        FROM cached_books b
        INNER JOIN cached_series s ON b.id = s.book_id
        INNER JOIN downloaded_lessons l ON s.id = l.series_id
        WHERE $whereClause
        ORDER BY b.sort_order, b.name
      ''', whereArgs);

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached books with downloads', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get cached series by filters that have downloaded lessons
  Future<List<Map<String, dynamic>>> getCachedSeriesWithDownloads({
    int? themeId,
    int? bookId,
    int? teacherId,
  }) async {
    try {
      final db = await database;

      final where = <String>[];
      final whereArgs = <dynamic>[];

      if (themeId != null) {
        where.add('s.theme_id = ?');
        whereArgs.add(themeId);
      }
      if (bookId != null) {
        where.add('s.book_id = ?');
        whereArgs.add(bookId);
      }
      if (teacherId != null) {
        where.add('s.teacher_id = ?');
        whereArgs.add(teacherId);
      }

      where.add('l.status = ?');
      whereArgs.add(DownloadStatus.completed.name);

      final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final result = await db.rawQuery('''
        SELECT DISTINCT s.*
        FROM cached_series s
        INNER JOIN downloaded_lessons l ON s.id = l.series_id
        $whereClause
        ORDER BY s.year DESC, s.series_order, s.name
      ''', whereArgs);

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached series with downloads', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get cached teachers that have downloaded series
  Future<List<Map<String, dynamic>>> getCachedTeachersWithDownloads() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT DISTINCT t.*
        FROM cached_teachers t
        INNER JOIN cached_series s ON t.id = s.teacher_id
        INNER JOIN downloaded_lessons l ON s.id = l.series_id
        WHERE l.status = ?
        ORDER BY t.name
      ''', [DownloadStatus.completed.name]);

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached teachers with downloads', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get cached book authors that have downloaded books/series
  Future<List<Map<String, dynamic>>> getCachedBookAuthorsWithDownloads() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT DISTINCT a.*
        FROM cached_book_authors a
        INNER JOIN cached_books b ON a.id = b.author_id
        INNER JOIN cached_series s ON b.id = s.book_id
        INNER JOIN downloaded_lessons l ON s.id = l.series_id
        WHERE l.status = ?
        ORDER BY a.name
      ''', [DownloadStatus.completed.name]);

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached book authors with downloads', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get downloaded lessons for a series with full lesson data
  Future<List<Map<String, dynamic>>> getDownloadedLessonsForSeries(int seriesId) async {
    try {
      final db = await database;
      final result = await db.query(
        'downloaded_lessons',
        where: 'series_id = ? AND status = ?',
        whereArgs: [seriesId, DownloadStatus.completed.name],
        orderBy: 'lesson_id',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get downloaded lessons for series', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached lessons for a series
  Future<List<Map<String, dynamic>>> getCachedLessonsForSeries(int seriesId) async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_lessons',
        where: 'series_id = ?',
        whereArgs: [seriesId],
        orderBy: 'lesson_number',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached lessons for series', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached themes
  Future<List<Map<String, dynamic>>> getAllCachedThemes() async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_themes',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'sort_order, name',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get all cached themes', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached books (with optional theme filter)
  Future<List<Map<String, dynamic>>> getAllCachedBooks({int? themeId}) async {
    try {
      final db = await database;

      if (themeId != null) {
        final result = await db.query(
          'cached_books',
          where: 'theme_id = ? AND is_active = ?',
          whereArgs: [themeId, 1],
          orderBy: 'sort_order, name',
        );
        return result;
      } else {
        final result = await db.query(
          'cached_books',
          where: 'is_active = ?',
          whereArgs: [1],
          orderBy: 'sort_order, name',
        );
        return result;
      }
    } catch (e, stackTrace) {
      logger.e('Failed to get all cached books', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached book authors
  Future<List<Map<String, dynamic>>> getAllCachedBookAuthors() async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_book_authors',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get all cached book authors', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached teachers
  Future<List<Map<String, dynamic>>> getAllCachedTeachers() async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_teachers',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get all cached teachers', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get all cached series (with optional filters)
  Future<List<Map<String, dynamic>>> getAllCachedSeries({
    int? themeId,
    int? bookId,
    int? teacherId,
    bool includeInactive = false,
  }) async {
    try {
      final db = await database;

      final where = <String>[];
      final whereArgs = <dynamic>[];

      // Only filter by is_active if includeInactive is false
      if (!includeInactive) {
        where.add('is_active = ?');
        whereArgs.add(1);
      }

      if (themeId != null) {
        where.add('theme_id = ?');
        whereArgs.add(themeId);
      }
      if (bookId != null) {
        where.add('book_id = ?');
        whereArgs.add(bookId);
      }
      if (teacherId != null) {
        where.add('teacher_id = ?');
        whereArgs.add(teacherId);
      }

      final whereClause = where.isNotEmpty ? where.join(' AND ') : null;

      final result = await db.query(
        'cached_series',
        where: whereClause,
        whereArgs: whereClause != null ? whereArgs : null,
        orderBy: 'year DESC, series_order, name',
      );

      return result;
    } catch (e, stackTrace) {
      logger.e('Failed to get all cached series', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get cached lesson by ID
  Future<Map<String, dynamic>?> getCachedLessonById(int lessonId) async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_lessons',
        where: 'id = ?',
        whereArgs: [lessonId],
        limit: 1,
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e, stackTrace) {
      logger.e('Failed to get cached lesson by ID', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if cache has data
  Future<bool> hasCachedData() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cached_themes',
      );

      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Clear all cache (for re-syncing)
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete('cached_lessons');
      await db.delete('cached_series');
      await db.delete('cached_books');
      await db.delete('cached_book_authors');
      await db.delete('cached_teachers');
      await db.delete('cached_themes');
      logger.i('Cleared all cache');
    } catch (e, stackTrace) {
      logger.e('Failed to clear cache', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Check if user has any downloaded content
  Future<bool> hasDownloadedContent() async {
    try {
      final count = await getDownloadedLessonsCount();
      return count > 0;
    } catch (e) {
      return false;
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
