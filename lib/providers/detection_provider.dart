import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/compliance_result.dart';
import '../models/compliance_statistics.dart';
import '../models/detection.dart';
import '../models/detection_frame.dart';
import '../models/frame_data.dart';
import '../services/camera/camera_service.dart';
import '../services/compliance/ppe_compliance_analyzer.dart';
import '../services/detection/detection_provider.dart' as engine;
import '../services/detection/mock_detection_provider.dart';
import '../services/detection/model_detection_provider.dart';
import 'camera_provider.dart';
import 'history_provider.dart';
import 'settings_provider.dart';

final detectionEngineProvider = Provider<engine.DetectionProvider>((ref) {
  final backend = ref.watch(settingsProvider.select((s) => s.backend));
  final provider = backend == DetectionBackend.mock
      ? MockDetectionProvider()
      : ModelDetectionProvider();
  ref.onDispose(provider.dispose);
  return provider;
});

enum CameraPhase { idle, initializing, ready, fallback, failed }

class DetectionSessionState {
  const DetectionSessionState({
    this.cameraPhase = CameraPhase.idle,
    this.isDetecting = false,
    this.latestFrame,
    this.compliance = const ComplianceResult(
      people: [],
      statistics: ComplianceStatistics.empty,
    ),
    this.fps = 0,
    this.errorMessage,
    this.statusMessage,
    this.capturedFlash = false,
  });

  final CameraPhase cameraPhase;
  final bool isDetecting;
  final DetectionFrame? latestFrame;
  final ComplianceResult compliance;
  final double fps;
  final String? errorMessage;
  final String? statusMessage;
  final bool capturedFlash;

  List<Detection> get detections => latestFrame?.detections ?? const [];
  Duration get inferenceTime =>
      latestFrame?.inferenceTime ?? Duration.zero;
  bool get usingFallbackPreview => cameraPhase == CameraPhase.fallback;

  DetectionSessionState copyWith({
    CameraPhase? cameraPhase,
    bool? isDetecting,
    DetectionFrame? latestFrame,
    ComplianceResult? compliance,
    double? fps,
    String? errorMessage,
    String? statusMessage,
    bool? capturedFlash,
    bool clearError = false,
    bool clearFrame = false,
  }) {
    return DetectionSessionState(
      cameraPhase: cameraPhase ?? this.cameraPhase,
      isDetecting: isDetecting ?? this.isDetecting,
      latestFrame: clearFrame ? null : (latestFrame ?? this.latestFrame),
      compliance: compliance ?? this.compliance,
      fps: fps ?? this.fps,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: statusMessage ?? this.statusMessage,
      capturedFlash: capturedFlash ?? this.capturedFlash,
    );
  }
}

final detectionSessionProvider =
    NotifierProvider<DetectionSessionNotifier, DetectionSessionState>(
      DetectionSessionNotifier.new,
    );

