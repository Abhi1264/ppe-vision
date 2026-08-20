import 'compliance_statistics.dart';

class DetectionHistoryEntry {
  const DetectionHistoryEntry({
    required this.timestamp,
    required this.statistics,
  });

  final DateTime timestamp;
  final ComplianceStatistics statistics;
}
