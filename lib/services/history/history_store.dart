import 'package:shared_preferences/shared_preferences.dart';

import '../../models/detection_history_entry.dart';

abstract class HistoryStore {
  Future<List<DetectionHistoryEntry>> load();
  Future<void> save(List<DetectionHistoryEntry> entries);
}

class MemoryHistoryStore implements HistoryStore {
  MemoryHistoryStore([List<DetectionHistoryEntry> seed = const []])
    : _entries = List<DetectionHistoryEntry>.from(seed);

  List<DetectionHistoryEntry> _entries;

  @override
  Future<List<DetectionHistoryEntry>> load() async =>
      List<DetectionHistoryEntry>.from(_entries);

  @override
  Future<void> save(List<DetectionHistoryEntry> entries) async {
    _entries = List<DetectionHistoryEntry>.from(entries);
  }
}

class SharedPreferencesHistoryStore implements HistoryStore {
  SharedPreferencesHistoryStore({this._prefs});

  static const storageKey = 'ppe_vision.detection_history';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<DetectionHistoryEntry>> load() async {
    final prefs = await _instance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    return DetectionHistoryEntry.decodeList(raw);
  }

  @override
  Future<void> save(List<DetectionHistoryEntry> entries) async {
    final prefs = await _instance();
    await prefs.setString(
      storageKey,
      DetectionHistoryEntry.encodeList(entries),
    );
  }
}
