import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math';

class NameDetectionService {
  static const facenetModelPath = 'assets/facenet_512_int_quantized.tflite';
  static const faceDetectorModelPath = 'assets/mask_detector.tflite';
  late Interpreter facenetInterpreter;
  late Interpreter faceDetectorInterpreter;
  late List<int> facenetInputShape;
  late List<int> facenetOutputShape;
  late List<int> faceDetectorInputShape;
  late List<int> faceDetectorOutputShape;

  NameDetectionService() {
    _loadModels();
  }

  Future<void> _loadModels() async {
    facenetInterpreter = await Interpreter.fromAsset(facenetModelPath);
    facenetInputShape = facenetInterpreter.getInputTensor(0).shape;
    facenetOutputShape = facenetInterpreter.getOutputTensor(0).shape;

    faceDetectorInterpreter =
        await Interpreter.fromAsset(faceDetectorModelPath);
    faceDetectorInputShape = faceDetectorInterpreter.getInputTensor(0).shape;
    faceDetectorOutputShape = faceDetectorInterpreter.getOutputTensor(0).shape;

    saveKnownFaces();
    print('done loading name detection model');
  }

  Future<img.Image> _loadImage(File image) async {
    final img.Image? decodedImage = img.decodeImage(image.readAsBytesSync());
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    return decodedImage;
  }

  Future<List<dynamic>> _detectFaces(img.Image image) async {
    // Resize image to match the model's input size
    img.Image resizedImage = img.copyResize(image,
        width: faceDetectorInputShape[1], height: faceDetectorInputShape[2]);

    // Ensure the image is in RGB format and extract RGB bytes
    var rgbImage = img.copyResize(resizedImage,
        width: faceDetectorInputShape[1], height: faceDetectorInputShape[2]);
    var rgbBytes = rgbImage.getBytes(format: img.Format.rgb);

    var input = Float32List.fromList(rgbBytes.map((e) => e / 255.0).toList());
    var output =
        List.filled(faceDetectorOutputShape.reduce((a, b) => a * b), 0.0)
            .reshape(faceDetectorOutputShape);
    print('output before faceDetectorINterpreter.run: $output');

    faceDetectorInterpreter.run(input.reshape(faceDetectorInputShape), output);
    print('output after faceDetectorINterpreter.run: $output');

    // Parse output - this will depend on the exact output format of your model
    // Assuming output is a list of detected face bounding boxes
    List<dynamic> faces = [];

    // TODO: don't understand yet what happens when multiple faces are detected.
    // let's take just the first face for now

    final data = faceDetectorInterpreter.getOutputTensor(0).data;
    return [
      {'x': data[0], 'y': data[1], 'width': data[2], 'height': data[3]}
    ];
/*
    for (var i = 0; i < output.length; i += 6) {
      if (output[i + 1] > 0.5) {
        // Assuming the confidence score is the second element
        faces.add({
          'x': (output[i + 2] * image.width).toInt(),
          'y': (output[i + 3] * image.height).toInt(),
          'width': ((output[i + 4] - output[i + 2]) * image.width).toInt(),
          'height': ((output[i + 5] - output[i + 3]) * image.height).toInt(),
        });
      }
    }*/
    return faces;
  }

  List<double> _generateEmbedding(img.Image faceImage) {
    // Resize and convert to RGB format
    img.Image resizedImage = img.copyResize(faceImage,
        width: facenetInputShape[1], height: facenetInputShape[2]);
    var rgbBytes = resizedImage.getBytes(format: img.Format.rgb);

    // Normalize pixel values to [0, 1]
    var input = Float32List.fromList(rgbBytes.map((e) => e / 255.0).toList());

    // Prepare output buffer
    var output =
        List.filled(facenetOutputShape[1], 0.0).reshape(facenetOutputShape);

    // Run embedding generation
    facenetInterpreter.run(input.reshape(facenetInputShape), output);

    return output[0].cast<double>();
  }

  Future<void> _saveEmbedding(String name, List<double> embedding) async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = path.join(directory.path, 'embeddings');
    final filePath = path.join(folderPath, '$name.json');

    final folder = Directory(folderPath);
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }

    final file = File(filePath);
    file.writeAsStringSync(jsonEncode(embedding));
  }

  Future<Map<String, List<double>>> _loadEmbeddings() async {
    final directory = await getApplicationDocumentsDirectory();
    final folderPath = path.join(directory.path, 'embeddings');

    final folder = Directory(folderPath);
    if (!folder.existsSync()) {
      return {};
    }

    final files =
        folder.listSync().where((file) => file.path.endsWith('.json')).toList();
    final embeddings = <String, List<double>>{};

    for (var file in files) {
      final name = path.basenameWithoutExtension(file.path);
      final content = File(file.path).readAsStringSync();
      final embedding = (jsonDecode(content) as List).cast<double>();
      embeddings[name] = embedding;
    }

    return embeddings;
  }

  Future<String?> _findMatch(
      List<double> newEmbedding, double threshold) async {
    final knownEmbeddings = await _loadEmbeddings();

    final distances = <String, double>{};
    String? result;
    for (var entry in knownEmbeddings.entries) {
      final name = entry.key;
      final embedding = entry.value;
      final distance = _calculateDistance(newEmbedding, embedding);
      distances[name] = distance;
      if (distance < threshold) {
        result = name;
        break;
      }
    }
    print(distances);
    return result;
  }

  double _calculateDistance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }

    return sqrt(sum);
  }

  Future<List<String>> recognizeFacesInImage(File imageFile) async {
    final image = await _loadImage(imageFile);
    final faces = await _detectFaces(image);

    final result = <String>[];

    for (var face in faces) {
      // Extract face bounding box
      final x = face['x'];
      final y = face['y'];
      final width = face['width'];
      final height = face['height'];

      final faceImage = img.copyCrop(image, x, y, width, height);
      final embedding = _generateEmbedding(faceImage);
      final name = await _findMatch(embedding, 1.2);

      if (name != null) result.add(name);

      if (name != null) {
        print('Face recognized: $name');
      } else {
        final newName = DateTime.now().millisecondsSinceEpoch.toString();
        print('Face not recognized, creating new face with name $newName');
        final personFolder =
            Directory(path.join(imageFile.parent.path, 'images', newName));
        await personFolder.create(recursive: true);
        final newImagePath = path.join(personFolder.path, '1.jpg');
        File(newImagePath).writeAsBytesSync(img.encodeJpg(faceImage));
        await _saveEmbedding(newName, embedding);
      }
    }

    return result;
  }

  Future<void> saveKnownFaces() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesPath = path.join(directory.path, 'images');
    final imagesFolder = Directory(imagesPath);
    if (!imagesFolder.existsSync()) {
      imagesFolder.createSync(recursive: true);
    }
    final knownFolders = imagesFolder.listSync().whereType<Directory>();

    final futures = <Future>[];

    for (var folder in knownFolders) {
      final personName = path.basename(folder.path);
      final images = folder.listSync().whereType<File>();

      for (var imageFile in images) {
        final image = img.decodeImage(imageFile.readAsBytesSync())!;
        final faces = await _detectFaces(image);

        for (var face in faces) {
          final box = face['box'];
          final faceImage = img.copyCrop(image, box[0], box[1], box[2], box[3]);
          final embedding = _generateEmbedding(faceImage);
          futures.add(_saveEmbedding(personName, embedding));
        }
      }
    }
    await Future.wait(futures);
  }
}
