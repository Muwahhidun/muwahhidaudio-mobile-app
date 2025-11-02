import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson.dart';
import '../../data/models/downloaded_lesson.dart';
import '../../core/download/download_manager.dart';
import '../../core/logger.dart';

/// State for downloads
class DownloadState {
  final Map<int, DownloadProgress> activeDownloads;
  final Map<int, bool> downloadedLessons;
  final bool isLoading;
  final String? error;

  const DownloadState({
    this.activeDownloads = const {},
    this.downloadedLessons = const {},
    this.isLoading = false,
    this.error,
  });

  DownloadState copyWith({
    Map<int, DownloadProgress>? activeDownloads,
    Map<int, bool>? downloadedLessons,
    bool? isLoading,
    String? error,
  }) {
    return DownloadState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      downloadedLessons: downloadedLessons ?? this.downloadedLessons,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Download provider notifier
class DownloadNotifier extends StateNotifier<DownloadState> {
  final DownloadManager _downloadManager;

  DownloadNotifier(this._downloadManager) : super(const DownloadState()) {
    _loadDownloadedLessons();
  }

  /// Load all downloaded lessons on init
  Future<void> _loadDownloadedLessons() async {
    try {
      state = state.copyWith(isLoading: true);

      final downloads = await _downloadManager.getAllDownloads();
      final downloadedMap = <int, bool>{};

      for (var download in downloads) {
        if (download.status == DownloadStatus.completed) {
          downloadedMap[download.lessonId] = true;
        }
      }

      state = state.copyWith(
        downloadedLessons: downloadedMap,
        isLoading: false,
      );

      logger.i('Loaded ${downloadedMap.length} downloaded lessons');
    } catch (e) {
      logger.e('Failed to load downloaded lessons', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load downloads: $e',
      );
    }
  }

  /// Start downloading a lesson
  Future<void> downloadLesson(Lesson lesson) async {
    try {
      logger.i('Starting download for lesson ${lesson.id}');

      // Listen to download progress
      await for (final progress in _downloadManager.downloadLesson(lesson)) {
        final newActiveDownloads = Map<int, DownloadProgress>.from(state.activeDownloads);

        if (progress.status == DownloadStatus.completed) {
          // Download completed - remove from active, add to downloaded
          newActiveDownloads.remove(lesson.id);

          final newDownloadedLessons = Map<int, bool>.from(state.downloadedLessons);
          newDownloadedLessons[lesson.id] = true;

          state = state.copyWith(
            activeDownloads: newActiveDownloads,
            downloadedLessons: newDownloadedLessons,
          );

          logger.i('Download completed for lesson ${lesson.id}');
        } else if (progress.status == DownloadStatus.failed) {
          // Download failed - remove from active
          newActiveDownloads.remove(lesson.id);
          state = state.copyWith(
            activeDownloads: newActiveDownloads,
            error: 'Download failed for lesson ${lesson.id}',
          );

          logger.e('Download failed for lesson ${lesson.id}');
        } else {
          // Download in progress - update progress
          newActiveDownloads[lesson.id] = progress;
          state = state.copyWith(activeDownloads: newActiveDownloads);
        }
      }
    } catch (e) {
      logger.e('Error downloading lesson ${lesson.id}', error: e);

      final newActiveDownloads = Map<int, DownloadProgress>.from(state.activeDownloads);
      newActiveDownloads.remove(lesson.id);

      state = state.copyWith(
        activeDownloads: newActiveDownloads,
        error: 'Download error: $e',
      );
    }
  }

  /// Cancel download
  Future<void> cancelDownload(int lessonId) async {
    try {
      await _downloadManager.cancelDownload(lessonId);

      final newActiveDownloads = Map<int, DownloadProgress>.from(state.activeDownloads);
      newActiveDownloads.remove(lessonId);

      state = state.copyWith(activeDownloads: newActiveDownloads);

      logger.i('Cancelled download for lesson $lessonId');
    } catch (e) {
      logger.e('Failed to cancel download', error: e);
      state = state.copyWith(error: 'Failed to cancel: $e');
    }
  }

  /// Delete downloaded lesson
  Future<void> deleteDownload(int lessonId) async {
    try {
      await _downloadManager.deleteDownload(lessonId);

      final newDownloadedLessons = Map<int, bool>.from(state.downloadedLessons);
      newDownloadedLessons.remove(lessonId);

      state = state.copyWith(downloadedLessons: newDownloadedLessons);

      logger.i('Deleted download for lesson $lessonId');
    } catch (e) {
      logger.e('Failed to delete download', error: e);
      state = state.copyWith(error: 'Failed to delete: $e');
    }
  }

  /// Check if lesson is downloaded
  bool isLessonDownloaded(int lessonId) {
    return state.downloadedLessons[lessonId] == true;
  }

  /// Check if lesson is downloading
  bool isLessonDownloading(int lessonId) {
    return state.activeDownloads.containsKey(lessonId);
  }

  /// Get download progress for lesson
  DownloadProgress? getDownloadProgress(int lessonId) {
    return state.activeDownloads[lessonId];
  }

  /// Refresh downloaded lessons list
  Future<void> refresh() async {
    await _loadDownloadedLessons();
  }
}

/// Download manager provider
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager();
});

/// Download provider
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final downloadManager = ref.watch(downloadManagerProvider);
  return DownloadNotifier(downloadManager);
});

/// Helper provider to check if lesson is downloaded
final isLessonDownloadedProvider = Provider.family<bool, int>((ref, lessonId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.downloadedLessons[lessonId] == true;
});

/// Helper provider to check if lesson is downloading
final isLessonDownloadingProvider = Provider.family<bool, int>((ref, lessonId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.activeDownloads.containsKey(lessonId);
});

/// Helper provider to get download progress
final downloadProgressProvider = Provider.family<DownloadProgress?, int>((ref, lessonId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.activeDownloads[lessonId];
});

/// Provider for total downloaded size
final totalDownloadedSizeProvider = FutureProvider<int>((ref) async {
  final downloadManager = ref.watch(downloadManagerProvider);
  return await downloadManager.getTotalDownloadedSize();
});

/// Provider for downloaded lessons count
final downloadedLessonsCountProvider = FutureProvider<int>((ref) async {
  final downloadManager = ref.watch(downloadManagerProvider);
  return await downloadManager.getDownloadedCount();
});
