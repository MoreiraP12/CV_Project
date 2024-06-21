import 'package:app/services/emotion_detection_interface.dart';
import 'package:app/services/emotion_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class PredictionInformation extends StatelessWidget {
  final List<EmotionDetectionResult> predictions;

  PredictionInformation({required this.predictions});

  @override
  Widget build(BuildContext context) {
    final colorMap = generateColorMap(predictions.length);
    return Container(
      color: Colors.black54,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: predictions
              .mapIndexed<Widget>((index, face) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Face $index',
                            style:  TextStyle(
                                color: colorMap[index], fontSize: 24),
                          ),
                          ...face.emotion.entries.map((entry) => Text(
                                '${entry.key.padRight(8)} ${entry.value.toStringAsFixed(10).padLeft(13)} %',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: entry.key == face.dominantEmotion
                                      ? Colors.green
                                      : Colors.white,
                                  fontSize: 16,
                                ),
                              ))
                        ]),
                  ))
              .toList()),
    );
  }
}


List<Color> generateColorMap(int numColors) {
  List<Color> colors = [];
  double hueStep = 360.0 / numColors;

  for (int i = 0; i < numColors; i++) {
    double hue = (i * hueStep) % 360;
    colors.add(HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor());
  }

  return colors;
}
