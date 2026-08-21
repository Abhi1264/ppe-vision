import 'dart:convert';

import 'compliance_statistics.dart';

class DetectionHistoryEntry {
  const DetectionHistoryEntry({
    required this.timestamp,
    required this.statistics,
  });

  final DateTime timestamp;
  final ComplianceStatistics statistics;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'statistics': statistics.toJson(),
  };

  factory DetectionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final timestampRaw = json['timestamp'];
    final timestamp = timestampRaw is String
        ? DateTime.tryParse(timestampRaw) ??
              DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);
    final statsRaw = json['statistics'];
    final statistics = statsRaw is Map
        ? ComplianceStatistics.fromJson(Map<String, dynamic>.from(statsRaw))
        : ComplianceStatistics.empty;
    return DetectionHistoryEntry(timestamp: timestamp, statistics: statistics);
  }

  static String encodeList(List<DetectionHistoryEntry> entries) {
    return jsonEncode([for (final entry in entries) entry.toJson()]);
  }

  static List<DetectionHistoryEntry> decodeList(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            DetectionHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }
}
