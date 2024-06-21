import 'dart:io';
import 'package:app/services/name_detection_interface.dart';
import 'package:app/services/name_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/name_detection_service.dart';

final nameDetectionResultProvider = NotifierProvider<NameDetectionNotifier,
    AsyncValue<List<NameDetectionResult>>>(() => NameDetectionNotifier());

class NameDetectionNotifier
    extends Notifier<AsyncValue<List<NameDetectionResult>>> {
  late NameDetectionInterface _nameDetectionService;

  @override
  AsyncValue<List<NameDetectionResult>> build() {
    _nameDetectionService = ref.watch(nameDetectionImplementationProvider);
    return const AsyncValue.loading();
  }

  Future<void> predictImage(File image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _nameDetectionService.predictFromImage(image));
    state.mapOrNull(error: (error) {
      print('Error processing image: $error');
    });
  }

  Future<void> registerPerson(String name, File image) =>
      _nameDetectionService.registerPerson(name, image);

  bool _isProcessing = false;

  Future<void> predictCameraStream(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final predictions =
          await _nameDetectionService.predictFromCameraStream(image);
      state = AsyncValue.data(predictions);
    } catch (error, stackTrace) {
      state = AsyncValue.error('Error processing image: $error', stackTrace);
    } finally {
      _isProcessing = false;
    }
  }
}
