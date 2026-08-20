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

  /// Normalized coordinates from 0.0 to 1.0.
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
}

DetectionClass detectionClassFromLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'person':
      return DetectionClass.person;
    case 'helmet':
    case 'hardhat':
    case 'hard_hat':
      return DetectionClass.helmet;
    case 'vest':
    case 'safety vest':
    case 'safety_vest':
      return DetectionClass.vest;
    default:
      return DetectionClass.unknown;
  }
}
