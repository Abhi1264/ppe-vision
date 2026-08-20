enum DetectionClass { person, helmet, vest, unknown }

class Detection {
  const Detection({
    required this.classType,
    required this.label,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final DetectionClass classType;
  final String label;
  final double confidence;

  /// Normalized 0–1.
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  double get width => x2 - x1;
  double get height => y2 - y1;
  double get area => width * height;
  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;

  Detection clampNormalized() {
    return Detection(
      classType: classType,
      label: label,
      confidence: confidence,
      x1: x1.clamp(0.0, 1.0),
      y1: y1.clamp(0.0, 1.0),
      x2: x2.clamp(0.0, 1.0),
      y2: y2.clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Detection &&
            classType == other.classType &&
            label == other.label &&
            confidence == other.confidence &&
            x1 == other.x1 &&
            y1 == other.y1 &&
            x2 == other.x2 &&
            y2 == other.y2;
  }

  @override
  int get hashCode => Object.hash(classType, label, confidence, x1, y1, x2, y2);
}

DetectionClass detectionClassFromLabel(String label) {
  return switch (label.trim().toLowerCase()) {
    'person' => DetectionClass.person,
    'helmet' || 'hardhat' || 'hard_hat' => DetectionClass.helmet,
    'vest' || 'safety vest' || 'safety_vest' => DetectionClass.vest,
    _ => DetectionClass.unknown,
  };
}
