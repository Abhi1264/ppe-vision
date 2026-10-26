import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../models/site_log.dart';
import '../providers/event_log_provider.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(eventLogProvider);
    final rate = log.complianceRate == null
        ? 'Not yet'
        : '${log.compliantFrames}/${log.personFrames}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
        actions: [
          IconButton(
            tooltip: 'Copy report',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _text(log)));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied report')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              _Metric(label: 'Events', value: '${log.events.length}'),
              const SizedBox(width: AppSpacing.sm),
              _Metric(label: 'Compliance', value: rate),
            ],
          ),
          if (log.complianceRate == null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Compliance needs a person in the camera view.',
              style: TextStyle(color: AppColors.body),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _Section(title: 'By type', rows: log.counts((event) => event.type)),
          _Section(title: 'By day', rows: log.counts((event) => _day(event.at))),
          _Section(title: 'By camera', rows: log.counts((event) => event.camera)),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'This log counts missing gear in the camera view. It does not identify a person.',
            style: TextStyle(color: AppColors.body),
          ),
        ],
      ),
    );
  }
}

String _text(SiteLog log) {
  final rate = log.complianceRate == null
      ? 'not yet'
      : '${log.compliantFrames}/${log.personFrames}';
  return 'Events: ${log.events.length}\nCompliance: $rate\n${log.toCsv()}';
}

String _day(DateTime at) {
  final local = at.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadii.xxl),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.steel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final Map<String, int> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            const Text('None', style: TextStyle(color: AppColors.body))
          else
            for (final entry in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key} · ${entry.value}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
