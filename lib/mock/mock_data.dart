import 'dart:math' as math;

import '../models/detection.dart';

// Person 1: helmet+vest. Person 2: helmet. Person 3: vest.
class MockData {
  MockData._();

  static List<Detection> scene({double phase = 0}) {
    final drift = 0.008 * math.sin(phase);

    return [
      _person(
        label: 'person',
        x1: 0.04 + drift,
        y1: 0.16,
        x2: 0.31 + drift,
        y2: 0.94,
        confidence: 0.96,
      ),
      _box(
        DetectionClass.helmet,
        'helmet',
        0.10 + drift,
        0.16,
        0.24 + drift,
        0.30,
        0.94,
      ),
      _box(
        DetectionClass.vest,
        'vest',
        0.08 + drift,
        0.34,
        0.27 + drift,
        0.68,
        0.91,
      ),
      _person(
        label: 'person',
        x1: 0.36,
        y1: 0.14 - drift,
        x2: 0.64,
        y2: 0.93 - drift,
        confidence: 0.93,
      ),
      _box(
        DetectionClass.helmet,
        'helmet',
        0.43,
        0.14 - drift,
        0.57,
        0.28 - drift,
        0.89,
      ),
      _person(
        label: 'person',
        x1: 0.68 - drift,
        y1: 0.18,
        x2: 0.96 - drift,
        y2: 0.95,
        confidence: 0.91,
      ),
      _box(
        DetectionClass.vest,
        'vest',
        0.73 - drift,
        0.38,
        0.92 - drift,
        0.72,
        0.88,
      ),
    ];
  }

  static Detection _person({
    required String label,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double confidence,
  }) {
    return Detection(
      classType: DetectionClass.person,
      label: label,
      confidence: confidence,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
    );
  }

  static Detection _box(
    DetectionClass type,
    String label,
    double x1,
    double y1,
    double x2,
    double y2,
    double confidence,
  ) {
    return Detection(
      classType: type,
      label: label,
      confidence: confidence,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
    );
  }
}
