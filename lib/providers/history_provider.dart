import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compliance_statistics.dart';
import '../models/detection_history_entry.dart';

final historyProvider =
    NotifierProvider<HistoryNotifier, List<DetectionHistoryEntry>>(
      HistoryNotifier.new,
    );

class HistoryNotifier extends Notifier<List<DetectionHistoryEntry>> {
  @override
  List<DetectionHistoryEntry> build() => const [];

  void addCapture(ComplianceStatistics statistics, {DateTime? timestamp}) {
    state = [
      DetectionHistoryEntry(
        timestamp: timestamp ?? DateTime.now(),
        statistics: statistics,
      ),
      ...state,
    ];
  }

  void clear() {
    state = const [];
  }
}
