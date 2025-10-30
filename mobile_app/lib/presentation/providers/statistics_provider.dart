import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/dio_provider.dart';
import '../../data/api/api_client.dart';
import '../../data/models/series_statistics.dart';

/// Provider for all series statistics
final allStatisticsProvider = FutureProvider<List<SeriesStatisticsDetailed>>((ref) async {
  final dio = DioProvider.getDio();
  final apiClient = ApiClient(dio);
  return await apiClient.getAllStatistics();
});

/// Provider for specific series statistics
final seriesStatisticsProvider = FutureProvider.family<SeriesStatistics, int>((ref, seriesId) async {
  final dio = DioProvider.getDio();
  final apiClient = ApiClient(dio);
  return await apiClient.getSeriesStatistics(seriesId);
});
