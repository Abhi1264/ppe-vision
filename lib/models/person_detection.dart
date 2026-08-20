import '../core/constants/app_constants.dart';
import 'detection.dart';

class PersonDetection {
  const PersonDetection({
    required this.person,
    this.helmet,
    this.vest,
  });

  final Detection person;
  final Detection? helmet;
  final Detection? vest;

  bool get hasHelmet => helmet != null;
  bool get hasVest => vest != null;
  bool get isCompliant => hasHelmet && hasVest;

  List<String> get missingItems => [
    if (!hasHelmet) 'helmet',
    if (!hasVest) 'vest',
  ];

  String get missingSummary {
    final missing = missingItems;
    if (missing.isEmpty) return AppStrings.allPpeDetected;
    if (missing.length == 1) return 'Missing ${missing.first}';
    return 'Missing ${missing.join(' and ')}';
  }
}
