import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/fps_tracker.dart';
import '../models/app_settings.dart';
import '../models/compliance_result.dart';
import '../models/detection.dart';
import '../models/detection_frame.dart';
import '../models/frame_data.dart';
import '../models/person_detection.dart';
import '../models/site_log.dart';
import '../services/camera/camera_service.dart';
import '../services/compliance/ppe_compliance_analyzer.dart';
import '../services/compliance/violation_streak.dart';
import '../services/detection/model_detection_provider.dart';
import 'camera_provider.dart';
import 'event_log_provider.dart';
import 'settings_provider.dart';

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
    this.notice,
    this.previewJpeg,
    this.previewWidth = 0,
    this.previewHeight = 0,
    this.lensLabel = 'back',
  });

  final CameraPhase cameraPhase;
  final bool isDetecting;
  final DetectionFrame? latestFrame;
  final ComplianceResult compliance;
  final double fps;
  final String? errorMessage;
  final String? statusMessage;
  final String? notice;
  final Uint8List? previewJpeg;
  final int previewWidth;
  final int previewHeight;
  final String lensLabel;

  List<Detection> get detections => latestFrame?.detections ?? const [];
  Duration get inferenceTime => latestFrame?.inferenceTime ?? Duration.zero;
  bool get usingFallbackPreview =>
      previewJpeg == null && cameraPhase != CameraPhase.ready;

  DetectionSessionState copyWith({
    CameraPhase? cameraPhase,
    bool? isDetecting,
    DetectionFrame? latestFrame,
    ComplianceResult? compliance,
    double? fps,
    String? errorMessage,
    String? statusMessage,
    String? notice,
    Uint8List? previewJpeg,
    int? previewWidth,
    int? previewHeight,
    String? lensLabel,
    bool clearError = false,
    bool clearNotice = false,
    bool clearFrame = false,
    bool clearJpeg = false,
  }) {
    return DetectionSessionState(
      cameraPhase: cameraPhase ?? this.cameraPhase,
      isDetecting: isDetecting ?? this.isDetecting,
      latestFrame: clearFrame ? null : (latestFrame ?? this.latestFrame),
      compliance: compliance ?? this.compliance,
      fps: fps ?? this.fps,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: statusMessage ?? this.statusMessage,
      notice: clearNotice ? null : (notice ?? this.notice),
      previewJpeg: clearJpeg ? null : (previewJpeg ?? this.previewJpeg),
      previewWidth: previewWidth ?? this.previewWidth,
      previewHeight: previewHeight ?? this.previewHeight,
      lensLabel: lensLabel ?? this.lensLabel,
    );
  }
}

final detectionSessionProvider =
    NotifierProvider<DetectionSessionNotifier, DetectionSessionState>(
      DetectionSessionNotifier.new,
    );

