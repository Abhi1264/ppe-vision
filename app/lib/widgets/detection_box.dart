import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../models/detection.dart';

class DetectionBoxStyle {
  DetectionBoxStyle._();

  static Color colorFor(DetectionClass type, {bool? compliant}) {
    return switch (type) {
      DetectionClass.person => switch (compliant) {
        null => AppColors.personStroke,
        true => AppColors.compliant,
        false => AppColors.violation,
      },
      DetectionClass.helmet => AppColors.helmet,
      DetectionClass.vest => AppColors.vest,
      DetectionClass.unknown => AppColors.muted,
    };
  }

  static String caption(Detection detection, {required bool showConfidence}) {
    final label = detection.label.toUpperCase();
    if (!showConfidence) return label;
    final pct = (detection.confidence * 100).round();
    return '$label  $pct%';
  }

  static double strokeFor(DetectionClass type) {
    return type == DetectionClass.person
        ? AppLayout.overlayStrokePerson
        : AppLayout.overlayStrokeObject;
  }
}
