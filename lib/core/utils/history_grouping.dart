import '../../models/detection_history_entry.dart';
import '../constants/app_constants.dart';

typedef HistoryDayGroup = ({
  String title,
  List<DetectionHistoryEntry> entries,
});

abstract final class HistoryGrouping {
  static List<HistoryDayGroup> groupByDay(
    List<DetectionHistoryEntry> entries, {
    DateTime? now,
  }) {
    final map = <String, List<DetectionHistoryEntry>>{};
    for (final entry in entries) {
      map.putIfAbsent(dayLabel(entry.timestamp, now: now), () => []).add(entry);
    }
    return [
      for (final entry in map.entries)
        (title: entry.key, entries: entry.value),
    ];
  }

  static String dayLabel(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final day = DateTime(time.year, time.month, time.day);
    final today = DateTime(current.year, current.month, current.day);
    if (day == today) return AppStrings.today;
    if (day == today.subtract(const Duration(days: 1))) {
      return AppStrings.yesterday;
    }
    final month = time.month.toString().padLeft(2, '0');
    final date = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$date';
  }

  static String clock(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
