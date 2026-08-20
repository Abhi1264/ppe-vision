import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/detection.dart';

class DetectionBoxStyle {
  DetectionBoxStyle._();

  static Color colorFor(DetectionClass type, {bool? compliant}) {
    return switch (type) {
      DetectionClass.person => compliant == null
          ? AppColors.personStroke
          : (compliant ? AppColors.compliant : AppColors.violation),
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
}
