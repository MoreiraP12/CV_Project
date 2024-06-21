import 'dart:async';
import 'dart:io';
import 'package:app/services/emotion_detection_interface.dart';
import 'package:app/services/mtcnn/mtcnn.dart';
import 'package:camera/camera.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class EmotionDetectionService implements EmotionDetectionInterface {
  @override
  Future<List<EmotionDetectionResult>> predictFromImage(File image) async {
    // Read file as bytes
    final bytes = await image.readAsBytes();

    // Decode image using the image package
    final decodedImage = img.decodeImage(bytes)!;

    // Create a UI Image
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      decodedImage.getBytes(),
      decodedImage.width,
      decodedImage.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final bitmap = await completer.future;

    final faceBoundingBoxes = await mtcnn.detectFaces(bitmap, 50);

    final result = await Future.wait(faceBoundingBoxes.map((face) async {
      final croppedFace = img.copyCrop(decodedImage, face.left.toInt(),
          face.top.toInt(), face.width.toInt(), face.height.toInt());

      final result = await Tflite.runModelOnFrame(
        bytesList: [croppedFace.getBytes()],
        numResults: 7,
        threshold: 0.0,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      final emotions = result!
          .map((e) => Prediction.fromJson((e as Map).cast<String, dynamic>()));
      return EmotionDetectionResult(
        dominantEmotion: emotions
            .reduce((a, b) => a.confidence > b.confidence ? a : b)
            .label,
        emotion: Map.fromEntries(
            emotions.map((e) => MapEntry(e.label, e.confidence))),
        region: Region(
          h: face.height,
          w: face.width,
          x: face.left,
          y: face.top,
        ),
      );
    }));

    return result;
  }

  @override
  Future<List<EmotionDetectionResult>> predictFromCameraStream(
      CameraImage image) async {
    final file = await File('temp.jpg').writeAsBytes(image.planes[0].bytes);
    return predictFromImage(file);
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
