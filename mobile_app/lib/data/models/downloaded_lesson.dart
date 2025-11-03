/// Model for downloaded lessons stored in local database
class DownloadedLesson {
  final int lessonId;
  final String filePath;
  final int fileSize;
  final DateTime downloadDate;
  final DownloadStatus status;
  final int? seriesId; // Links to cached_series for offline navigation
  final String? lessonData; // JSON string of full lesson object for offline use

  DownloadedLesson({
    required this.lessonId,
    required this.filePath,
    required this.fileSize,
    required this.downloadDate,
    required this.status,
    this.seriesId,
    this.lessonData,
  });

  /// Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'file_path': filePath,
      'file_size': fileSize,
      'download_date': downloadDate.toIso8601String(),
      'status': status.name,
      'series_id': seriesId,
      'lesson_data': lessonData,
    };
  }

  /// Create from Map (from database)
  factory DownloadedLesson.fromMap(Map<String, dynamic> map) {
    return DownloadedLesson(
      lessonId: map['lesson_id'] as int,
      filePath: map['file_path'] as String,
      fileSize: map['file_size'] as int,
      downloadDate: DateTime.parse(map['download_date'] as String),
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.failed,
      ),
      seriesId: map['series_id'] as int?,
      lessonData: map['lesson_data'] as String?,
    );
  }

  DownloadedLesson copyWith({
    int? lessonId,
    String? filePath,
    int? fileSize,
    DateTime? downloadDate,
    DownloadStatus? status,
    int? seriesId,
    String? lessonData,
  }) {
    return DownloadedLesson(
      lessonId: lessonId ?? this.lessonId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      downloadDate: downloadDate ?? this.downloadDate,
      status: status ?? this.status,
      seriesId: seriesId ?? this.seriesId,
      lessonData: lessonData ?? this.lessonData,
    );
  }
}

/// Download status enum
enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
}

/// Download progress info (for UI)
class DownloadProgress {
  final int lessonId;
  final int downloaded;
  final int total;
  final double progress; // 0.0 to 1.0
  final DownloadStatus status;

  DownloadProgress({
    required this.lessonId,
    required this.downloaded,
    required this.total,
    required this.progress,
    required this.status,
  });

  int get progressPercent => (progress * 100).round();
}
