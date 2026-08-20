import 'compliance_statistics.dart';
import 'person_detection.dart';

class ComplianceResult {
  const ComplianceResult({
    required this.people,
    required this.statistics,
  });

  factory ComplianceResult.fromPeople(List<PersonDetection> people) {
    return ComplianceResult(
      people: people,
      statistics: ComplianceStatistics.fromPeople(people),
    );
  }

  final List<PersonDetection> people;
  final ComplianceStatistics statistics;

  bool get hasPeople => statistics.peopleCount > 0;
  bool get isFullyCompliant =>
      hasPeople && statistics.violationCount == 0;

  String get headline {
    if (!hasPeople) {
      return 'NO PEOPLE DETECTED';
    }
    if (isFullyCompliant) {
      return 'PPE COMPLIANT';
    }
    if (statistics.peopleCount == 1) {
      return 'PPE VIOLATION';
    }
    return '${statistics.violationCount} PPE VIOLATION${statistics.violationCount == 1 ? '' : 'S'}';
  }

  String get detail {
    if (!hasPeople) {
      return 'Waiting for a person in frame';
    }
    if (isFullyCompliant) {
      if (statistics.peopleCount == 1) {
        return 'All required PPE detected';
      }
      return 'All detected people are wearing required PPE';
    }
    if (statistics.peopleCount == 1) {
      return people.first.missingSummary;
    }
    return '${statistics.violationCount} PPE violation${statistics.violationCount == 1 ? '' : 's'} detected';
  }
}
