import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
import '../providers/statistics_provider.dart';


// TODO add some charts for e.g. inference time?
class StatisticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: statistics.when(
        data: (stats) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Inference Statistics', style: TextStyle(fontSize: 20)),
              Expanded(
                child: charts.TimeSeriesChart(
                  [
                    charts.Series<dynamic, DateTime>(
                      id: 'Inferences',
                      data: stats,
                      domainFn: (dynamic stat, _) => stat.time,
                      measureFn: (dynamic stat, _) => stat.value,
                    ),
                  ],
                  animate: true,
                ),
              ),
            ],
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
