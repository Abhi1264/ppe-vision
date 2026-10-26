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
    return DetectionHistoryEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      statistics: ComplianceStatistics.fromJson(
        Map<String, dynamic>.from(json['statistics'] as Map),
      ),
    );
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
          DetectionHistoryEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}
