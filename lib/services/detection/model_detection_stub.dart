import '../../core/errors/app_exception.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import 'detection_provider.dart';

class ModelDetectionProvider implements DetectionProvider {
  @override
  bool get isReady => false;

  @override
  Future<void> initialize() async {
    throw const ModelUnavailableException(
      'The bundled model runs in the mobile and desktop app, not in the browser.',
    );
  }

  @override
  Future<List<Detection>> detect(FrameData frame) async {
    throw const ModelUnavailableException(
      'The bundled model runs in the mobile and desktop app, not in the browser.',
    );
  }

  @override
  Future<void> dispose() async {}
}
