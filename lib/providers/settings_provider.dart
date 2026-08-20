import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/detection_constants.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.defaults();

  void setConfidenceThreshold(double value) {
    state = state.copyWith(
      confidenceThreshold: value.clamp(
        DetectionConstants.minConfidenceThreshold,
        DetectionConstants.maxConfidenceThreshold,
      ),
    );
  }

  void setBackend(DetectionBackend backend) {
    if (backend == DetectionBackend.model) return;
    state = state.copyWith(backend: backend);
  }

  void setShowOverlay(bool value) {
    state = state.copyWith(showOverlay: value);
  }

  void setShowConfidence(bool value) {
    state = state.copyWith(showConfidence: value);
  }

  void setTargetInferenceFps(int value) {
    state = state.copyWith(
      targetInferenceFps: value.clamp(
        DetectionConstants.minTargetFps,
        DetectionConstants.maxTargetFps,
      ),
    );
  }

  void setShowFps(bool value) {
    state = state.copyWith(showFps: value);
  }

  void setShowInferenceTime(bool value) {
    state = state.copyWith(showInferenceTime: value);
  }
}
