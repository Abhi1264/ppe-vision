import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/models/compliance_result.dart';
import 'package:ppe_vision/models/compliance_statistics.dart';
import 'package:ppe_vision/models/detection.dart';
import 'package:ppe_vision/models/person_detection.dart';

PersonDetection _person({required bool helmet, required bool vest}) {
  const body = Detection(
    classType: DetectionClass.person,
    label: 'person',
    confidence: 0.9,
    x1: 0.1,
    y1: 0.1,
    x2: 0.4,
    y2: 0.9,
  );
  return PersonDetection(
    person: body,
    helmet: helmet
        ? const Detection(
            classType: DetectionClass.helmet,
            label: 'helmet',
            confidence: 0.9,
            x1: 0.15,
            y1: 0.1,
            x2: 0.3,
            y2: 0.25,
          )
        : null,
    vest: vest
        ? const Detection(
            classType: DetectionClass.vest,
            label: 'vest',
            confidence: 0.9,
            x1: 0.15,
            y1: 0.35,
            x2: 0.35,
            y2: 0.65,
          )
        : null,
  );
}

void main() {
  test('statistics are derived from people, not hardcoded', () {
    final people = [
      _person(helmet: true, vest: true),
      _person(helmet: true, vest: false),
      _person(helmet: false, vest: true),
    ];
    final stats = ComplianceStatistics.fromPeople(people);
    expect(stats.peopleCount, 3);
    expect(stats.helmetCount, 2);
    expect(stats.vestCount, 2);
    expect(stats.compliantCount, 1);
    expect(stats.violationCount, 2);
  });

  test('empty frame has zero counts', () {
    expect(ComplianceStatistics.fromPeople(const []).peopleCount, 0);
    expect(ComplianceStatistics.empty.violationCount, 0);
  });

  test('status copy distinguishes compliant and multi-person violations', () {
    final compliant = ComplianceResult.fromPeople([
      _person(helmet: true, vest: true),
    ]);
    expect(compliant.headline, 'PPE COMPLIANT');
    expect(compliant.detail, 'All required PPE detected');

    final mixed = ComplianceResult.fromPeople([
      _person(helmet: true, vest: true),
      _person(helmet: true, vest: false),
      _person(helmet: false, vest: true),
    ]);
    expect(mixed.headline, '2 PPE VIOLATIONS');
    expect(mixed.detail, '2 PPE violations detected');
  });
}
