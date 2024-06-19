import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inference_stat.dart';
import '../services/statistics_service.dart';

final statisticsProvider = FutureProvider<List<InferenceStat>>((ref) async {
  return await StatisticsService.getInferenceStats();
});
