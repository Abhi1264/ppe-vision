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
          const SectionTitle('Server'),
          SettingsCard(
            children: [
              ServerUrlField(
                url: settings.serverUrl,
                onSubmit: notifier.setServerUrl,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                title: const Text('Require hardhat'),
                value: settings.requireHardhat,
                onChanged: notifier.setRequireHardhat,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                title: const Text('Require vest'),
                value: settings.requireVest,
                onChanged: notifier.setRequireVest,
              ),
              SliderTile(
                label: 'Frames before an event',
                valueLabel: '${settings.confirmFrames}',
                value: settings.confirmFrames.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (value) => notifier.setConfirmFrames(value.round()),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                title: const Text('Use this device camera'),
                subtitle: const Text('Off uses the server webcam.'),
                value: settings.useDeviceCamera,
                onChanged: notifier.setUseDeviceCamera,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
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

class ServerUrlField extends StatefulWidget {
  const ServerUrlField({super.key, required this.url, required this.onSubmit});

  final String url;
  final ValueChanged<String> onSubmit;

  @override
  State<ServerUrlField> createState() => _ServerUrlFieldState();
}

class _ServerUrlFieldState extends State<ServerUrlField> {
  late final TextEditingController _controller = TextEditingController(text: widget.url);

  @override
  void didUpdateWidget(ServerUrlField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _controller.text == oldWidget.url) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Server URL'),
        onSubmitted: widget.onSubmit,
        onEditingComplete: () => widget.onSubmit(_controller.text),
      ),
    );
  }
}
