import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../models/compliance_result.dart';

class ComplianceCard extends StatelessWidget {
  const ComplianceCard({super.key, required this.result});

  final ComplianceResult result;

  @override
  Widget build(BuildContext context) {
    final color = switch ((result.hasPeople, result.isFullyCompliant)) {
      (false, _) => AppColors.muted,
      (true, true) => AppColors.compliant,
      (true, false) => AppColors.violation,
    };
    final icon = switch ((result.hasPeople, result.isFullyCompliant)) {
      (false, _) => Icons.visibility_outlined,
      (true, true) => Icons.check_rounded,
      (true, false) => Icons.priority_high_rounded,
    };

    return Semantics(
      label: '${result.headline}. ${result.detail}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.headline,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      result.detail,
                      style: const TextStyle(
                        color: AppColors.hudText,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
