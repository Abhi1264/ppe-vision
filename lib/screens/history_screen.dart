import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../models/detection_history_entry.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(historyProvider);
    final groups = _group(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
      ),
      body: entries.isEmpty
          ? const _EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _DayGroup(title: group.$1, entries: group.$2);
              },
            ),
    );
  }

  List<(String, List<DetectionHistoryEntry>)> _group(
    List<DetectionHistoryEntry> entries,
  ) {
    final map = <String, List<DetectionHistoryEntry>>{};
    for (final entry in entries) {
      map.putIfAbsent(_dayLabel(entry.timestamp), () => []).add(entry);
    }
    return [for (final key in map.keys) (key, map[key]!)];
  }

  String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.title, required this.entries});

  final String title;
  final List<DetectionHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          for (final entry in entries) _HistoryTile(entry: entry),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final DetectionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final stats = entry.statistics;
    final time =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
    final violationLabel =
        '${stats.violationCount} violation${stats.violationCount == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DCE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.peopleCount} people',
            style: const TextStyle(
              color: AppColors.steel,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${stats.compliantCount} compliant  ·  $violationLabel',
            style: const TextStyle(color: Color(0xFF5A646E), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Helmets ${stats.helmetCount}/${stats.peopleCount}   Vests ${stats.vestCount}/${stats.peopleCount}',
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 36, color: AppColors.muted),
            SizedBox(height: 12),
            Text(
              'No captures yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Use Capture on the detection screen to save a snapshot of the current compliance counts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5A646E), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