class DetectionSessionNotifier extends Notifier<DetectionSessionState>
    with WidgetsBindingObserver {
  static const _analyzer = PPEComplianceAnalyzer();

  bool _isProcessing = false;
  bool _started = false;
  bool _alive = true;
  int _generation = 0;
  DateTime? _lastInferenceStartedAt;
  DateTime? _lastInferenceCompletedAt;
  Timer? _fallbackTimer;
  Timer? _captureTimer;
  double _fps = 0;

  CameraService get _camera => ref.read(cameraServiceProvider);
  engine.DetectionProvider get _engine => ref.read(detectionEngineProvider);

  @override
  DetectionSessionState build() {
    final observer = this;
    WidgetsBinding.instance.addObserver(observer);
    _alive = true;
    ref.onDispose(() {
      _alive = false;
      WidgetsBinding.instance.removeObserver(observer);
      unawaited(_teardown());
    });
    return DetectionSessionState(
      compliance: ComplianceResult.fromPeople(const []),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_camera.pause());
        _fallbackTimer?.cancel();
      case AppLifecycleState.resumed:
        unawaited(_resume());
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final generation = ++_generation;
    state = state.copyWith(
      cameraPhase: CameraPhase.initializing,
      isDetecting: false,
      clearError: true,
      statusMessage: 'Starting camera…',
    );

    try {
      await _engine.initialize();
    } on AppException catch (error) {
      if (generation != _generation) return;
      _started = false;
      state = state.copyWith(
        cameraPhase: CameraPhase.failed,
        errorMessage: error.message,
        isDetecting: false,
      );
      return;
    } catch (error) {
      if (generation != _generation) return;
      _started = false;
      state = state.copyWith(
        cameraPhase: CameraPhase.failed,
        errorMessage: error.toString(),
        isDetecting: false,
      );
      return;
    }

    if (generation != _generation) return;

    try {
      await _camera.initialize();
      if (generation != _generation) return;
      await _camera.startImageStream(_onFrame);
      if (generation != _generation) return;
      state = state.copyWith(
        cameraPhase: CameraPhase.ready,
        isDetecting: true,
        statusMessage: 'Detection active',
        clearError: true,
      );
    } on AppException catch (error) {
      if (generation != _generation) return;
      _startFallback(error.message);
    } catch (error) {
      if (generation != _generation) return;
      _startFallback(
        'Camera unavailable. Showing demo preview with mock detections.',
      );
    }
  }

  Future<void> stop() async {
    _generation += 1;
    _started = false;
    await _teardown();
    state = DetectionSessionState(
      compliance: ComplianceResult.fromPeople(const []),
    );
  }

  void capture() {
    ref.read(historyProvider.notifier).addCapture(state.compliance.statistics);
    state = state.copyWith(capturedFlash: true);
    _captureTimer?.cancel();
    _captureTimer = Timer(const Duration(milliseconds: 1400), () {
      if (_alive) {
        state = state.copyWith(capturedFlash: false);
      }
    });
  }

  void _startFallback(String message) {
    state = state.copyWith(
      cameraPhase: CameraPhase.fallback,
      isDetecting: true,
      errorMessage: message,
      statusMessage: 'Demo preview',
    );
    _scheduleFallback();
  }

  void _scheduleFallback() {
    _fallbackTimer?.cancel();
    final fps = ref.read(settingsProvider).targetInferenceFps;
    final interval = Duration(milliseconds: (1000 / fps).round());
    _fallbackTimer = Timer.periodic(interval, (_) {
      _onFrame(FrameData.synthetic());
    });
  }

  Future<void> _resume() async {
    if (!_started) return;
    if (state.cameraPhase == CameraPhase.fallback) {
      _scheduleFallback();
      return;
    }
    try {
      await _camera.resume(_onFrame);
    } catch (_) {
      _startFallback(
        'Camera unavailable. Showing demo preview with mock detections.',
      );
    }
  }

  void _onFrame(FrameData frame) {
    if (!_started || _isProcessing) return;

    final settings = ref.read(settingsProvider);
    final minInterval = Duration(
      milliseconds: (1000 / settings.targetInferenceFps).round(),
    );
    final now = DateTime.now();
    if (_lastInferenceStartedAt != null &&
        now.difference(_lastInferenceStartedAt!) < minInterval) {
      return;
    }

    _isProcessing = true;
    _lastInferenceStartedAt = now;
    unawaited(_runDetection(frame, settings.confidenceThreshold));
  }

  Future<void> _runDetection(FrameData frame, double threshold) async {
    final started = DateTime.now();
    try {
      final raw = await _engine.detect(frame);
      final detections = [
        for (final detection in raw)
          if (detection.confidence >= threshold) detection.clampNormalized(),
      ];
      final people = _analyzer.analyze(detections);
      final inferenceTime = DateTime.now().difference(started);
      _updateFps();
      if (!_alive || !_started) return;
      state = state.copyWith(
        latestFrame: DetectionFrame(
          detections: detections,
          timestamp: DateTime.now(),
          inferenceTime: inferenceTime,
        ),
        compliance: ComplianceResult.fromPeople(people),
        fps: _fps,
        isDetecting: true,
      );
    } on UnimplementedError catch (error) {
      if (_alive) {
        state = state.copyWith(
          errorMessage: error.message ?? 'Model detection is not implemented.',
          isDetecting: false,
        );
      }
    } on AppException catch (error) {
      if (_alive) {
        state = state.copyWith(errorMessage: error.message);
      }
    } catch (error) {
      if (_alive) {
        state = state.copyWith(
          errorMessage: 'Detection failed for this frame.',
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _updateFps() {
    final now = DateTime.now();
    if (_lastInferenceCompletedAt != null) {
      final dt = now.difference(_lastInferenceCompletedAt!).inMilliseconds;
      if (dt > 0) {
        final instant = 1000 / dt;
        _fps = _fps == 0 ? instant : (_fps * 0.75 + instant * 0.25);
      }
    }
    _lastInferenceCompletedAt = now;
  }

  Future<void> _teardown() async {
    _fallbackTimer?.cancel();
    _captureTimer?.cancel();
    _fallbackTimer = null;
    _isProcessing = false;
    try {
      await _camera.stopImageStream();
    } catch (_) {}
  }
}
