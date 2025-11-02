/// Model for downloaded lessons stored in local database
class DownloadedLesson {
  final int lessonId;
  final String filePath;
  final int fileSize;
  final DateTime downloadDate;
  final DownloadStatus status;

  DownloadedLesson({
    required this.lessonId,
    required this.filePath,
    required this.fileSize,
    required this.downloadDate,
    required this.status,
  });

  /// Convert to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'lesson_id': lessonId,
      'file_path': filePath,
      'file_size': fileSize,
      'download_date': downloadDate.toIso8601String(),
      'status': status.name,
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
    );
  }

  DownloadedLesson copyWith({
    int? lessonId,
    String? filePath,
    int? fileSize,
    DateTime? downloadDate,
    DownloadStatus? status,
  }) {
    return DownloadedLesson(
      lessonId: lessonId ?? this.lessonId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      downloadDate: downloadDate ?? this.downloadDate,
      status: status ?? this.status,
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
