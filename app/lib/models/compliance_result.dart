import '../core/constants/app_constants.dart';
import 'compliance_statistics.dart';
import 'person_detection.dart';

class ComplianceResult {
  const ComplianceResult({
    required this.people,
    required this.statistics,
  });

  static const empty = ComplianceResult(
    people: [],
    statistics: ComplianceStatistics.empty,
  );

  factory ComplianceResult.fromPeople(List<PersonDetection> people) {
    return ComplianceResult(
      people: people,
      statistics: ComplianceStatistics.fromPeople(people),
    );
  }

  final List<PersonDetection> people;
  final ComplianceStatistics statistics;

  bool get hasPeople => statistics.peopleCount > 0;
  bool get isFullyCompliant => hasPeople && statistics.violationCount == 0;

  String get headline {
    if (!hasPeople) return AppStrings.noPeopleHeadline;
    if (isFullyCompliant) return AppStrings.compliantHeadline;
    if (statistics.peopleCount == 1) return AppStrings.violationHeadline;
    final count = statistics.violationCount;
    return '$count PPE VIOLATION${count == 1 ? '' : 'S'}';
  }

  String get detail {
    if (!hasPeople) return AppStrings.waitingForPerson;
    if (isFullyCompliant) {
      return statistics.peopleCount == 1
          ? AppStrings.allPpeDetected
          : AppStrings.allPeopleCompliant;
    }
    if (statistics.peopleCount == 1) return people.first.missingSummary;
    final count = statistics.violationCount;
    return '$count PPE violation${count == 1 ? '' : 's'} detected';
  }
}
