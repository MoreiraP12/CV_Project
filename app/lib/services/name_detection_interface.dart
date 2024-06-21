import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:app/services/name_detection_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:meta/meta.dart';
import 'dart:convert';


final Provider<NameDetectionInterface>
    nameDetectionImplementationProvider =
    Provider<NameDetectionInterface>((ref) => NameDetectionService());


abstract interface class NameDetectionInterface {
  Future<List<NameDetectionResult>> predictFromImage(File imageFile);
  Future<List<NameDetectionResult>> predictFromCameraStream(CameraImage image);
  Future<void> registerPerson(String name, File imageFile);
}

class NameDetectionResult {
    final String name;
    final double probability;
    final Rectangle rectangle;
    final String uuid;
    final List<dynamic> collections;

    NameDetectionResult({
        required this.name,
        required this.probability,
        required this.rectangle,
        required this.uuid,
        required this.collections,
    });

    factory NameDetectionResult.fromRawJson(String str) => NameDetectionResult.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory NameDetectionResult.fromJson(Map<String, dynamic> json) => NameDetectionResult(
        name: json["name"],
        probability: json["probability"]?.toDouble(),
        rectangle: Rectangle.fromJson(json["rectangle"]),
        uuid: json["uuid"],
        collections: List<dynamic>.from(json["collections"].map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "probability": probability,
        "rectangle": rectangle.toJson(),
        "uuid": uuid,
        "collections": List<dynamic>.from(collections.map((x) => x)),
    };
}

class Rectangle {
    final int left;
    final int top;
    final int right;
    final int bottom;

    Rectangle({
        required this.left,
        required this.top,
        required this.right,
        required this.bottom,
    });

    factory Rectangle.fromRawJson(String str) => Rectangle.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Rectangle.fromJson(Map<String, dynamic> json) => Rectangle(
        left: json["left"],
        top: json["top"],
        right: json["right"],
        bottom: json["bottom"],
    );

    Map<String, dynamic> toJson() => {
        "left": left,
        "top": top,
        "right": right,
        "bottom": bottom,
    };
}
