import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/models/compliance_statistics.dart';
import 'package:ppe_vision/models/detection_history_entry.dart';
import 'package:ppe_vision/providers/history_provider.dart';
import 'package:ppe_vision/services/history/history_store.dart';

const _stats = ComplianceStatistics(
  peopleCount: 3,
  helmetCount: 2,
  vestCount: 2,
  compliantCount: 1,
  violationCount: 2,
);

void main() {
  test('history JSON round-trips', () {
    final entry = DetectionHistoryEntry(
      timestamp: DateTime.utc(2026, 8, 21, 6, 30),
      statistics: _stats,
    );
    final restored = DetectionHistoryEntry.decodeList(
      DetectionHistoryEntry.encodeList([entry]),
    ).single;

    expect(restored.timestamp, entry.timestamp);
    expect(restored.statistics.peopleCount, 3);
    expect(restored.statistics.helmetCount, 2);
    expect(restored.statistics.vestCount, 2);
    expect(restored.statistics.compliantCount, 1);
    expect(restored.statistics.violationCount, 2);
  });

  test('corrupt history JSON is ignored', () {
    expect(DetectionHistoryEntry.decodeList('{not-json'), isEmpty);
  });

  test('captures survive a new HistoryNotifier using the same store', () async {
    final store = MemoryHistoryStore();
    final first = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(first.dispose);

    await first
        .read(historyProvider.notifier)
        .addCapture(_stats, timestamp: DateTime.utc(2026, 8, 21, 6, 30));
    expect(first.read(historyProvider).entries, hasLength(1));

    final second = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(second.dispose);

    await second.read(historyProvider.notifier).ready;
    final restored = second.read(historyProvider).entries.single;
    expect(restored.statistics.peopleCount, 3);
    expect(restored.timestamp, DateTime.utc(2026, 8, 21, 6, 30));
  });
}
