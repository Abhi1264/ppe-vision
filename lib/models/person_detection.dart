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

  List<String> get missingItems {
    return [
      if (!hasHelmet) 'helmet',
      if (!hasVest) 'vest',
    ];
  }

  String get missingSummary {
    if (missingItems.isEmpty) {
      return 'All required PPE detected';
    }
    if (missingItems.length == 1) {
      return 'Missing ${missingItems.first}';
    }
    return 'Missing ${missingItems.join(' and ')}';
  }
}
