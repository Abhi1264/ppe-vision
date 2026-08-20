import '../../core/errors/app_exception.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import 'detection_provider.dart';

/// Stub for the future TFLite / YOLO backend.
///
/// Plug the exported model into `assets/models/ppe_model.tflite` and implement
/// the TODOs below. Downstream UI, overlays, PPE association, statistics,
/// history, and settings must not change.
class ModelDetectionProvider implements DetectionProvider {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    // TODO:
    // Load TFLite model.
    // Load labels.
    // Configure interpreter.
    // Allocate tensors.
    throw const ModelUnavailableException();
  }

  @override
  Future<List<Detection>> detect(FrameData frame) async {
    // TODO:
    // 1. Convert camera frame to RGB.
    // 2. Resize/letterbox to model input size.
    // 3. Normalize input.
    // 4. Run inference.
    // 5. Decode YOLO output.
    // 6. Apply confidence threshold.
    // 7. Apply NMS.
    // 8. Convert coordinates to normalized coordinates.
    // 9. Return Detection objects.
    throw UnimplementedError(
      'ModelDetectionProvider is not implemented. Use Mock until ppe_model.tflite is supplied.',
    );
  }

  @override
  Future<void> dispose() async {
    // TODO: Close the TFLite interpreter and release tensors.
    _ready = false;
  }
}
