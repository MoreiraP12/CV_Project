import 'dart:io';
import 'package:app/services/emotion_detection_service.dart';
import 'package:camera/camera.dart';

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<EmotionDetectionInterface>
    emotionDetectionImplementationProvider =
    Provider<EmotionDetectionInterface>((ref) => EmotionDetectionService());

abstract interface class EmotionDetectionInterface {
  Future<List<EmotionDetectionResult>> predictFromImage(File imageFile);
  Future<List<EmotionDetectionResult>> predictFromCameraStream(
      CameraImage image);
}

class EmotionDetectionResult {
  final String dominantEmotion;
  final Map<String, double> emotion;
  final Region region;

  EmotionDetectionResult({
    required this.dominantEmotion,
    required this.emotion,
    required this.region,
  });

  factory EmotionDetectionResult.fromRawJson(String str) =>
      EmotionDetectionResult.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory EmotionDetectionResult.fromJson(Map<String, dynamic> json) =>
      EmotionDetectionResult(
        dominantEmotion: json["dominant_emotion"],
        emotion: json["emotion"].cast<String, double>(),
        region: Region.fromJson(json["region"]),
      );

  Map<String, dynamic> toJson() => {
        "dominant_emotion": dominantEmotion,
        "emotion": emotion,
        "region": region.toJson(),
      };
}

class Region {
  final int h;
  final int w;
  final int x;
  final int y;

  Region({
    required this.h,
    required this.w,
    required this.x,
    required this.y,
  });

  factory Region.fromRawJson(String str) => Region.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Region.fromJson(Map<String, dynamic> json) => Region(
        h: json["h"],
        w: json["w"],
        x: json["x"],
        y: json["y"],
      );

  Map<String, dynamic> toJson() => {
        "h": h,
        "w": w,
        "x": x,
        "y": y,
      };
}
