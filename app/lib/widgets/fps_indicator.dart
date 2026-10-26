import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

class FpsIndicator extends StatelessWidget {
  const FpsIndicator({
    super.key,
    required this.fps,
    required this.inferenceTime,
    required this.showFps,
    required this.showInferenceTime,
  });

  final double fps;
  final Duration inferenceTime;
  final bool showFps;
  final bool showInferenceTime;

  @override
  Widget build(BuildContext context) {
    if (!showFps && !showInferenceTime) return const SizedBox.shrink();

    final parts = <String>[
      if (showFps) 'FPS: ${fps.toStringAsFixed(1)}',
      if (showInferenceTime) 'Inference: ${inferenceTime.inMilliseconds} ms',
    ];

    return Semantics(
      label: parts.join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.fpsScrim,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            parts.join('   '),
            style: const TextStyle(
              color: AppColors.fpsText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
