import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/detection_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import 'detection_provider.dart';
import 'frame_detector.dart';

class ModelDetectionProvider implements DetectionProvider {
  _YoloWorker? _worker;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (_ready) return;

    final ppe = await _asset(DetectionConstants.modelAsset);
    final person = await _asset(DetectionConstants.personModelAsset);
    try {
      _worker = await _YoloWorker.start(ppe, person);
      _ready = true;
    } catch (error) {
      throw ModelInitializationException(
        'The detection model failed to initialize. $error',
        error,
      );
    }
  }

  @override
  Future<List<Detection>> detect(FrameData frame) {
    final worker = _worker;
    if (!_ready || worker == null) {
      return Future<List<Detection>>.error(
        const InferenceException('The detection model is not initialized.'),
      );
    }
    if (!frame.hasPixelData) return Future<List<Detection>>.value(const []);
    return worker.detect(_copyFrame(frame));
  }

  @override
  Future<void> dispose() async {
    _ready = false;
    final worker = _worker;
    _worker = null;
    await worker?.stop();
  }
}

Future<Uint8List> _asset(String path) async {
  try {
    final data = await rootBundle.load(path);
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } catch (_) {
    throw ModelUnavailableException('Missing $path.');
  }
}

FrameData _copyFrame(FrameData frame) {
  return FrameData(
    width: frame.width,
    height: frame.height,
    timestamp: frame.timestamp,
    rotationDegrees: frame.rotationDegrees,
    format: frame.format,
    mirrored: frame.mirrored,
    planes: [
      for (final plane in frame.planes)
        FramePlane(
          bytes: Uint8List.fromList(plane.bytes),
          bytesPerRow: plane.bytesPerRow,
          bytesPerPixel: plane.bytesPerPixel,
        ),
    ],
  );
}

sealed class _WorkerMsg {
  const _WorkerMsg();
}

class _InitMsg extends _WorkerMsg {
  _InitMsg(this.ppe, this.person);
  final Uint8List ppe;
  final Uint8List person;
}

class _DetectMsg extends _WorkerMsg {
  _DetectMsg(this.frame);
  final FrameData frame;
}

class _StopMsg extends _WorkerMsg {
  const _StopMsg();
}

sealed class _WorkerReply {
  const _WorkerReply();
}

class _ReadyReply extends _WorkerReply {
  const _ReadyReply();
}

class _StoppedReply extends _WorkerReply {
  const _StoppedReply();
}

class _DetectionsReply extends _WorkerReply {
  _DetectionsReply(this.detections);
  final List<Detection> detections;
}

class _FailReply extends _WorkerReply {
  _FailReply(this.message);
  final String message;
}

class _YoloWorker {
  _YoloWorker(this._isolate);

  late final SendPort _toWorker;
  final Isolate _isolate;
  late final StreamSubscription<dynamic> _subscription;
  final List<Completer<_WorkerReply>> _waiters = [];

  static Future<_YoloWorker> start(Uint8List ppe, Uint8List person) async {
    final fromWorker = ReceivePort();
    final isolate = await Isolate.spawn(yoloWorkerMain, fromWorker.sendPort);
    final handshake = Completer<SendPort>();
    final worker = _YoloWorker(isolate);
    // One listener for the whole port. ReceivePort.first would consume it.
    worker._subscription = fromWorker.listen((Object? message) {
      if (!handshake.isCompleted) {
        handshake.complete(message as SendPort);
        return;
      }
      worker._onReply(message);
    });
    worker._toWorker = await handshake.future;
    final reply = await worker._send(_InitMsg(ppe, person));
    if (reply is _ReadyReply) return worker;
    await worker.stop();
    throw ModelInitializationException(
      reply is _FailReply
          ? reply.message
          : 'The detection model failed to initialize.',
    );
  }

  Future<List<Detection>> detect(FrameData frame) async {
    final waiter = Completer<_WorkerReply>();
    _waiters.add(waiter);
    _toWorker.send(_DetectMsg(frame));
    final _WorkerReply reply;
    try {
      reply = await waiter.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _waiters.remove(waiter);
      throw const InferenceException('Detection timed out.');
    }
    if (reply is _DetectionsReply) return reply.detections;
    if (reply is _FailReply) throw InferenceException(reply.message);
    throw const InferenceException();
  }

  Future<void> stop() async {
    if (_waiters.isEmpty) {
      _toWorker.send(const _StopMsg());
    }
    _isolate.kill(priority: Isolate.immediate);
    await _subscription.cancel();
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(const InferenceException('Model stopped.'));
      }
    }
    _waiters.clear();
  }

  Future<_WorkerReply> _send(_WorkerMsg message) {
    final waiter = Completer<_WorkerReply>();
    _waiters.add(waiter);
    _toWorker.send(message);
    return waiter.future;
  }

  void _onReply(Object? message) {
    if (_waiters.isEmpty) return;
    final waiter = _waiters.removeAt(0);
    if (waiter.isCompleted) return;
    if (message is _WorkerReply) {
      waiter.complete(message);
      return;
    }
    waiter.complete(_FailReply('Unexpected model response.'));
  }
}

Future<void> yoloWorkerMain(SendPort toMain) async {
  final inbox = ReceivePort();
  toMain.send(inbox.sendPort);

  final interpreters = <Interpreter>[];
  RunModel? ppe;
  RunModel? person;

  await for (final Object? message in inbox) {
    if (message is _StopMsg) {
      for (final interpreter in interpreters) {
        interpreter.close();
      }
      toMain.send(const _StoppedReply());
      break;
    }
    if (message is _InitMsg) {
      try {
        ppe = _runner(_interpreter(message.ppe, interpreters));
        person = _runner(_interpreter(message.person, interpreters));
        toMain.send(const _ReadyReply());
      } catch (error) {
        toMain.send(_FailReply('$error'));
      }
      continue;
    }
    final runPpe = ppe;
    final runPerson = person;
    if (message is! _DetectMsg || runPpe == null || runPerson == null) {
      toMain.send(_FailReply('Model is not initialized.'));
      continue;
    }
    try {
      toMain.send(
        _DetectionsReply(detectFrame(message.frame, ppe: runPpe, person: runPerson)),
      );
    } catch (error) {
      toMain.send(_FailReply('$error'));
    }
  }
}

Interpreter _interpreter(Uint8List model, List<Interpreter> opened) {
  final interpreter = Interpreter.fromBuffer(
    model,
    options: InterpreterOptions()..threads = 2,
  );
  opened.add(interpreter);
  interpreter.allocateTensors();
  final input = interpreter.getInputTensor(0);
  const size = DetectionConstants.modelInputSize;
  if (input.type != TensorType.float32 || input.shape.join(',') != '1,$size,$size,3') {
    throw StateError(
      'Expected a float32 [1, $size, $size, 3] input, got ${input.type} ${input.shape}.',
    );
  }
  return interpreter;
}

RunModel _runner(Interpreter interpreter) {
  return (Float32List input) {
    interpreter.getInputTensor(0).data = input.buffer.asUint8List(
      input.offsetInBytes,
      input.lengthInBytes,
    );
    interpreter.invoke();
    final output = interpreter.getOutputTensor(0);
    return (
      values: Uint8List.fromList(output.data).buffer.asFloat32List(),
      shape: output.shape,
    );
  };
}
