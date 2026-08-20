import '../../models/detection.dart';
import '../../models/frame_data.dart';

/// Replaceable detection backend. The UI and PPE logic depend on this
/// interface only — never on YOLO, TFLite, or tensor shapes.
abstract class DetectionProvider {
  Future<void> initialize();
  Future<List<Detection>> detect(FrameData frame);
  Future<void> dispose();
  bool get isReady;
}
