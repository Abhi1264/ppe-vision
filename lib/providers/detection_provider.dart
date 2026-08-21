import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/fps_tracker.dart';
import '../models/compliance_result.dart';
import '../models/detection.dart';
import '../models/detection_frame.dart';
import '../models/frame_data.dart';
import '../services/camera/camera_service.dart';
import '../services/compliance/ppe_compliance_analyzer.dart';
import '../services/detection/detection_engine_factory.dart';
import '../services/detection/detection_provider.dart' as engine;
import 'camera_provider.dart';
import 'history_provider.dart';
import 'settings_provider.dart';

final detectionEngineProvider = Provider<engine.DetectionProvider>((ref) {
  final backend = ref.watch(settingsProvider.select((s) => s.backend));
  final provider = createDetectionEngine(backend);
  ref.onDispose(provider.dispose);
  return provider;
});

enum CameraPhase { idle, initializing, ready, fallback, failed }

class DetectionSessionState {
  const DetectionSessionState({
    this.cameraPhase = CameraPhase.idle,
    this.isDetecting = false,
    this.latestFrame,
    this.compliance = ComplianceResult.empty,
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
  Duration get inferenceTime => latestFrame?.inferenceTime ?? Duration.zero;
  bool get usingFallbackPreview => cameraPhase == CameraPhase.fallback;
  bool get canCapture => latestFrame != null;

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
  Timer? _fallbackTimer;
  Timer? _captureTimer;
  final FpsTracker _fps = FpsTracker();

  CameraService get _camera => ref.read(cameraServiceProvider);
  engine.DetectionProvider get _engine => ref.read(detectionEngineProvider);

  bool _isCurrent(int generation) => _alive && generation == _generation;

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
    return const DetectionSessionState();
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
      statusMessage: AppStrings.startingCamera,
    );

    final engineError = await _initializeEngine();
    if (!_isCurrent(generation)) return;
    if (engineError != null) {
      _started = false;
      state = state.copyWith(
        cameraPhase: CameraPhase.failed,
        errorMessage: engineError,
        isDetecting: false,
      );
      return;
    }

    try {
      await _camera.initialize();
      if (!_isCurrent(generation)) return;
      var streaming = false;
      if (_camera.supportsImageStream) {
        try {
          await _camera.startImageStream(_onFrame);
          streaming = true;
        } catch (_) {
          streaming = false;
        }
      }
      if (!streaming) {
        _scheduleFallback();
      }
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        cameraPhase: CameraPhase.ready,
        isDetecting: true,
        statusMessage: AppStrings.detectionActive,
        clearError: true,
      );
    } on AppException catch (error) {
      if (!_isCurrent(generation)) return;
      _startFallback(error.message);
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _startFallback(AppStrings.cameraUnavailable);
    }
  }

  Future<String?> _initializeEngine() async {
    try {
      await _engine.initialize();
      return null;
    } on AppException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> stop() async {
    _generation += 1;
    _started = false;
    _fps.reset();
    await _teardown();
    state = const DetectionSessionState();
  }

  void capture() {
    unawaited(
      ref.read(historyProvider.notifier).addCapture(state.compliance.statistics),
    );
    state = state.copyWith(capturedFlash: true);
    _captureTimer?.cancel();
    _captureTimer = Timer(AppDurations.captureToast, () {
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
      statusMessage: AppStrings.demoPreviewStatus,
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
      if (_camera.supportsImageStream) {
        await _camera.resume(_onFrame);
      } else if (_camera.isInitialized) {
        _scheduleFallback();
      } else {
        _startFallback(AppStrings.cameraUnavailable);
      }
    } catch (_) {
      _startFallback(AppStrings.cameraUnavailable);
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
      _fps.record(DateTime.now());
      if (!_alive || !_started) return;
      state = state.copyWith(
        latestFrame: DetectionFrame(
          detections: detections,
          timestamp: DateTime.now(),
          inferenceTime: inferenceTime,
        ),
        compliance: ComplianceResult.fromPeople(people),
        fps: _fps.value,
        isDetecting: true,
      );
    } on UnimplementedError catch (error) {
      _setError(error.message ?? AppStrings.modelUnimplemented, detecting: false);
    } on AppException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError(AppStrings.inferenceFailed);
    } finally {
      _isProcessing = false;
    }
  }

  void _setError(String message, {bool? detecting}) {
    if (!_alive) return;
    state = state.copyWith(
      errorMessage: message,
      isDetecting: detecting ?? state.isDetecting,
    );
  }

  Future<void> _teardown() async {
    _fallbackTimer?.cancel();
    _captureTimer?.cancel();
    _fallbackTimer = null;
    _captureTimer = null;
    _isProcessing = false;
    try {
      await _camera.stopImageStream();
    } catch (_) {}
  }
}
