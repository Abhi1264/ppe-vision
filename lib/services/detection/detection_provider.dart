import '../../models/detection.dart';
import '../../models/frame_data.dart';

abstract class DetectionProvider {
  Future<void> initialize();
  Future<List<Detection>> detect(FrameData frame);
  Future<void> dispose();
  bool get isReady;
}
