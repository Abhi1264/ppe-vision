import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

class ModeBadge extends StatelessWidget {
  const ModeBadge({super.key, required this.label, this.expand = true});

  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.badgeFill,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.badgeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.badgeText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    if (!expand) return badge;
    return SizedBox(width: double.infinity, child: badge);
  }
}
