import 'dart:io';
import 'package:app/services/emotion_detection_interface.dart';
import 'package:app/services/name_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/emotion_detection_service.dart';

final emotionDetectionResultProvider = NotifierProvider<
    EmotionDetectionNotifier,
    AsyncValue<List<EmotionDetectionResult>>>(() => EmotionDetectionNotifier());

class EmotionDetectionNotifier
    extends Notifier<AsyncValue<List<EmotionDetectionResult>>> {
  late EmotionDetectionInterface _emotionDetectionService;

  @override
  AsyncValue<List<EmotionDetectionResult>> build() {
    _emotionDetectionService =
        ref.watch(emotionDetectionImplementationProvider);
    return const AsyncValue.loading();
  }

  Future<void> predictImage(File image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _emotionDetectionService.predictFromImage(image));
    state.mapOrNull(error: (error) {
      print('Error processing image: $error');
    });
  }
  

  bool _isProcessing = false;

  Future<void> predictCameraStream(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final predictions =
          await _emotionDetectionService.predictFromCameraStream(image);
      state = AsyncValue.data(predictions);
    } catch (error, stackTrace) {
      state = AsyncValue.error('Error processing image: $error', stackTrace);
    } finally {
      _isProcessing = false;
    }
  }
}
