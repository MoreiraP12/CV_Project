import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/emotion_detection_service.dart';

final predictionProvider =
    StateNotifierProvider<PredictionNotifier, List<Prediction>?>((ref) {
  return PredictionNotifier();
});

class PredictionNotifier extends StateNotifier<List<Prediction>?> {
  PredictionNotifier() : super(null);

  Future<void> predictImage(File image) async {
    final predictions = await EmotionDetectionService.predictFromImage(image);
    state = predictions;
  }

  bool _isProcessing = false;

  Future<void> predictCameraStream(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;
    final predictions =
        await EmotionDetectionService.predictFromCameraStream(image);
    state = predictions;
    _isProcessing = false;
  }
}
