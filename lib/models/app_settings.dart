import '../core/constants/app_constants.dart';
import '../core/constants/detection_constants.dart';

class AppSettings {
  const AppSettings({
    required this.confidenceThreshold,
    required this.backend,
    required this.showOverlay,
    required this.showConfidence,
    required this.targetInferenceFps,
    required this.showFps,
    required this.showInferenceTime,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      confidenceThreshold: DetectionConstants.defaultConfidenceThreshold,
      backend: DetectionBackend.mock,
      showOverlay: true,
      showConfidence: true,
      targetInferenceFps: DetectionConstants.defaultTargetFps,
      showFps: true,
      showInferenceTime: true,
    );
  }

  final double confidenceThreshold;
  final DetectionBackend backend;
  final bool showOverlay;
  final bool showConfidence;
  final int targetInferenceFps;
  final bool showFps;
  final bool showInferenceTime;

  AppSettings copyWith({
    double? confidenceThreshold,
    DetectionBackend? backend,
    bool? showOverlay,
    bool? showConfidence,
    int? targetInferenceFps,
    bool? showFps,
    bool? showInferenceTime,
  }) {
    return AppSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      backend: backend ?? this.backend,
      showOverlay: showOverlay ?? this.showOverlay,
      showConfidence: showConfidence ?? this.showConfidence,
      targetInferenceFps: targetInferenceFps ?? this.targetInferenceFps,
      showFps: showFps ?? this.showFps,
      showInferenceTime: showInferenceTime ?? this.showInferenceTime,
    );
  }
}
