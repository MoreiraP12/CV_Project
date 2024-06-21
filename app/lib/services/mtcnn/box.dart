import 'dart:ui';
import 'dart:math';
class Box {
  List<int> box;
  double score;
  List<double> bbr;
  bool deleted;
  List<Offset> landmark;

  Box()
      : box = List.filled(4, 0),
        score = 0.0,
        bbr = List.filled(4, 0.0),
        deleted = false,
        landmark = List.filled(5, Offset.zero);

  int get left => box[0];
  int get right => box[2];
  int get top => box[1];
  int get bottom => box[3];

  int get width => box[2] - box[0] + 1;
  int get height => box[3] - box[1] + 1;

  Rect transform2Rect() => Rect.fromLTRB(box[0].toDouble(), box[1].toDouble(), box[2].toDouble(), box[3].toDouble());

  int get area => width * height;

  void calibrate() {
    int w = box[2] - box[0] + 1;
    int h = box[3] - box[1] + 1;
    box[0] = (box[0] + w * bbr[0]).toInt();
    box[1] = (box[1] + h * bbr[1]).toInt();
    box[2] = (box[2] + w * bbr[2]).toInt();
    box[3] = (box[3] + h * bbr[3]).toInt();
    for (int i = 0; i < 4; i++) bbr[i] = 0.0;
  }

  void toSquareShape() {
    int w = width;
    int h = height;
    if (w > h) {
      box[1] -= (w - h) ~/ 2;
      box[3] += (w - h + 1) ~/ 2;
    } else {
      box[0] -= (h - w) ~/ 2;
      box[2] += (h - w + 1) ~/ 2;
    }
  }

  void limitSquare(int w, int h) {
    if (box[0] < 0 || box[1] < 0) {
      int len = max(-box[0], -box[1]);
      box[0] += len;
      box[1] += len;
    }
    if (box[2] >= w || box[3] >= h) {
      int len = max(box[2] - w + 1, box[3] - h + 1);
      box[2] -= len;
      box[3] -= len;
    }
  }

  bool transbound(int w, int h) {
    if (box[0] < 0 || box[1] < 0) {
      return true;
    } else if (box[2] >= w || box[3] >= h) {
      return true;
    }
    return false;
  }
}
