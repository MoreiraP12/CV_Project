import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

final modelProvider = NotifierProvider<ModelNotifier, ModelType>(() {
  return ModelNotifier();
});

final modelLoadedProvider = StateProvider<bool>((ref) => false);

class ModelNotifier extends Notifier<ModelType> {
  @override
  ModelType build() {
    const initialModel = ModelType.emaiface;
    _loadModel(initialModel).then((_) {
      ref.read(modelLoadedProvider.notifier).state = true;
    });
    return initialModel;
  }

  Future<void> _loadModel(ModelType model) async {
    await Tflite.loadModel(
      model: model.modelPath,
      labels: model.labelPath,
    );
  }

  Future<void> changeModel(ModelType newModel) async {
    state = newModel;
    await _loadModel(state);
  }
}

enum ModelType {
  vggface(
    modelPath: "assets/trained_vggface.tflite",
    labelPath: "assets/trained_vggface.txt",
    displayName: "VGGFace",
  ),

  emaiface(
    modelPath: "assets/converted_model.tflite",
    labelPath: "assets/converted_model.txt",
    displayName: "EMAIFace",
  ),
  ;

  const ModelType({
    required this.modelPath,
    required this.labelPath,
    required this.displayName,
  });

  final String modelPath;
  final String labelPath;
  final String displayName;
}
