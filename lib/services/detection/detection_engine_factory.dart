import '../../core/constants/app_constants.dart';
import 'detection_provider.dart';
import 'mock_detection_provider.dart';
import 'model_detection_provider.dart';

DetectionProvider createDetectionEngine(DetectionBackend backend) {
  return switch (backend) {
    DetectionBackend.mock => MockDetectionProvider(),
    DetectionBackend.model => ModelDetectionProvider(),
  };
}
