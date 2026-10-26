import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/core/constants/app_constants.dart';
import 'package:ppe_vision/core/utils/history_grouping.dart';
import 'package:ppe_vision/models/compliance_statistics.dart';
import 'package:ppe_vision/models/detection_history_entry.dart';

void main() {
  const stats = ComplianceStatistics(
    peopleCount: 2,
    helmetCount: 2,
    vestCount: 1,
    compliantCount: 1,
    violationCount: 1,
  );

  test('groups entries by calendar day', () {
    final now = DateTime(2026, 8, 20, 12);
    final entries = [
      DetectionHistoryEntry(
        timestamp: DateTime(2026, 8, 20, 19, 32),
        statistics: stats,
      ),
      DetectionHistoryEntry(
        timestamp: DateTime(2026, 8, 19, 8),
        statistics: stats,
      ),
    ];

    final groups = HistoryGrouping.groupByDay(entries, now: now);
    expect(groups, hasLength(2));
    expect(groups.first.title, AppStrings.today);
    expect(groups.last.title, AppStrings.yesterday);
  });

  test('formats a 24-hour clock', () {
    expect(HistoryGrouping.clock(DateTime(2026, 1, 1, 9, 5)), '09:05');
  });
}
