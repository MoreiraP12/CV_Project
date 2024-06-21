import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Align {
  static Future<ui.Image> faceAlign(ui.Image image, List<Offset> landmarks) async {
    double diffEyeX = landmarks[1].dx - landmarks[0].dx;
    double diffEyeY = landmarks[1].dy - landmarks[0].dy;

    double fAngle;
    if (diffEyeY.abs() < 1e-7) {
      fAngle = 0.0;
    } else {
      fAngle = atan(diffEyeY / diffEyeX) * 180.0 / pi;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    final matrix = Matrix4.identity()..rotateZ(-fAngle * pi / 180);
    canvas.drawImage(image, Offset.zero, paint);
    canvas.transform(matrix.storage);
    final picture = recorder.endRecording();
    return picture.toImage(image.width, image.height);
  }
}
