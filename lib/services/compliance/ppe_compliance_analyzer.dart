import '../../core/constants/detection_constants.dart';
import '../../core/utils/bounding_box_utils.dart';
import '../../models/detection.dart';
import '../../models/person_detection.dart';

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
