import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/detection_constants.dart';
import '../models/app_settings.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _hardhatKey = 'requireHardhat';
  static const _vestKey = 'requireVest';
  static const _framesKey = 'confirmFrames';

  @override
  AppSettings build() {
    Future<void>(() async {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted) return;
      final frames = prefs.getInt(_framesKey) ?? 8;
      state = AppSettings.defaults().copyWith(
        requireHardhat: prefs.getBool(_hardhatKey) ?? true,
        requireVest: prefs.getBool(_vestKey) ?? true,
        confirmFrames: frames.clamp(1, 30),
      );
    });
    return AppSettings.defaults();
  }

  void setConfidenceThreshold(double value) {
    state = state.copyWith(
      confidenceThreshold: value.clamp(
        DetectionConstants.minConfidenceThreshold,
        DetectionConstants.maxConfidenceThreshold,
      ),
    );
  }

  void setShowOverlay(bool value) => state = state.copyWith(showOverlay: value);

  void setShowConfidence(bool value) =>
      state = state.copyWith(showConfidence: value);

  void setTargetInferenceFps(int value) {
    state = state.copyWith(
      targetInferenceFps: value.clamp(
        DetectionConstants.minTargetFps,
        DetectionConstants.maxTargetFps,
      ),
    );
  }

  void setShowFps(bool value) => state = state.copyWith(showFps: value);

  void setShowInferenceTime(bool value) =>
      state = state.copyWith(showInferenceTime: value);

  void setRequireHardhat(bool value) {
    if (!value && !state.requireVest) return;
    state = state.copyWith(requireHardhat: value);
    _save();
  }

  void setRequireVest(bool value) {
    if (!value && !state.requireHardhat) return;
    state = state.copyWith(requireVest: value);
    _save();
  }

  void setConfirmFrames(int value) {
    state = state.copyWith(confirmFrames: value.clamp(1, 30));
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hardhatKey, state.requireHardhat);
    await prefs.setBool(_vestKey, state.requireVest);
    await prefs.setInt(_framesKey, state.confirmFrames);
  }
}
