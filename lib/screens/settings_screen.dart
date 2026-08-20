import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/detection_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionTitle('Detection'),
          _Card(
            children: [
              _SliderTile(
                label: 'Confidence threshold',
                valueLabel: settings.confidenceThreshold.toStringAsFixed(2),
                value: settings.confidenceThreshold,
                min: DetectionConstants.minConfidenceThreshold,
                max: DetectionConstants.maxConfidenceThreshold,
                onChanged: notifier.setConfidenceThreshold,
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Detection provider',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              RadioGroup<DetectionBackend>(
                groupValue: settings.backend,
                onChanged: (value) {
                  if (value != null) notifier.setBackend(value);
                },
                child: Column(
                  children: [
                    RadioListTile<DetectionBackend>(
                      value: DetectionBackend.mock,
                      title: const Text('Mock'),
                      subtitle: const Text('Functional demo detections'),
                    ),
                    RadioListTile<DetectionBackend>(
                      value: DetectionBackend.model,
                      enabled: false,
                      title: const Text('Model'),
                      subtitle: const Text(
                        'Not implemented — awaiting TFLite model',
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Enable detection overlay'),
                value: settings.showOverlay,
                onChanged: notifier.setShowOverlay,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Show confidence scores'),
                value: settings.showConfidence,
                onChanged: notifier.setShowConfidence,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Performance'),
          _Card(
            children: [
              _SliderTile(
                label: 'Target inference FPS',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Show FPS'),
                value: settings.showFps,
                onChanged: notifier.setShowFps,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Show inference time'),
                value: settings.showInferenceTime,
                onChanged: notifier.setShowInferenceTime,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle('About'),
          const _Card(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    SizedBox(height: 4),
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
                      style: TextStyle(color: Color(0xFF5A646E)),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5DCE3)),
      ),
      child: Column(children: children),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
