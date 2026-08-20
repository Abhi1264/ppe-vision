import 'person_detection.dart';

class ComplianceStatistics {
  const ComplianceStatistics({
    required this.peopleCount,
    required this.helmetCount,
    required this.vestCount,
    required this.compliantCount,
    required this.violationCount,
  });

  static const empty = ComplianceStatistics(
    peopleCount: 0,
    helmetCount: 0,
    vestCount: 0,
    compliantCount: 0,
    violationCount: 0,
  );

  factory ComplianceStatistics.fromPeople(List<PersonDetection> people) {
    var helmets = 0;
    var vests = 0;
    var compliant = 0;
    for (final person in people) {
      if (person.hasHelmet) helmets += 1;
      if (person.hasVest) vests += 1;
      if (person.isCompliant) compliant += 1;
    }
    return ComplianceStatistics(
      peopleCount: people.length,
      helmetCount: helmets,
      vestCount: vests,
      compliantCount: compliant,
      violationCount: people.length - compliant,
    );
  }

  final int peopleCount;
  final int helmetCount;
  final int vestCount;
  final int compliantCount;
  final int violationCount;
}
