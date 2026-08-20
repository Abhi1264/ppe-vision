import 'dart:math';

import '../../core/constants/detection_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../mock/mock_data.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import 'detection_provider.dart';

class MockDetectionProvider implements DetectionProvider {
  MockDetectionProvider({Random? random}) : _random = random ?? Random();

  final Random _random;
  bool _ready = false;
  DateTime? _startedAt;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    _startedAt = DateTime.now();
    _ready = true;
  }

  @override
  Future<List<Detection>> detect(FrameData frame) async {
    if (!_ready) {
      throw const InferenceException('Mock detection provider is not initialized.');
    }
    if (frame.width <= 0 || frame.height <= 0) {
      throw const InvalidFrameException();
    }

    final jitterMs = _random.nextInt(
      DetectionConstants.mockInferenceJitter.inMilliseconds + 1,
    );
    await Future<void>.delayed(
      DetectionConstants.mockInferenceMin + Duration(milliseconds: jitterMs),
    );

    final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
    final phase = elapsed.inMilliseconds / 700;
    return MockData.scene(phase: phase);
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
