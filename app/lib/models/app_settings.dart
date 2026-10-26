import '../core/constants/detection_constants.dart';

class AppSettings {
  const AppSettings({
    required this.confidenceThreshold,
    required this.showOverlay,
    required this.showConfidence,
    required this.targetInferenceFps,
    required this.showFps,
    required this.showInferenceTime,
    required this.serverUrl,
    required this.requireHardhat,
    required this.requireVest,
    required this.confirmFrames,
    required this.useDeviceCamera,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      confidenceThreshold: DetectionConstants.defaultConfidenceThreshold,
      showOverlay: true,
      showConfidence: true,
      targetInferenceFps: DetectionConstants.defaultTargetFps,
      showFps: true,
      showInferenceTime: true,
      serverUrl: 'http://127.0.0.1:8000',
      requireHardhat: true,
      requireVest: true,
      confirmFrames: 8,
      useDeviceCamera: false,
    );
  }

  final double confidenceThreshold;
  final bool showOverlay;
  final bool showConfidence;
  final int targetInferenceFps;
  final bool showFps;
  final bool showInferenceTime;
  final String serverUrl;
  final bool requireHardhat;
  final bool requireVest;
  final int confirmFrames;
  final bool useDeviceCamera;

  String get requiredPpe {
    return [
      if (requireHardhat) 'hardhat',
      if (requireVest) 'vest',
    ].join(',');
  }

  AppSettings copyWith({
    double? confidenceThreshold,
    bool? showOverlay,
    bool? showConfidence,
    int? targetInferenceFps,
    bool? showFps,
    bool? showInferenceTime,
    String? serverUrl,
    bool? requireHardhat,
    bool? requireVest,
    int? confirmFrames,
    bool? useDeviceCamera,
  }) {
    return AppSettings(
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      showOverlay: showOverlay ?? this.showOverlay,
      showConfidence: showConfidence ?? this.showConfidence,
      targetInferenceFps: targetInferenceFps ?? this.targetInferenceFps,
      showFps: showFps ?? this.showFps,
      showInferenceTime: showInferenceTime ?? this.showInferenceTime,
      serverUrl: serverUrl ?? this.serverUrl,
      requireHardhat: requireHardhat ?? this.requireHardhat,
      requireVest: requireVest ?? this.requireVest,
      confirmFrames: confirmFrames ?? this.confirmFrames,
      useDeviceCamera: useDeviceCamera ?? this.useDeviceCamera,
    );
  }
}
