import '../core/constants/detection_constants.dart';

class AppSettings {
  const AppSettings({
    required this.confidenceThreshold,
    required this.showOverlay,
    required this.showConfidence,
    required this.targetInferenceFps,
    required this.showFps,
    required this.showInferenceTime,
    required this.requireHardhat,
    required this.requireVest,
    required this.confirmFrames,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      confidenceThreshold: DetectionConstants.defaultConfidenceThreshold,
      showOverlay: true,
      showConfidence: true,
      targetInferenceFps: DetectionConstants.defaultTargetFps,
      showFps: true,
      showInferenceTime: true,
      requireHardhat: true,
      requireVest: true,
      confirmFrames: 8,
    );
  }

  final double confidenceThreshold;
  final bool showOverlay;
  final bool showConfidence;
  final int targetInferenceFps;
  final bool showFps;
  final bool showInferenceTime;
  final bool requireHardhat;
  final bool requireVest;
  final int confirmFrames;

  AppSettings copyWith({
    double? confidenceThreshold,
    bool? showOverlay,
    bool? showConfidence,
    int? targetInferenceFps,
    bool? showFps,
    bool? showInferenceTime,
    bool? requireHardhat,
    bool? requireVest,
    int? confirmFrames,
  }) {
    return AppSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      showOverlay: showOverlay ?? this.showOverlay,
      showConfidence: showConfidence ?? this.showConfidence,
      targetInferenceFps: targetInferenceFps ?? this.targetInferenceFps,
      showFps: showFps ?? this.showFps,
      showInferenceTime: showInferenceTime ?? this.showInferenceTime,
      requireHardhat: requireHardhat ?? this.requireHardhat,
      requireVest: requireVest ?? this.requireVest,
      confirmFrames: confirmFrames ?? this.confirmFrames,
    );
  }
}
