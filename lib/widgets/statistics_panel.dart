import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/compliance_statistics.dart';

class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({super.key, required this.statistics});

  final ComplianceStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: 'People', value: '${statistics.peopleCount}'),
        _Stat(
          label: 'Helmets',
          value: '${statistics.helmetCount} / ${statistics.peopleCount}',
        ),
        _Stat(
          label: 'Vests',
          value: '${statistics.vestCount} / ${statistics.peopleCount}',
        ),
        _Stat(
          label: 'Compliant',
          value: '${statistics.compliantCount}',
          color: AppColors.compliant,
        ),
        _Stat(
          label: 'Violations',
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
              color: color ?? const Color(0xFFF2F5F7),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8B959E),
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
