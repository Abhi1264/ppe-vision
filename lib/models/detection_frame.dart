import 'detection.dart';

class DetectionFrame {
  const DetectionFrame({
    required this.detections,
    required this.timestamp,
    required this.inferenceTime,
  });

  final List<Detection> detections;
  final DateTime timestamp;
  final Duration inferenceTime;
}
