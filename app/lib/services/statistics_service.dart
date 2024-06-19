import '../models/inference_stat.dart';

class StatisticsService {
  static Future<List<InferenceStat>> getInferenceStats() async {
    // placeholder data
    return [
      InferenceStat(DateTime.now().subtract(Duration(minutes: 1)), 0.8),
      InferenceStat(DateTime.now().subtract(Duration(minutes: 2)), 0.6),
      InferenceStat(DateTime.now().subtract(Duration(minutes: 3)), 0.7),
    ];
  }
}
