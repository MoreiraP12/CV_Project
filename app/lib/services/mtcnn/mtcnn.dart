import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'utils.dart';
import 'box.dart';
import 'dart:math';

final mtcnn = MTCNN();

class MTCNN {
  final double _factor = 0.709;
  final double _pNetThreshold = 0.6;
  final double _rNetThreshold = 0.7;
  final double _oNetThreshold = 0.7;

  late final Interpreter _pInterpreter;
  late final Interpreter _rInterpreter;
  late final Interpreter _oInterpreter;

  late final Future<void> __loaded;

  MTCNN() {
    __loaded = _loadModel();
  }

  Future<void> _loadModel() async {
    _pInterpreter = await Interpreter.fromAsset('assets/pnet.tflite');
    print('pnet');
    print(_pInterpreter.getOutputTensors().map((e) => e.name).toList());
    _rInterpreter = await Interpreter.fromAsset('assets/rnet.tflite');
    print('rnet');
    print(_rInterpreter.getOutputTensors().map((e) => e.name).toList());
    _oInterpreter = await Interpreter.fromAsset('assets/onet.tflite');
    print('onet');
    print(_oInterpreter.getOutputTensors().map((e) => e.name).toList());
  }

  Future<List<Box>> detectFaces(ui.Image bitmap, int minFaceSize) async {
    await __loaded;
    List<Box> boxes;
    try {
      boxes = await _pNet(bitmap, minFaceSize);
      _squareLimit(boxes, bitmap.width, bitmap.height);

      boxes = await _rNet(bitmap, boxes);
      _squareLimit(boxes, bitmap.width, bitmap.height);

      boxes = await _oNet(bitmap, boxes);
    } catch (e) {
      print(e);
      boxes = [];
    }
    return boxes;
  }

  void _squareLimit(List<Box> boxes, int w, int h) {
    for (var box in boxes) {
      box.toSquareShape();
      box.limitSquare(w, h);
    }
  }

  Future<List<Box>> _pNet(ui.Image bitmap, int minSize) async {
    int whMin = min(bitmap.width, bitmap.height);
    double currentFaceSize = minSize.toDouble();
    List<Box> totalBoxes = [];
    while (currentFaceSize <= whMin) {
      double scale = 12.0 / currentFaceSize;
      ui.Image bm = await Utils.bitmapResize(bitmap, scale);
      int w = bm.width;
      int h = bm.height;

      List<dynamic> outputs = await _pNetForward(bm);
      List<Box> curBoxes = _generateBoxes(outputs, scale);

      _nms(curBoxes, 0.5, "Union");

      for (var box in curBoxes) {
        if (!box.deleted) totalBoxes.add(box);
      }

      currentFaceSize /= _factor;
    }

    _nms(totalBoxes, 0.7, "Union");
    _boundingBoxRegression(totalBoxes);

    return _updateBoxes(totalBoxes);
  }

// pNetForward implementation
  Future<List<dynamic>> _pNetForward(ui.Image bitmap) async {
    final img = await Utils.normalizeImage(bitmap);
    final pNetIn = Utils.transposeBatch([img]);

    final prob1Index = 0; // _pInterpreter.getOutputIndex("pnet/prob1");
    final biasAddIndex = 1; //_pInterpreter.getOutputIndex("pnet/conv4-2/BiasAdd");
    final pnetProb1Shape = _pInterpreter.getOutputTensor(prob1Index).shape;
    final pnetBiasAddShape = _pInterpreter.getOutputTensor(biasAddIndex).shape;
    var outputs = <int, Object>{};
    outputs[prob1Index] =
        List.filled(pnetProb1Shape.reduce((a, b) => a * b), 0.0);
    outputs[biasAddIndex] =
        List.filled(pnetBiasAddShape.reduce((a, b) => a * b), 0.0);

    _pInterpreter.runForMultipleInputs([pNetIn], outputs);

    return outputs.values.toList();
  }

// generateBoxes implementation
  List<Box> _generateBoxes(List<dynamic> outputs, double scale) {
    List<Box> boxes = [];
    var prob1 = outputs[0] as List<List<List<List<double>>>>;
    var conv4_2_BiasAdd = outputs[1] as List<List<List<List<double>>>>;

    int h = prob1[0].length;
    int w = prob1[0][0].length;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double score = prob1[0][y][x][1];
        if (score > _pNetThreshold) {
          Box box = Box();
          box.score = score;
          box.box[0] = (x * 2 / scale).round();
          box.box[1] = (y * 2 / scale).round();
          box.box[2] = ((x * 2 + 11) / scale).round();
          box.box[3] = ((y * 2 + 11) / scale).round();
          for (int i = 0; i < 4; i++) {
            box.bbr[i] = conv4_2_BiasAdd[0][y][x][i];
          }
          boxes.add(box);
        }
      }
    }
    return boxes;
  }

