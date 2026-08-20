import '../../core/errors/app_exception.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import 'detection_provider.dart';

class ModelDetectionProvider implements DetectionProvider {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    // TODO: load TFLite model, labels, interpreter, tensors.
    throw const ModelUnavailableException();
  }

  @override
  Future<List<Detection>> detect(FrameData frame) async {
    // TODO: RGB convert, letterbox, infer, decode YOLO, NMS, normalize boxes.
    throw UnimplementedError(
      'ModelDetectionProvider is not implemented. Use Mock until ppe_model.tflite is supplied.',
    );
  }

  @override
  Future<void> dispose() async {
    // TODO: close interpreter.
    _ready = false;
  }
}
