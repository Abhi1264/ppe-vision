import '../core/constants/detection_constants.dart';

class AppSettings {
  const AppSettings({
    required this.confidenceThreshold,
    required this.showOverlay,
    required this.showConfidence,
    required this.targetInferenceFps,
    required this.showFps,
    required this.showInferenceTime,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      confidenceThreshold: DetectionConstants.defaultConfidenceThreshold,
      showOverlay: true,
      showConfidence: true,
      targetInferenceFps: DetectionConstants.defaultTargetFps,
      showFps: true,
      showInferenceTime: true,
    );
  }

  final double confidenceThreshold;
  final bool showOverlay;
  final bool showConfidence;
  final int targetInferenceFps;
  final bool showFps;
  final bool showInferenceTime;

  AppSettings copyWith({
    double? confidenceThreshold,
    bool? showOverlay,
    bool? showConfidence,
    int? targetInferenceFps,
    bool? showFps,
    bool? showInferenceTime,
  }) {
    return AppSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      showOverlay: showOverlay ?? this.showOverlay,
      showConfidence: showConfidence ?? this.showConfidence,
      targetInferenceFps: targetInferenceFps ?? this.targetInferenceFps,
      showFps: showFps ?? this.showFps,
      showInferenceTime: showInferenceTime ?? this.showInferenceTime,
    );
  }
}
