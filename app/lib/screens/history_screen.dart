import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/history_grouping.dart';
import '../models/detection_history_entry.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    if (!history.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.detectionHistory)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entries = history.entries;
    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.detectionHistory)),
        body: const EmptyHistory(),
      );
    }

    final groups = HistoryGrouping.groupByDay(entries);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.detectionHistory)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return HistoryDayGroupView(
            title: group.title,
            entries: group.entries,
          );
        },
      ),
    );
  }
}

class HistoryDayGroupView extends StatelessWidget {
  const HistoryDayGroupView({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<DetectionHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries) HistoryTile(entry: entry),
        ],
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry});

  final DetectionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final stats = entry.statistics;
    final violationLabel =
        '${stats.violationCount} violation${stats.violationCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            HistoryGrouping.clock(entry.timestamp),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${stats.peopleCount} people',
            style: const TextStyle(
              color: AppColors.steel,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${stats.compliantCount} compliant  ·  $violationLabel',
            style: const TextStyle(
              color: AppColors.bodySecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppStrings.helmets} ${stats.helmetCount}/${stats.peopleCount}   ${AppStrings.vests} ${stats.vestCount}/${stats.peopleCount}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 36, color: AppColors.muted),
            SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.emptyHistoryTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              AppStrings.emptyHistoryBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.bodySecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
