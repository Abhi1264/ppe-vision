import '../core/constants/app_constants.dart';
import 'detection.dart';

class PersonDetection {
  const PersonDetection({
    required this.person,
    this.helmet,
    this.vest,
    this.countHelmet = true,
    this.countVest = true,
  });

  final Detection person;
  final Detection? helmet;
  final Detection? vest;
  final bool countHelmet;
  final bool countVest;

  bool get hasHelmet => helmet != null;
  bool get hasVest => vest != null;
  bool get isCompliant =>
      (!countHelmet || hasHelmet) && (!countVest || hasVest);

  List<String> get missingItems => [
    if (countHelmet && !hasHelmet) 'helmet',
    if (countVest && !hasVest) 'vest',
  ];

  String get missingSummary {
    final missing = missingItems;
    if (missing.isEmpty) return AppStrings.allPpeDetected;
    if (missing.length == 1) return 'Missing ${missing.first}';
    return 'Missing ${missing.join(' and ')}';
  }
}
