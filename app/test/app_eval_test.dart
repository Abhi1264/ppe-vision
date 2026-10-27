import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppe_vision/core/constants/detection_constants.dart';
import 'package:ppe_vision/models/frame_data.dart';
import 'package:ppe_vision/services/detection/frame_detector.dart';
// The plugin's Interpreter only finds its runtime inside an app bundle.
// ignore: implementation_imports
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';

/// Runs the app's detection pipeline on frames from `ml/app_eval.py prepare`.
/// `make eval-app` sets PPE_EVAL_DIR; plain `flutter test` skips this.
void main() {
  final dir = Platform.environment['PPE_EVAL_DIR'];

  test(
    'app pipeline on the eval frames',
    () {
      final tflite = TensorFlowLiteBindings(
        DynamicLibrary.open(_runtimePath()),
      );
      final ppe = _model(tflite, DetectionConstants.modelAsset);
      final person = _model(tflite, DetectionConstants.personModelAsset);
      final manifest = (jsonDecode(
        File('$dir/manifest.json').readAsStringSync(),
      ) as List).cast<Map<String, dynamic>>();

      final images = <String, Object>{};
      final clock = Stopwatch()..start();
      for (final item in manifest) {
        final frame = _frame(
          '$dir/${item['file']}',
          item['width'] as int,
          item['height'] as int,
        );
        images[item['name'] as String] = [
          for (final d in detectFrame(frame, ppe: ppe, person: person))
            if (d.confidence >= DetectionConstants.defaultConfidenceThreshold)
              {
                'cls': d.classType.name,
                'conf': d.confidence,
                'box': [d.x1, d.y1, d.x2, d.y2],
              },
        ];
      }
      clock.stop();

      File('$dir/app.json').writeAsStringSync(
        jsonEncode({
          'ms_per_frame': clock.elapsedMilliseconds / manifest.length,
          'images': images,
        }),
      );
    },
    skip: dir == null ? 'Set PPE_EVAL_DIR, or run make eval-app' : false,
    timeout: Timeout.none,
  );
}

String _runtimePath() {
  return switch (Platform.operatingSystem) {
    'macos' =>
      _pluginRoot().resolve('macos/libtensorflowlite_c-mac.dylib').toFilePath(),
    'linux' => 'blobs/libtensorflowlite_c-linux.so',
    'windows' => 'blobs/libtensorflowlite_c-win.dll',
    final os => throw UnsupportedError('No TFLite runtime for $os'),
  };
}

Uri _pluginRoot() {
  final file = File('.dart_tool/package_config.json');
  final packages =
      ((jsonDecode(file.readAsStringSync()) as Map)['packages'] as List)
          .cast<Map<String, dynamic>>();
  final root = file.absolute.uri.resolve(
    packages.firstWhere((p) => p['name'] == 'tflite_flutter')['rootUri']
        as String,
  );
  return root.path.endsWith('/') ? root : Uri.parse('$root/');
}

RunModel _model(TensorFlowLiteBindings tflite, String asset) {
  final options = tflite.TfLiteInterpreterOptionsCreate();
  tflite.TfLiteInterpreterOptionsSetNumThreads(options, 4);
  final path = asset.toNativeUtf8();
  final model = tflite.TfLiteModelCreateFromFile(path.cast());
  malloc.free(path);
  final interpreter = tflite.TfLiteInterpreterCreate(model, options);
  if (interpreter == nullptr ||
      tflite.TfLiteInterpreterAllocateTensors(interpreter) != 0) {
    throw StateError('Could not load $asset');
  }
  final output = tflite.TfLiteInterpreterGetOutputTensor(interpreter, 0);
  final shape = [
    for (var i = 0; i < tflite.TfLiteTensorNumDims(output); i++)
      tflite.TfLiteTensorDim(output, i),
  ];
  final outputBytes = tflite.TfLiteTensorByteSize(output);
  const size = DetectionConstants.modelInputSize;
  final inputBuffer = malloc<Float>(size * size * 3);
  final outputBuffer = malloc<Float>(outputBytes ~/ 4);

  return (Float32List input) {
    inputBuffer.asTypedList(input.length).setAll(0, input);
    final input0 = tflite.TfLiteInterpreterGetInputTensor(interpreter, 0);
    if (tflite.TfLiteTensorCopyFromBuffer(
              input0,
              inputBuffer.cast(),
              input.length * 4,
            ) !=
            0 ||
        tflite.TfLiteInterpreterInvoke(interpreter) != 0 ||
        tflite.TfLiteTensorCopyToBuffer(
              output,
              outputBuffer.cast(),
              outputBytes,
            ) !=
            0) {
      throw StateError('Inference failed for $asset');
    }
    return (
      values: Float32List.fromList(outputBuffer.asTypedList(outputBytes ~/ 4)),
      shape: shape,
    );
  };
}

FrameData _frame(String path, int width, int height) {
  final bytes = File(path).readAsBytesSync();
  final chromaWidth = (width + 1) ~/ 2;
  final luma = width * height;
  final chroma = chromaWidth * ((height + 1) ~/ 2);
  return FrameData(
    width: width,
    height: height,
    timestamp: DateTime.utc(2026),
    format: FrameFormat.yuv420,
    planes: [
      FramePlane(
        bytes: Uint8List.sublistView(bytes, 0, luma),
        bytesPerRow: width,
      ),
      FramePlane(
        bytes: Uint8List.sublistView(bytes, luma, luma + chroma),
        bytesPerRow: chromaWidth,
      ),
      FramePlane(
        bytes: Uint8List.sublistView(bytes, luma + chroma, luma + 2 * chroma),
        bytesPerRow: chromaWidth,
      ),
    ],
  );
}
