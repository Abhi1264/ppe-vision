import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/detection_constants.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_controls.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.screen,
        ),
        children: [
          const SectionTitle(AppStrings.detectionSection),
          SettingsCard(
            children: [
              SliderTile(
                label: AppStrings.confidenceThreshold,
                valueLabel: settings.confidenceThreshold.toStringAsFixed(2),
                value: settings.confidenceThreshold,
                min: DetectionConstants.minConfidenceThreshold,
                max: DetectionConstants.maxConfidenceThreshold,
                onChanged: notifier.setConfidenceThreshold,
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  14,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  AppStrings.detectionProvider,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              RadioGroup<DetectionBackend>(
                groupValue: settings.backend,
                onChanged: (value) {
                  if (value == null) return;
                  notifier.setBackend(value);
                },
                child: const Column(
                  children: [
                    RadioListTile<DetectionBackend>(
                      value: DetectionBackend.mock,
                      title: Text(AppStrings.providerMock),
                      subtitle: Text(AppStrings.providerMockSubtitle),
                    ),
                    RadioListTile<DetectionBackend>(
                      value: DetectionBackend.model,
                      enabled: false,
                      title: Text(AppStrings.providerModel),
                      subtitle: Text(AppStrings.providerModelSubtitle),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: const Text(AppStrings.enableOverlay),
                value: settings.showOverlay,
                onChanged: notifier.setShowOverlay,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: const Text(AppStrings.showConfidence),
                value: settings.showConfidence,
                onChanged: notifier.setShowConfidence,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(AppStrings.performanceSection),
          SettingsCard(
            children: [
              SliderTile(
                label: AppStrings.targetInferenceFps,
                valueLabel: '${settings.targetInferenceFps}',
                value: settings.targetInferenceFps.toDouble(),
                min: DetectionConstants.minTargetFps.toDouble(),
                max: DetectionConstants.maxTargetFps.toDouble(),
                divisions:
                    DetectionConstants.maxTargetFps -
                    DetectionConstants.minTargetFps,
                onChanged: (value) =>
                    notifier.setTargetInferenceFps(value.round()),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: const Text(AppStrings.showFps),
                value: settings.showFps,
                onChanged: notifier.setShowFps,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: const Text(AppStrings.showInferenceTime),
                value: settings.showInferenceTime,
                onChanged: notifier.setShowInferenceTime,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(AppStrings.aboutSection),
          const SettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      AppConstants.appSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.steel,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppConstants.aboutBlurb,
                      style: TextStyle(color: AppColors.bodySecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
