class DetectionConstants {
  static const double defaultConfidenceThreshold = 0.5;
  static const double minConfidenceThreshold = 0.1;
  static const double maxConfidenceThreshold = 0.9;

  static const int defaultTargetFps = 8;
  static const int minTargetFps = 5;
  static const int maxTargetFps = 15;

  /// Helmets are associated when their center sits in the upper portion
  /// of a person box.
  static const double helmetVerticalMax = 0.45;

  /// Vests are associated when their center sits in the torso band.
  static const double vestVerticalMin = 0.18;
  static const double vestVerticalMax = 0.85;

  /// Minimum IoU (or containment) required to pair PPE with a person.
  static const double associationIouThreshold = 0.02;

  static const Duration mockInferenceMin = Duration(milliseconds: 90);
  static const Duration mockInferenceJitter = Duration(milliseconds: 50);
}
