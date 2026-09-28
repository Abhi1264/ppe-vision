import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/detection_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../models/detection.dart';
import '../../models/frame_data.dart';
import '../image/image_preprocessor.dart';
import 'detection_provider.dart';
import 'yolo_decode.dart';

class ModelDetectionProvider implements DetectionProvider {
  _YoloWorker? _worker;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (_ready) return;

    final ByteData data;
    try {
      data = await rootBundle.load(DetectionConstants.modelAsset);
    } catch (_) {
      throw const ModelUnavailableException(
        'Missing ${DetectionConstants.modelAsset}.',
      );
    }

    final bytes = Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      _worker = await _YoloWorker.start(bytes);
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
  _InitMsg(this.model);
  final Uint8List model;
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

  static Future<_YoloWorker> start(Uint8List model) async {
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
    final reply = await worker._send(_InitMsg(model));
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

  Interpreter? interpreter;
  var inputIsNchw = false;
  var inputWidth = 0;
  var inputHeight = 0;
  var outputIndex = 0;
  final labels = DetectionConstants.modelLabels;

  await for (final Object? message in inbox) {
    if (message is _StopMsg) {
      interpreter?.close();
      toMain.send(const _StoppedReply());
      break;
    }
    if (message is _InitMsg) {
      try {
        final options = InterpreterOptions()..threads = 2;
        interpreter = Interpreter.fromBuffer(message.model, options: options);
        interpreter.allocateTensors();
        final input = interpreter.getInputTensor(0);
        if (input.type != TensorType.float32) {
          toMain.send(
            _FailReply('Expected a float32 model, got ${input.type}.'),
          );
          continue;
        }
        final shape = input.shape;
        inputIsNchw = shape.length == 4 && shape[1] == 3;
        final inputIsNhwc = shape.length == 4 && shape[3] == 3;
        if (!inputIsNchw && !inputIsNhwc) {
          toMain.send(_FailReply('Unexpected model input shape $shape.'));
          continue;
        }
        inputHeight = inputIsNchw ? shape[2] : shape[1];
        inputWidth = inputIsNchw ? shape[3] : shape[2];
        outputIndex = _detectionOutputIndex(interpreter, 4 + labels.length);
        toMain.send(const _ReadyReply());
      } catch (error) {
        toMain.send(_FailReply('$error'));
      }
      continue;
    }
    if (message is! _DetectMsg || interpreter == null) {
      toMain.send(_FailReply('Model is not initialized.'));
      continue;
    }
    try {
      final image = await DefaultImagePreprocessor(
        targetWidth: inputWidth,
        targetHeight: inputHeight,
      ).process(message.frame);
      final input = _inputTensor(image.rgbBytes, image.width, image.height, inputIsNchw);
      interpreter.getInputTensor(0).data = input.buffer.asUint8List(
        input.offsetInBytes,
        input.lengthInBytes,
      );
      interpreter.invoke();
      final output = interpreter.getOutputTensor(outputIndex);
      final raw = Uint8List.fromList(output.data);
      final upright = uprightFrameSize(message.frame);
      final detections = decodeYoloOutput(
        values: raw.buffer.asFloat32List(),
        shape: output.shape,
        modelWidth: image.width,
        modelHeight: image.height,
        padX: image.padX,
        padY: image.padY,
        letterboxScale: image.letterboxScale,
        uprightWidth: upright.width,
        uprightHeight: upright.height,
      );
      toMain.send(_DetectionsReply(detections));
    } catch (error) {
      toMain.send(_FailReply('$error'));
    }
  }
}

int _detectionOutputIndex(Interpreter interpreter, int channels) {
  final tensors = interpreter.getOutputTensors();
  for (var i = 0; i < tensors.length; i++) {
    final shape = tensors[i].shape;
    if (shape.length == 3 && (shape[1] == channels || shape[2] == channels)) {
      return i;
    }
  }
  return 0;
}

Float32List _inputTensor(Uint8List rgb, int width, int height, bool nchw) {
  final floats = Float32List(width * height * 3);
  if (!nchw) {
    for (var i = 0; i < rgb.length; i++) {
      floats[i] = rgb[i] / 255.0;
    }
    return floats;
  }
  final plane = width * height;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final src = (y * width + x) * 3;
      final dst = y * width + x;
      floats[dst] = rgb[src] / 255.0;
      floats[plane + dst] = rgb[src + 1] / 255.0;
      floats[2 * plane + dst] = rgb[src + 2] / 255.0;
    }
  }
  return floats;
}
