import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/constants/detection_constants.dart';
import '../../core/utils/bounding_box_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../models/detection.dart';

/// Decode a YOLO11 detect head: `[1, 4+nc, N]` or `[1, N, 4+nc]`, xywh in
/// model pixels, class scores already passed through sigmoid (logits are
/// accepted too).
List<Detection> decodeYoloOutput({
  required Float32List values,
  required List<int> shape,
  required int modelWidth,
  required int modelHeight,
  required double padX,
  required double padY,
  required double letterboxScale,
  required int uprightWidth,
  required int uprightHeight,
  List<String> labels = DetectionConstants.modelLabels,
  double confidenceThreshold = DetectionConstants.minConfidenceThreshold,
  double iouThreshold = DetectionConstants.nmsIouThreshold,
  int maxDetections = DetectionConstants.maxDetections,
}) {
  if (shape.length != 3 || letterboxScale <= 0) {
    throw ArgumentError('Unexpected YOLO output shape $shape');
  }
  final channels = 4 + labels.length;
  final channelsFirst = shape[1] == channels;
  final channelsLast = shape[2] == channels;
  if (!channelsFirst && !channelsLast) {
    throw ArgumentError(
      'YOLO output $shape does not match ${labels.length} classes',
    );
  }
  final boxCount = channelsFirst ? shape[2] : shape[1];
  if (values.length < boxCount * channels ||
      uprightWidth <= 0 ||
      uprightHeight <= 0) {
    throw ArgumentError('YOLO output is shorter than its shape $shape');
  }

  final found = <Detection>[];
  for (var box = 0; box < boxCount; box++) {
    double at(int channel) {
      final index = channelsFirst
          ? channel * boxCount + box
          : box * channels + channel;
      return values[index];
    }

    var bestClass = 0;
    var bestScore = at(4);
    for (var c = 1; c < labels.length; c++) {
      final score = at(4 + c);
      if (score > bestScore) {
        bestScore = score;
        bestClass = c;
      }
    }
    if (bestScore < 0 || bestScore > 1) {
      bestScore = 1 / (1 + math.exp(-bestScore));
    }
    if (bestScore < confidenceThreshold) continue;

    final cx = at(0);
    final cy = at(1);
    final w = at(2);
    final h = at(3);
    if (w <= 0 || h <= 0) continue;

    final mapped = _unmap(
      x1: cx - w / 2,
      y1: cy - h / 2,
      x2: cx + w / 2,
      y2: cy + h / 2,
      modelWidth: modelWidth,
      modelHeight: modelHeight,
      padX: padX,
      padY: padY,
      letterboxScale: letterboxScale,
      uprightWidth: uprightWidth,
      uprightHeight: uprightHeight,
    );
    if (mapped == null) continue;

    final raw = labels[bestClass];
    final classType = detectionClassFromLabel(raw);
    found.add(
      Detection(
        classType: classType,
        label: switch (classType) {
          DetectionClass.helmet => 'helmet',
          DetectionClass.vest => 'vest',
          DetectionClass.person => 'person',
          DetectionClass.unknown => raw,
        },
        confidence: bestScore,
        x1: mapped.$1,
        y1: mapped.$2,
        x2: mapped.$3,
        y2: mapped.$4,
      ),
    );
  }

  found.sort((a, b) => b.confidence.compareTo(a.confidence));
  final dropped = List<bool>.filled(found.length, false);
  final selected = <Detection>[];
  for (var i = 0; i < found.length; i++) {
    if (dropped[i]) continue;
    selected.add(found[i]);
    if (selected.length == maxDetections) break;
    for (var j = i + 1; j < found.length; j++) {
      if (dropped[j] || found[j].classType != found[i].classType) continue;
      if (BoundingBoxUtils.calculateIoU(found[i], found[j]) > iouThreshold) {
        dropped[j] = true;
      }
    }
  }
  return selected;
}

(double, double, double, double)? _unmap({
  required double x1,
  required double y1,
  required double x2,
  required double y2,
  required int modelWidth,
  required int modelHeight,
  required double padX,
  required double padY,
  required double letterboxScale,
  required int uprightWidth,
  required int uprightHeight,
}) {
  final topLeft = ImageUtils.removeLetterbox(
    nx: x1 / modelWidth,
    ny: y1 / modelHeight,
    scale: letterboxScale,
    padX: padX,
    padY: padY,
    modelWidth: modelWidth.toDouble(),
    modelHeight: modelHeight.toDouble(),
  );
  final bottomRight = ImageUtils.removeLetterbox(
    nx: x2 / modelWidth,
    ny: y2 / modelHeight,
    scale: letterboxScale,
    padX: padX,
    padY: padY,
    modelWidth: modelWidth.toDouble(),
    modelHeight: modelHeight.toDouble(),
  );
  final nx1 = topLeft.x / uprightWidth;
  final ny1 = topLeft.y / uprightHeight;
  final nx2 = bottomRight.x / uprightWidth;
  final ny2 = bottomRight.y / uprightHeight;
  if (nx2 <= nx1 || ny2 <= ny1) return null;
  return (nx1, ny1, nx2, ny2);
}