// nms implementation
  void _nms(List<Box> boxes, double threshold, String method) {
    for (int i = 0; i < boxes.length; i++) {
      Box box = boxes[i];
      if (!box.deleted) {
        for (int j = i + 1; j < boxes.length; j++) {
          Box box2 = boxes[j];
          if (!box2.deleted) {
            int x1 = box.box[0].clamp(box2.box[0], box.box[2]);
            int y1 = box.box[1].clamp(box2.box[1], box.box[3]);
            int x2 = box.box[2].clamp(box.box[0], box2.box[2]);
            int y2 = box.box[3].clamp(box.box[1], box2.box[3]);
            if (x2 < x1 || y2 < y1) continue;
            int areaIoU = (x2 - x1 + 1) * (y2 - y1 + 1);
            double iou = (method == "Union")
                ? areaIoU / (box.area + box2.area - areaIoU)
                : areaIoU / min(box.area, box2.area);
            if (iou >= threshold) {
              if (box.score > box2.score)
                box2.deleted = true;
              else
                box.deleted = true;
            }
          }
        }
      }
    }
  }

// boundingBoxRegression implementation
  void _boundingBoxRegression(List<Box> boxes) {
    for (var box in boxes) {
      box.calibrate();
    }
  }

// rNet implementation
  Future<List<Box>> _rNet(ui.Image bitmap, List<Box> boxes) async {
    int num = boxes.length;
    var rNetIn = List.generate(
        num,
        (_) => List.generate(
            24, (_) => List.generate(24, (_) => List.filled(3, 0.0))));

    for (int i = 0; i < num; i++) {
      var curCrop = await Utils.cropAndResize(bitmap, boxes[i], 24);
      rNetIn[i] = Utils.transposeImage(curCrop);
    }

    final prob1Index = 0; //_rInterpreter.getOutputIndex("rnet/prob1");
    final conv5_2Index =
        1; //_rInterpreter.getOutputIndex("rnet/conv5-2/conv5-2");
    final prob1Shape = _rInterpreter.getOutputTensor(prob1Index).shape;
    final conv5_2Shape = _rInterpreter.getOutputTensor(conv5_2Index).shape;
    var outputs = <int, Object>{
      prob1Index: List.filled(prob1Shape.reduce((a, b) => a * b), 0.0),
      conv5_2Index: List.filled(conv5_2Shape.reduce((a, b) => a * b), 0.0)
    };

    _rInterpreter.runForMultipleInputs([rNetIn], outputs);

    var prob1 = outputs.values.elementAt(0) as List<List<double>>;
    var conv5_2 = outputs.values.elementAt(1) as List<List<double>>;

    for (int i = 0; i < num; i++) {
      boxes[i].score = prob1[i][1];
      for (int j = 0; j < 4; j++) {
        boxes[i].bbr[j] = conv5_2[i][j];
      }
    }

    boxes = boxes.where((box) => box.score >= _rNetThreshold).toList();
    _nms(boxes, 0.7, "Union");
    _boundingBoxRegression(boxes);
    return _updateBoxes(boxes);
  }

// oNet implementation
  Future<List<Box>> _oNet(ui.Image bitmap, List<Box> boxes) async {
    int num = boxes.length;
    var oNetIn = List.generate(
        num,
        (_) => List.generate(
            48, (_) => List.generate(48, (_) => List.filled(3, 0.0))));

    for (int i = 0; i < num; i++) {
      var curCrop = await Utils.cropAndResize(bitmap, boxes[i], 48);
      oNetIn[i] = Utils.transposeImage(curCrop);
    }

    final prob1Index = 0; //_oInterpreter.getOutputIndex("onet/prob1");
    final conv6_2Index =
        1; //_oInterpreter.getOutputIndex("onet/conv6-2/conv6-2");
    final conv6_3Index =
        2; //_oInterpreter.getOutputIndex("onet/conv6-3/conv6-3");
    final prob1Shape = _oInterpreter.getOutputTensor(prob1Index).shape;
    final conv6_2Shape = _oInterpreter.getOutputTensor(conv6_2Index).shape;
    final conv6_3Shape = _oInterpreter.getOutputTensor(conv6_3Index).shape;
    var outputs = <int, Object>{
      prob1Index: List.filled(prob1Shape.reduce((a, b) => a * b), 0.0),
      conv6_2Index: List.filled(conv6_2Shape.reduce((a, b) => a * b), 0.0),
      conv6_3Index: List.filled(conv6_3Shape.reduce((a, b) => a * b), 0.0)
    };

    _oInterpreter.runForMultipleInputs([oNetIn], outputs);

    var prob1 = outputs.values.elementAt(0) as List<List<double>>;
    var conv6_2 = outputs.values.elementAt(1) as List<List<double>>;
    var conv6_3 = outputs.values.elementAt(2) as List<List<double>>;

    for (int i = 0; i < num; i++) {
      boxes[i].score = prob1[i][1];
      for (int j = 0; j < 4; j++) {
        boxes[i].bbr[j] = conv6_2[i][j];
      }
      for (int j = 0; j < 5; j++) {
        int x = (boxes[i].left + (conv6_3[i][j] * boxes[i].width)).round();
        int y = (boxes[i].top + (conv6_3[i][j + 5] * boxes[i].height)).round();
        boxes[i].landmark[j] = Offset(x.toDouble(), y.toDouble());
      }
    }

    boxes = boxes.where((box) => box.score >= _oNetThreshold).toList();
    _boundingBoxRegression(boxes);
    _nms(boxes, 0.7, "Min");
    return _updateBoxes(boxes);
  }

  List<Box> _updateBoxes(List<Box> boxes) {
    List<Box> updatedBoxes = [];
    for (var box in boxes) {
      if (!box.deleted) {
        updatedBoxes.add(box);
      }
    }
    return updatedBoxes;
  }
}
