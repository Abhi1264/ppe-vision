import 'package:flutter_test/flutter_test.dart';

import 'package:ppe_vision/mock/mock_data.dart';
import 'package:ppe_vision/models/detection.dart';
import 'package:ppe_vision/services/compliance/ppe_compliance_analyzer.dart';

Detection person({
  required double x1,
  required double y1,
  required double x2,
  required double y2,
}) {
  return Detection(
    classType: DetectionClass.person,
    label: 'person',
    confidence: 0.95,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
  );
}

Detection helmet(double x1, double y1, double x2, double y2) {
  return Detection(
    classType: DetectionClass.helmet,
    label: 'helmet',
    confidence: 0.9,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
  );
}

Detection vest(double x1, double y1, double x2, double y2) {
  return Detection(
    classType: DetectionClass.vest,
    label: 'vest',
    confidence: 0.9,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
  );
}

void main() {
  const analyzer = PPEComplianceAnalyzer();

  test('fully compliant person with helmet and vest', () {
    final people = analyzer.analyze([
      person(x1: 0.1, y1: 0.1, x2: 0.5, y2: 0.9),
      helmet(0.2, 0.1, 0.4, 0.28),
      vest(0.18, 0.35, 0.42, 0.7),
    ]);
    expect(people, hasLength(1));
    expect(people.first.hasHelmet, isTrue);
    expect(people.first.hasVest, isTrue);
    expect(people.first.isCompliant, isTrue);
    expect(people.first.missingItems, isEmpty);
  });

  test('missing helmet is a violation', () {
    final people = analyzer.analyze([
      person(x1: 0.1, y1: 0.1, x2: 0.5, y2: 0.9),
      vest(0.18, 0.35, 0.42, 0.7),
    ]);
    expect(people.first.isCompliant, isFalse);
    expect(people.first.hasVest, isTrue);
    expect(people.first.hasHelmet, isFalse);
    expect(people.first.missingItems, ['helmet']);
  });

  test('missing vest is a violation', () {
    final people = analyzer.analyze([
      person(x1: 0.1, y1: 0.1, x2: 0.5, y2: 0.9),
      helmet(0.2, 0.1, 0.4, 0.28),
    ]);
    expect(people.first.isCompliant, isFalse);
    expect(people.first.hasHelmet, isTrue);
    expect(people.first.hasVest, isFalse);
    expect(people.first.missingItems, ['vest']);
  });

  test('no PPE is a violation of helmet and vest', () {
    final people = analyzer.analyze([
      person(x1: 0.1, y1: 0.1, x2: 0.5, y2: 0.9),
    ]);
    expect(people.first.isCompliant, isFalse);
    expect(people.first.missingItems, ['helmet', 'vest']);
    expect(people.first.missingSummary, 'Missing helmet and vest');
  });

  test('multiple people keep helmets and vests associated locally', () {
    final left = person(x1: 0.0, y1: 0.1, x2: 0.4, y2: 0.9);
    final right = person(x1: 0.55, y1: 0.1, x2: 0.95, y2: 0.9);
    final people = analyzer.analyze([
      left,
      right,
      helmet(0.1, 0.1, 0.28, 0.28),
      vest(0.08, 0.35, 0.3, 0.68),
      helmet(0.68, 0.12, 0.84, 0.3),
    ]);

    expect(people, hasLength(2));
    expect(people[0].isCompliant, isTrue);
    expect(people[1].hasHelmet, isTrue);
    expect(people[1].hasVest, isFalse);
    expect(people[1].isCompliant, isFalse);
  });

  test('canonical mock scene has mixed compliance', () {
    final people = analyzer.analyze(MockData.scene());
    expect(people, hasLength(3));
    expect(people[0].isCompliant, isTrue);
    expect(people[1].hasHelmet, isTrue);
    expect(people[1].hasVest, isFalse);
    expect(people[2].hasHelmet, isFalse);
    expect(people[2].hasVest, isTrue);
  });
}
