import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/core/utils/bounding_box_utils.dart';
import 'package:ppe_vision/models/detection.dart';

Detection _box({
  required double x1,
  required double y1,
  required double x2,
  required double y2,
  DetectionClass type = DetectionClass.person,
}) {
  return Detection(
    classType: type,
    label: type.name,
    confidence: 0.9,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
  );
}

void main() {
  group('IoU', () {
    test('identical boxes have IoU of 1', () {
      final a = _box(x1: 0.1, y1: 0.1, x2: 0.5, y2: 0.5);
      expect(BoundingBoxUtils.calculateIoU(a, a), closeTo(1.0, 1e-9));
    });

    test('disjoint boxes have IoU of 0', () {
      final a = _box(x1: 0.0, y1: 0.0, x2: 0.2, y2: 0.2);
      final b = _box(x1: 0.5, y1: 0.5, x2: 0.7, y2: 0.7);
      expect(BoundingBoxUtils.calculateIoU(a, b), 0);
    });

    test('partial overlap is between 0 and 1', () {
      final a = _box(x1: 0.0, y1: 0.0, x2: 0.5, y2: 0.5);
      final b = _box(x1: 0.25, y1: 0.25, x2: 0.75, y2: 0.75);
      final iou = BoundingBoxUtils.calculateIoU(a, b);
      expect(iou, greaterThan(0));
      expect(iou, lessThan(1));
      expect(iou, closeTo(0.0625 / 0.4375, 1e-9));
    });
  });

  group('containment', () {
    test('child fully inside parent', () {
      final parent = _box(x1: 0.1, y1: 0.1, x2: 0.9, y2: 0.9);
      final child = _box(x1: 0.2, y1: 0.2, x2: 0.4, y2: 0.4);
      expect(BoundingBoxUtils.isInside(child, parent), isTrue);
    });

    test('child outside parent is not inside', () {
      final parent = _box(x1: 0.0, y1: 0.0, x2: 0.4, y2: 0.8);
      final child = _box(x1: 0.6, y1: 0.1, x2: 0.8, y2: 0.3);
      expect(BoundingBoxUtils.isInside(child, parent), isFalse);
    });

    test('centerInside requires the center, not full containment', () {
      final parent = _box(x1: 0.2, y1: 0.2, x2: 0.6, y2: 0.8);
      final child = _box(x1: 0.15, y1: 0.3, x2: 0.35, y2: 0.5);
      expect(BoundingBoxUtils.centerInside(child, parent), isTrue);
      expect(BoundingBoxUtils.isInside(child, parent), isFalse);
    });
  });
}
