import 'package:app/services/emotion_detection_service.dart';
import 'package:flutter/material.dart';

class PredictionInformation extends StatelessWidget {
  final List<Prediction> predictions;

  PredictionInformation({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final mostProbablePrediction = predictions.isEmpty ? null : 
        predictions.reduce((a, b) => a.confidence > b.confidence ? a : b);

    return Container(
      color: Colors.black54,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Wrap(
        direction: Axis.vertical,
        children: predictions
            .map((prediction) => Text(
                  '${prediction.label} ${(100 * prediction.confidence).toStringAsFixed(2)} %',
                  style: TextStyle(
                      color: prediction == mostProbablePrediction
                          ? Colors.green
                          : Colors.white,
                      fontSize: 16),
                ))
            .toList(),
      ),
    );
  }
}
