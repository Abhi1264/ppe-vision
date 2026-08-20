import 'package:flutter/material.dart';

import '../app/theme.dart';

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
    final color = active ? AppColors.compliant : AppColors.muted;
    return Semantics(
      liveRegion: true,
      label: label ?? (active ? 'Detection active' : 'Detection idle'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label ?? (active ? 'Detection active' : 'Detection idle'),
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