class DetectionSessionNotifier extends Notifier<DetectionSessionState>
    with WidgetsBindingObserver {
  bool _started = false;
  bool _alive = true;
  bool _busy = false;
  int _generation = 0;
  DateTime? _lastFrame;
  CameraLensDirection _lens = CameraLensDirection.back;
  final FpsTracker _fps = FpsTracker();
  final _analyzer = const PPEComplianceAnalyzer();
  final _streak = ViolationStreak();
  late final CameraService _camera;
  late final ModelDetectionProvider _model;

  bool _isCurrent(int generation) => _alive && generation == _generation;

  @override
  DetectionSessionState build() {
    final observer = this;
    _camera = ref.read(cameraServiceProvider);
    _model = ModelDetectionProvider();
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
    if (state == AppLifecycleState.resumed) {
      unawaited(_resume());
      return;
    }
    if (state == AppLifecycleState.detached) return;
    _busy = false;
    unawaited(_camera.pause());
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final generation = ++_generation;
    state = state.copyWith(
      cameraPhase: CameraPhase.initializing,
      isDetecting: false,
      clearError: true,
      clearNotice: true,
      statusMessage: 'Starting camera',
    );
    try {
      await _model.initialize();
      if (!_isCurrent(generation)) return;
      await _camera.initialize();
      if (!_isCurrent(generation)) return;
      if (!_camera.supportsImageStream) {
        _fail('This camera does not stream frames.');
        return;
      }
      await _camera.startImageStream(_onFrame);
    } on AppException catch (error) {
      if (_isCurrent(generation)) _fail(error.message);
      return;
    } catch (error) {
      if (_isCurrent(generation)) _fail(error.toString());
      return;
    }
    if (!_isCurrent(generation)) return;
    state = state.copyWith(
      cameraPhase: CameraPhase.ready,
      isDetecting: true,
      statusMessage: 'Live',
      lensLabel: _lens == CameraLensDirection.front ? 'front' : 'back',
      clearError: true,
    );
  }

  Future<void> _resume() async {
    if (!_started) return;
    try {
      if (!_model.isReady) await _model.initialize();
      if (!_camera.isInitialized) await _camera.initialize();
      await _camera.resume(_onFrame);
    } catch (error) {
      if (_started) state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> stop() async {
    _generation += 1;
    _started = false;
    _fps.reset();
    await _teardown();
    if (!_alive) return;
    state = const DetectionSessionState();
  }

  Future<void> switchCamera() async {
    if (!_started) return;
    final next = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    try {
      await _camera.stopImageStream();
      await _camera.useLens(next);
      _lens = next;
      await _camera.startImageStream(_onFrame);
      state = state.copyWith(
        lensLabel: next == CameraLensDirection.front ? 'front' : 'back',
        clearError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  void _onFrame(FrameData frame) {
    if (!_started || _busy) return;
    final settings = ref.read(settingsProvider);
    final minInterval = Duration(
      milliseconds: (1000 / settings.targetInferenceFps).round(),
    );
    final now = DateTime.now();
    if (_lastFrame != null && now.difference(_lastFrame!) < minInterval) return;
    _busy = true;
    _lastFrame = now;
    unawaited(_infer(frame, settings, _generation));
  }

  Future<void> _infer(
    FrameData frame,
    AppSettings settings,
    int generation,
  ) async {
    final started = DateTime.now();
    try {
      final raw = await _model.detect(frame);
      if (!_isCurrent(generation)) return;
      final kept = [
        for (final detection in raw)
          if (detection.confidence >= settings.confidenceThreshold) detection,
      ];
      final people = [
        for (final person in _analyzer.analyze(kept))
          PersonDetection(
            person: person.person,
            helmet: person.helmet,
            vest: person.vest,
            countHelmet: settings.requireHardhat,
            countVest: settings.requireVest,
          ),
      ];
      final compliance = ComplianceResult.fromPeople(people);
      final fired = _streak.tick(
        missingHardhat: people.any(
          (person) => person.missingItems.contains('helmet'),
        ),
        missingVest: people.any(
          (person) => person.missingItems.contains('vest'),
        ),
        confirm: settings.confirmFrames,
      );
      final log = ref.read(eventLogProvider.notifier);
      log.addFrames(
        compliance.statistics.peopleCount,
        compliance.statistics.compliantCount,
      );
      if (fired.isNotEmpty) {
        final camera = state.lensLabel;
        log.addEvents([
          for (final type in fired)
            SiteEvent(type: type, camera: camera, at: DateTime.now()),
        ]);
      }
      _fps.record(DateTime.now());
      state = state.copyWith(
        latestFrame: DetectionFrame(
          detections: kept,
          timestamp: DateTime.now(),
          inferenceTime: DateTime.now().difference(started),
        ),
        compliance: compliance,
        fps: _fps.value,
        isDetecting: true,
        cameraPhase: CameraPhase.ready,
        clearError: true,
      );
    } catch (error) {
      if (_isCurrent(generation)) {
        state = state.copyWith(errorMessage: error.toString());
      }
    } finally {
      if (_isCurrent(generation)) _busy = false;
    }
  }

  void _fail(String message) {
    _started = false;
    state = state.copyWith(
      cameraPhase: CameraPhase.failed,
      isDetecting: false,
      errorMessage: message,
      statusMessage: 'Camera unavailable',
    );
  }

  Future<void> _teardown() async {
    _busy = false;
    try {
      await _camera.stopImageStream();
    } catch (_) {}
    try {
      await _model.dispose();
    } catch (_) {}
  }
}
