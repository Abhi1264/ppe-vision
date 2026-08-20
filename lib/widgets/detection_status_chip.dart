import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

class DetectionStatusChip extends StatelessWidget {
  const DetectionStatusChip({
    super.key,
    required this.active,
    this.label,
  });

  final bool active;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolved =
        label ??
        (active ? AppStrings.detectionActive : AppStrings.detectionIdle);
    final color = active ? AppColors.compliant : AppColors.muted;
    return Semantics(
      liveRegion: true,
      label: resolved,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            resolved,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
