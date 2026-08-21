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

  factory ComplianceStatistics.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return ComplianceStatistics(
      peopleCount: read('peopleCount'),
      helmetCount: read('helmetCount'),
      vestCount: read('vestCount'),
      compliantCount: read('compliantCount'),
      violationCount: read('violationCount'),
    );
  }

  final int peopleCount;
  final int helmetCount;
  final int vestCount;
  final int compliantCount;
  final int violationCount;

  Map<String, int> toJson() => {
    'peopleCount': peopleCount,
    'helmetCount': helmetCount,
    'vestCount': vestCount,
    'compliantCount': compliantCount,
    'violationCount': violationCount,
  };
}
