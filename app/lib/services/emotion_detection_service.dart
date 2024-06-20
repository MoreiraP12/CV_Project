import 'dart:io';
import 'package:camera/camera.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';


// TODO use other package instead so we can use just one package for name detection too
// https://pub.dev/packages/tflite_flutter
// https://github.com/tensorflow/flutter-tflite/blob/main/example/image_classification_mobilenet/lib/helper/image_classification_helper.dart

class EmotionDetectionService {
  static Future<List<Prediction>> predictFromImage(File image) async {
    final result = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 7,
      threshold: 0.0,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    return result!.map((e) => Prediction.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  static Future<List<Prediction>> predictFromCameraStream(CameraImage image) async {
    // Mock prediction
    final result = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 7, // defaults to 5
        threshold: 0.0, // defaults to 0.1
        );

    return result!.map((e) => Prediction.fromJson((e as Map).cast<String, dynamic>())).toList();
  }
}

class Prediction {
  final String label;
  final double confidence;

  Prediction(this.label, this.confidence);

  Prediction.fromJson(Map<String, dynamic> json)
      : label = json['label'],
        confidence = json['confidence'];
}