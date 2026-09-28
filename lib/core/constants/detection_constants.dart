class DetectionConstants {
  static const String modelAsset = 'assets/models/ppe_model.tflite';

  /// Class order baked into helemt-vest-detection/best.pt (YOLO11s, imgsz 640).
  static const List<String> modelLabels = ['hardhat', 'vest', 'person'];

  static const double nmsIouThreshold = 0.7;

  // ponytail: cap 100 boxes after NMS; raise if a crowded site drops people
  static const int maxDetections = 100;

  static const double defaultConfidenceThreshold = 0.25;
  static const double minConfidenceThreshold = 0.1;
  static const double maxConfidenceThreshold = 0.9;

  static const int defaultTargetFps = 8;
  static const int minTargetFps = 5;
  static const int maxTargetFps = 15;

  static const double helmetVerticalMax = 0.45;
  static const double vestVerticalMin = 0.18;
  static const double vestVerticalMax = 0.85;
  static const double associationIouThreshold = 0.02;
}
