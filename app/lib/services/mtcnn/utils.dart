import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:app/services/mtcnn/box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class Utils {
  static Future<ui.Image> copyBitmap(ui.Image bitmap) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(bitmap, Offset.zero, Paint());
    final picture = recorder.endRecording();
    return picture.toImage(bitmap.width, bitmap.height);
  }

  static Future<void> drawRect(ui.Image bitmap, Rect rect, int thick) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(bitmap, Offset.zero, Paint());
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = thick.toDouble()
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);
    final picture = recorder.endRecording();
    await picture.toImage(bitmap.width, bitmap.height);
  }

  static Future<void> drawPoints(
      ui.Image bitmap, List<Offset> landmarks, int thick) async {
    for (var point in landmarks) {
      await drawRect(
          bitmap,
          Rect.fromCenter(
              center: point, width: thick.toDouble(), height: thick.toDouble()),
          thick);
    }
  }

  static Future<void> drawBox(ui.Image bitmap, Box box, int thick) async {
    await drawRect(bitmap, box.transform2Rect(), thick);
    await drawPoints(bitmap, box.landmark, thick);
  }

  // Read image from assets
  static Future<ui.Image> readFromAssets(String filename) async {
    ByteData data = await rootBundle.load(filename);
    ui.Codec codec =
        await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  // Extend rect with margin
  static Rect rectExtend(ui.Image bitmap, Rect rect, int marginX, int marginY) {
    return Rect.fromLTRB(
      (rect.left - marginX / 2).clamp(0, bitmap.width - 1).toDouble(),
      (rect.top - marginY / 2).clamp(0, bitmap.height - 1).toDouble(),
      (rect.right + marginX / 2).clamp(0, bitmap.width - 1).toDouble(),
      (rect.bottom + marginY / 2).clamp(0, bitmap.height - 1).toDouble(),
    );
  }

  // Extend rect using height
  static Rect rectExtendHeight(ui.Image bitmap, Rect rect) {
    final width = rect.right - rect.left;
    final height = rect.bottom - rect.top;
    final margin = (height - width) ~/ 2;
    return Rect.fromLTRB(
      (rect.left - margin).clamp(0, bitmap.width - 1).toDouble(),
      rect.top.toDouble(),
      (rect.right + margin).clamp(0, bitmap.width - 1).toDouble(),
      rect.bottom.toDouble(),
    );
  }

  // Load model file
  static Future<ByteBuffer> loadModelFile(String modelPath) async {
    ByteData data = await rootBundle.load(modelPath);
    return data.buffer;
  }

  // Normalize image to [-1, 1]
  static Future<List<List<List<double>>>> normalizeImage(
      ui.Image bitmap) async {
    int width = bitmap.width;
    int height = bitmap.height;
    var pixels = List.filled(height, List.filled(width, List.filled(3, 0.0)));
    final bytes = (await bitmap.toByteData())!;

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        int val = bytes.getUint32(i * width + j);
        double r = (((val >> 16) & 0xFF) - 127.5) / 128;
        double g = (((val >> 8) & 0xFF) - 127.5) / 128;
        double b = ((val & 0xFF) - 127.5) / 128;
        pixels[i][j] = [r, g, b];
      }
    }
    return pixels;
  }

  // Resize bitmap
  static Future<ui.Image> bitmapResize(ui.Image bitmap, double scale) async {
    int width = (bitmap.width * scale).round();
    int height = (bitmap.height * scale).round();
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(
        recorder,
        Rect.fromPoints(
            Offset(0, 0), Offset(width.toDouble(), height.toDouble())));
    var paint = Paint();
    canvas.drawImageRect(
        bitmap,
        Rect.fromLTWH(0, 0, bitmap.width.toDouble(), bitmap.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paint);
    var picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  // Transpose image
  static List<List<List<double>>> transposeImage(
      List<List<List<double>>> input) {
    int height = input.length;
    int width = input[0].length;
    int channel = input[0][0].length;
    var output = List.generate(
        width, (_) => List.generate(height, (_) => List.filled(channel, 0.0)));
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        for (int k = 0; k < channel; k++) {
          output[j][i][k] = input[i][j][k];
        }
      }
    }
    return output;
  }

  // Transpose batch
  static List<List<List<List<double>>>> transposeBatch(
      List<List<List<List<double>>>> input) {
    int batch = input.length;
    int height = input[0].length;
    int width = input[0][0].length;
    int channel = input[0][0][0].length;
    var output = List.generate(
        batch,
        (_) => List.generate(width,
            (_) => List.generate(height, (_) => List.filled(channel, 0.0))));
    for (int i = 0; i < batch; i++) {
      for (int j = 0; j < height; j++) {
        for (int k = 0; k < width; k++) {
          for (int l = 0; l < channel; l++) {
            output[i][k][j][l] = input[i][j][k][l];
          }
        }
      }
    }
    return output;
  }

  // Crop and resize
  static Future<List<List<List<double>>>> cropAndResize(
      ui.Image bitmap, Box box, int size) async {
    double scaleW = size / box.width.toDouble();
    double scaleH = size / box.height.toDouble();
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    var paint = Paint();
    canvas.scale(scaleW, scaleH);
    canvas.drawImageRect(
        bitmap,
        Rect.fromLTRB(box.left.toDouble(), box.top.toDouble(),
            box.right.toDouble(), box.bottom.toDouble()),
        Rect.fromLTWH(0, 0, box.width.toDouble(), box.height.toDouble()),
        paint);
    var picture = recorder.endRecording();
    var cropped = await picture.toImage(box.width, box.height);
    return normalizeImage(cropped);
  }

  // Crop image
  static Future<ui.Image> crop(ui.Image bitmap, Rect rect) async {
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    var paint = Paint();
    canvas.drawImageRect(
        bitmap, rect, Rect.fromLTWH(0, 0, rect.width, rect.height), paint);
    var picture = recorder.endRecording();
    return picture.toImage(rect.width.toInt(), rect.height.toInt());
  }

  // L2 normalize
  static void l2Normalize(List<List<double>> embeddings, double epsilon) {
    for (var embedding in embeddings) {
      double squareSum = embedding.map((x) => x * x).reduce((a, b) => a + b);
      double xInvNorm =
          (squareSum > epsilon) ? sqrt((1.0 / (squareSum + epsilon))) : 1.0;
      for (int j = 0; j < embedding.length; j++) {
        embedding[j] *= xInvNorm;
      }
    }
  }

  // Convert to grayscale
  static Future<List<List<int>>> convertGreyImg(ui.Image bitmap) async {
    int width = bitmap.width;
    int height = bitmap.height;
    var pixels = List.filled(height, List.filled(width, 0));
    final bytes = (await bitmap.toByteData())!;

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        int val = bytes.getUint32(i * width + j);
        int red = (val >> 16) & 0xFF;
        int green = (val >> 8) & 0xFF;
        int blue = val & 0xFF;
        int grey = (red * 0.3 + green * 0.59 + blue * 0.11).toInt();
        pixels[i][j] = (0xFF << 24) | (grey << 16) | (grey << 8) | grey;
      }
    }

    return pixels;
  }
}
