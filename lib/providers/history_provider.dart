import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/compliance_statistics.dart';
import '../models/detection_history_entry.dart';
import '../services/history/history_store.dart';

final historyStoreProvider = Provider<HistoryStore>((ref) {
  return SharedPreferencesHistoryStore();
});

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);

class HistoryState {
  const HistoryState({this.entries = const [], this.isLoaded = false});

  final List<DetectionHistoryEntry> entries;
  final bool isLoaded;
}

class HistoryNotifier extends Notifier<HistoryState> {
  late Future<void> _loadFuture;
  Future<void> _saveFuture = Future.value();

  @override
  HistoryState build() {
    _loadFuture = _hydrate();
    return const HistoryState();
  }

  Future<void> get ready async {
    await _loadFuture;
    await _saveFuture;
  }

  Future<void> addCapture(
    ComplianceStatistics statistics, {
    DateTime? timestamp,
  }) async {
    await _loadFuture;
    state = HistoryState(
      isLoaded: true,
      entries: [
        DetectionHistoryEntry(
          timestamp: timestamp ?? DateTime.now(),
          statistics: statistics,
        ),
        ...state.entries,
      ],
    );
    await _persist();
  }

  Future<void> clear() async {
    await _loadFuture;
    state = const HistoryState(isLoaded: true);
    await _persist();
  }

  Future<void> _hydrate() async {
    try {
      final entries = await ref.read(historyStoreProvider).load();
      state = HistoryState(entries: entries, isLoaded: true);
    } catch (_) {
      state = const HistoryState(isLoaded: true);
    }
  }

  Future<void> _persist() async {
    final snapshot = state.entries;
    _saveFuture = _write(snapshot);
    await _saveFuture;
  }

  Future<void> _write(List<DetectionHistoryEntry> snapshot) async {
    try {
      await ref.read(historyStoreProvider).save(snapshot);
    } catch (_) {
      // Keep the in-memory capture even if disk write fails.
    }
  }
}
