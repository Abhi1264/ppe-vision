import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../models/compliance_statistics.dart';

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key, required this.statistics});

  final ComplianceStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: AppStrings.people, value: '${statistics.peopleCount}'),
        _Stat(
          label: AppStrings.helmets,
          value: '${statistics.helmetCount} / ${statistics.peopleCount}',
        ),
        _Stat(
          label: AppStrings.vests,
          value: '${statistics.vestCount} / ${statistics.peopleCount}',
        ),
        _Stat(
          label: AppStrings.compliant,
          value: '${statistics.compliantCount}',
          color: AppColors.compliant,
        ),
        _Stat(
          label: AppStrings.violations,
          value: '${statistics.violationCount}',
          color: statistics.violationCount > 0
              ? AppColors.violation
              : AppColors.muted,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.statValue,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.statLabel,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
