import 'dart:io';
import 'package:app/services/name_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/emotion_detection_service.dart';

final predictionProvider =
    StateNotifierProvider<PredictionNotifier, List<Prediction>?>((ref) {
  final predictionNotifier = PredictionNotifier();
  ref.listen(detectedFaceProvider, (_, newFace) {
    if (newFace != null) {
      predictionNotifier._predictImage(newFace);
    }
  });
  ;

  return predictionNotifier;
});

class PredictionNotifier extends StateNotifier<List<Prediction>?> {
  PredictionNotifier() : super(null);

  Future<void> _predictImage(File image) async {
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
