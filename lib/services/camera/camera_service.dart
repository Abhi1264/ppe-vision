import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/errors/app_exception.dart';
import '../../models/frame_data.dart';

typedef FrameCallback = void Function(FrameData frame);

abstract class CameraService {
  Future<void> initialize();
  Future<void> startImageStream(FrameCallback onFrame);
  Future<void> stopImageStream();
  Future<void> pause();
  Future<void> resume(FrameCallback onFrame);
  Future<void> dispose();

  bool get isInitialized;
  bool get supportsImageStream;
  Size? get previewSize;
  Widget? buildPreview();
}

@visibleForTesting
List<CameraDescription> rankDetectedCameras(List<CameraDescription> cameras) {
  const order = [
    CameraLensDirection.back,
    CameraLensDirection.external,
    CameraLensDirection.front,
  ];
  return [
    for (final lens in order) ...cameras.where((c) => c.lensDirection == lens),
  ];
}

class FlutterCameraService implements CameraService {
  CameraController? _controller;
  bool _streaming = false;

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  bool get supportsImageStream =>
      _controller?.supportsImageStreaming() ?? false;

  @override
  Size? get previewSize {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    final size = controller.value.previewSize;
    if (size == null) return null;
    final orientation = controller.description.sensorOrientation;
    if (orientation == 90 || orientation == 270) {
      return Size(size.height, size.width);
    }
    return size;
  }

  @override
  Widget? buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return CameraPreview(controller);
  }

  @override
  Future<void> initialize() async {
    final cameras = await _discoverCameras();
    if (cameras.isEmpty) {
      throw const CameraUnavailableException();
    }

    Object? lastError;
    for (final camera in rankDetectedCameras(cameras)) {
      try {
        await _openCamera(camera);
        return;
      } on CameraException catch (error) {
        lastError = error;
        await _releaseController();
        if (_isPermissionError(error)) {
          throw const CameraPermissionDeniedException();
        }
      } catch (error) {
        lastError = error;
        await _releaseController();
      }
    }

    throw CameraInitializationException(
      'No detected camera could be initialized.',
      lastError,
    );
  }

  Future<List<CameraDescription>> _discoverCameras() async {
    try {
      return await availableCameras();
    } on CameraException catch (error) {
      if (_isPermissionError(error)) {
        throw const CameraPermissionDeniedException();
      }
      throw const CameraUnavailableException();
    } on MissingPluginException {
      throw const CameraUnavailableException();
    }
  }

  Future<void> _openCamera(CameraDescription camera) async {
    await _releaseController();
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: _preferredImageFormat(),
    );
    _controller = controller;
    await controller.initialize();
  }

  ImageFormatGroup? _preferredImageFormat() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => ImageFormatGroup.yuv420,
      TargetPlatform.iOS || TargetPlatform.macOS => ImageFormatGroup.bgra8888,
      _ => null,
    };
  }

  @override
  Future<void> startImageStream(FrameCallback onFrame) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraInitializationException('Camera is not ready.');
    }
    if (!controller.supportsImageStreaming()) return;
    if (controller.value.isStreamingImages) return;
    _streaming = true;
    await controller.startImageStream((image) {
      if (!_streaming) return;
      onFrame(_toFrameData(image, controller));
    });
  }

  @override
  Future<void> stopImageStream() async {
    _streaming = false;
    final controller = _controller;
    if (controller == null || !controller.supportsImageStreaming()) return;
    if (!controller.value.isStreamingImages) return;
    await controller.stopImageStream();
  }

  @override
  Future<void> pause() => stopImageStream();

  @override
  Future<void> resume(FrameCallback onFrame) async {
    if (!isInitialized) return;
    await startImageStream(onFrame);
  }

  @override
  Future<void> dispose() async {
    _streaming = false;
    await _releaseController();
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  FrameData _toFrameData(CameraImage image, CameraController controller) {
    final format = switch (image.format.group) {
      ImageFormatGroup.yuv420 => FrameFormat.yuv420,
      ImageFormatGroup.bgra8888 => FrameFormat.bgra8888,
      _ => FrameFormat.unknown,
    };

    return FrameData(
      width: image.width,
      height: image.height,
      timestamp: DateTime.now(),
      rotationDegrees: controller.description.sensorOrientation,
      format: format,
      planes: [
        for (final plane in image.planes)
          FramePlane(bytes: plane.bytes, bytesPerRow: plane.bytesPerRow),
      ],
    );
  }

  bool _isPermissionError(CameraException error) {
    final code = error.code.toLowerCase();
    return code.contains('accessdenied') ||
        code.contains('permission') ||
        code.contains('accessrestricted');
  }
}
