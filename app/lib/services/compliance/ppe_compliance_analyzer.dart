import '../../core/constants/detection_constants.dart';
import '../../core/utils/bounding_box_utils.dart';
import '../../models/detection.dart';
import '../../models/person_detection.dart';

/// This model's `person` class does not fire. Estimate a body box from each
/// helmet, and from a vest only when no helmet already covers it.
/// ponytail: drop this when a retrained model emits real person boxes.
List<Detection> detectionsWithPeople(List<Detection> detections) {
  if (detections.any((d) => d.classType == DetectionClass.person)) {
    return detections;
  }

  final helmets = detections.where((d) => d.classType == DetectionClass.helmet);
  final vests = detections.where((d) => d.classType == DetectionClass.vest);
  final people = <Detection>[
    for (final helmet in helmets) _bodyFromHelmet(helmet),
  ];
  for (final vest in vests) {
    final covered = people.any(
      (person) =>
          BoundingBoxUtils.centerInside(vest, person) ||
          BoundingBoxUtils.isInside(vest, person),
    );
    if (!covered) people.add(_bodyFromVest(vest));
  }
  if (people.isEmpty) return detections;
  return [...detections, ...people];
}

Detection _bodyFromHelmet(Detection helmet) {
  final width = helmet.width;
  final height = helmet.height;
  return Detection(
    classType: DetectionClass.person,
    label: 'person',
    confidence: helmet.confidence,
    x1: helmet.centerX - width * 1.2,
    y1: helmet.y1 - height * 0.15,
    x2: helmet.centerX + width * 1.2,
    y2: helmet.y2 + height * 5,
  ).clampNormalized();
}

Detection _bodyFromVest(Detection vest) {
  final width = vest.width;
  final height = vest.height;
  return Detection(
    classType: DetectionClass.person,
    label: 'person',
    confidence: vest.confidence,
    x1: vest.x1 - width * 0.1,
    y1: vest.y1 - height * 0.9,
    x2: vest.x2 + width * 0.1,
    y2: vest.y2,
  ).clampNormalized();
}

class PPEComplianceAnalyzer {
  const PPEComplianceAnalyzer();

  List<PersonDetection> analyze(List<Detection> detections) {
    final people = detections
        .where((d) => d.classType == DetectionClass.person)
        .toList();
    final helmets = detections
        .where((d) => d.classType == DetectionClass.helmet)
        .toList();
    final vests = detections
        .where((d) => d.classType == DetectionClass.vest)
        .toList();

    final usedHelmets = <Detection>{};
    final usedVests = <Detection>{};

    return [
      for (final person in people)
        PersonDetection(
          person: person,
          helmet: _bestMatch(
            person: person,
            candidates: helmets,
            used: usedHelmets,
            minRelativeY: 0,
            maxRelativeY: DetectionConstants.helmetVerticalMax,
          ),
          vest: _bestMatch(
            person: person,
            candidates: vests,
            used: usedVests,
            minRelativeY: DetectionConstants.vestVerticalMin,
            maxRelativeY: DetectionConstants.vestVerticalMax,
          ),
        ),
    ];
  }

  Detection? _bestMatch({
    required Detection person,
    required List<Detection> candidates,
    required Set<Detection> used,
    required double minRelativeY,
    required double maxRelativeY,
  }) {
    Detection? best;
    var bestScore = 0.0;

    for (final candidate in candidates) {
      if (used.contains(candidate)) continue;
      if (!BoundingBoxUtils.centerInside(candidate, person) &&
          !BoundingBoxUtils.isInside(candidate, person)) {
        continue;
      }

      final relativeY = BoundingBoxUtils.relativeCenterY(candidate, person);
      if (relativeY < minRelativeY || relativeY > maxRelativeY) {
        continue;
      }

      final iou = BoundingBoxUtils.calculateIoU(candidate, person);
      final containment = BoundingBoxUtils.isInside(candidate, person) ? 0.5 : 0.0;
      final score = iou + containment;
      if (score < DetectionConstants.associationIouThreshold && containment == 0) {
        continue;
      }
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    if (best != null) {
      used.add(best);
    }
    return best;
  }
}
