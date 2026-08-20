import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/compliance_result.dart';

class ComplianceCard extends StatelessWidget {
  const ComplianceCard({super.key, required this.result});

  final ComplianceResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isFullyCompliant;
    final idle = !result.hasPeople;
    final color = idle
        ? AppColors.muted
        : (ok ? AppColors.compliant : AppColors.violation);
    final icon = idle
        ? Icons.visibility_outlined
        : (ok ? Icons.check_rounded : Icons.priority_high_rounded);

    return Semantics(
      label: '${result.headline}. ${result.detail}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    result.detail,
                    style: const TextStyle(
                      color: Color(0xFFE4E9EE),
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
    );
  }
}
