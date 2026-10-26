import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
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
import '../services/api/ppe_api.dart';
import '../services/camera/camera_service.dart';
import '../services/image/image_preprocessor.dart';
import 'camera_provider.dart';
import 'settings_provider.dart';

final ppeApiProvider = Provider<PpeApi>((ref) => const PpeApi());

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
  bool get usingFallbackPreview => previewJpeg == null && cameraPhase != CameraPhase.ready;

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
  bool _posting = false;
  int _generation = 0;
  Timer? _poll;
  DateTime? _lastPost;
  CameraLensDirection _lens = CameraLensDirection.back;
  final FpsTracker _fps = FpsTracker();
  late final CameraService _camera;
  late final PpeApi _api;
  String _base = 'http://127.0.0.1:8000';

  bool _isCurrent(int generation) => _alive && generation == _generation;

  @override
  DetectionSessionState build() {
    final observer = this;
    _camera = ref.read(cameraServiceProvider);
    _api = ref.read(ppeApiProvider);
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
    if (state == AppLifecycleState.resumed) return;
    if (state == AppLifecycleState.detached) return;
    _poll?.cancel();
    unawaited(_camera.pause());
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final generation = ++_generation;
    final settings = ref.read(settingsProvider);
    _base = settings.serverUrl;
    state = state.copyWith(
      cameraPhase: CameraPhase.initializing,
      isDetecting: false,
      clearError: true,
      clearNotice: true,
      statusMessage: 'Connecting to ${settings.serverUrl}',
    );
    final problem = await _api.healthError(settings.serverUrl).then<String?>(
      (error) => error.isEmpty ? null : error,
      onError: (Object error) => error.toString(),
    );
    if (!_isCurrent(generation)) return;
    if (problem != null) {
      _fail(problem);
      return;
    }
    if (settings.useDeviceCamera) {
      await _startDevice(settings, generation);
    } else {
      await _startServerCamera(settings, generation);
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
    if (!_started || !ref.read(settingsProvider).useDeviceCamera) return;
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

  Future<void> _startServerCamera(AppSettings settings, int generation) async {
    try {
      await _api.startJob(
        base: settings.serverUrl,
        source: '0',
        cameraId: '0',
        required: settings.requiredPpe,
        confirmFrames: settings.confirmFrames,
        conf: settings.confidenceThreshold,
      );
    } catch (error) {
      if (_isCurrent(generation)) _fail(error.toString());
      return;
    }
    if (!_isCurrent(generation)) return;
    state = state.copyWith(
      cameraPhase: CameraPhase.ready,
      isDetecting: true,
      statusMessage: 'Server webcam',
      clearError: true,
    );
    _poll = Timer.periodic(
      Duration(milliseconds: (1000 / settings.targetInferenceFps).round()),
      (_) => unawaited(_pullServer()),
    );
  }

  Future<void> _startDevice(AppSettings settings, int generation) async {
    try {
      await _camera.initialize();
      if (!_isCurrent(generation)) return;
      if (_camera.supportsImageStream) {
        await _camera.startImageStream(_onFrame);
      } else {
        _fail('This device camera does not stream frames.');
        return;
      }
    } on AppException catch (error) {
      if (_isCurrent(generation)) _fail(error.message);
      return;
    } catch (error) {
      if (_isCurrent(generation)) _fail(error.toString());
      return;
    }
    state = state.copyWith(
      cameraPhase: CameraPhase.ready,
      isDetecting: true,
      statusMessage: 'Device camera',
      lensLabel: 'back',
      clearError: true,
    );
  }

  Future<void> _pullServer() async {
    if (!_started || _posting) return;
    _posting = true;
    final settings = ref.read(settingsProvider);
    try {
      final view = await _api.live(settings.serverUrl, '0');
      if (!_started) return;
      _apply(view, settings);
    } catch (error) {
      if (_started) state = state.copyWith(errorMessage: error.toString());
    } finally {
      _posting = false;
    }
  }

  void _onFrame(FrameData frame) {
    if (!_started || _posting) return;
    final settings = ref.read(settingsProvider);
    final minInterval = Duration(
      milliseconds: (1000 / settings.targetInferenceFps).round(),
    );
    final now = DateTime.now();
    if (_lastPost != null && now.difference(_lastPost!) < minInterval) return;
    _posting = true;
    _lastPost = now;
    unawaited(_post(frame, settings));
  }

  Future<void> _post(FrameData frame, AppSettings settings) async {
    try {
      final image = await const DefaultImagePreprocessor().process(frame);
      final view = await _api.postFrame(
        base: settings.serverUrl,
        rgb: image.rgbBytes,
        width: image.width,
        height: image.height,
        cameraId: 'device-${state.lensLabel}',
        required: settings.requiredPpe,
        confirmFrames: settings.confirmFrames,
        conf: settings.confidenceThreshold,
      );
      if (!_started) return;
      _apply(view, settings);
    } catch (error) {
      if (_started) state = state.copyWith(errorMessage: error.toString());
    } finally {
      _posting = false;
    }
  }

  void _apply(LiveView view, AppSettings settings) {
    final detections = <Detection>[];
    final people = <PersonDetection>[];
    for (final track in view.tracks) {
      final person = _box(DetectionClass.person, 'person', track.person, track.confidence);
      final hardhat = track.hardhat == null
          ? null
          : _box(DetectionClass.helmet, 'hardhat', track.hardhat!, track.confidence);
      final vest = track.vest == null
          ? null
          : _box(DetectionClass.vest, 'vest', track.vest!, track.confidence);
      detections.add(person);
      if (hardhat != null) detections.add(hardhat);
      if (vest != null) detections.add(vest);
      people.add(
        PersonDetection(
          person: person,
          helmet: hardhat,
          vest: vest,
          countHelmet: settings.requireHardhat,
          countVest: settings.requireVest,
        ),
      );
    }
    _fps.record(DateTime.now());
    final notice = view.opened.isEmpty
        ? null
        : 'Logged ${view.opened.map((event) => event['violation_type']).join(', ')}';
    state = state.copyWith(
      latestFrame: DetectionFrame(
        detections: detections,
        timestamp: DateTime.now(),
        inferenceTime: Duration.zero,
      ),
      compliance: ComplianceResult.fromPeople(people),
      fps: _fps.value,
      isDetecting: true,
      previewJpeg: view.jpeg ?? state.previewJpeg,
      previewWidth: view.width,
      previewHeight: view.height,
      notice: notice,
      clearNotice: notice == null,
      clearError: true,
      cameraPhase: CameraPhase.ready,
    );
  }

  Detection _box(DetectionClass type, String label, List<double> coords, double confidence) {
    return Detection(
      classType: type,
      label: label,
      confidence: confidence,
      x1: coords[0],
      y1: coords[1],
      x2: coords[2],
      y2: coords[3],
    );
  }

  void _fail(String message) {
    _started = false;
    _poll?.cancel();
    state = state.copyWith(
      cameraPhase: CameraPhase.failed,
      isDetecting: false,
      errorMessage: message,
      statusMessage: 'Not detecting',
    );
  }

  Future<void> _teardown() async {
    _poll?.cancel();
    _poll = null;
    _posting = false;
    final base = _base;
    try {
      await _camera.stopImageStream();
    } catch (_) {}
    try {
      await _api.stopJob(base);
    } catch (_) {}
  }
}
