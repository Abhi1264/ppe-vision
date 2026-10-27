import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/errors/app_exception.dart';
import '../../models/frame_data.dart';
import '../../models/processed_image.dart';

abstract class ImagePreprocessor {
  Future<ProcessedImage> process(FrameData frame);
}

class DefaultImagePreprocessor implements ImagePreprocessor {
  const DefaultImagePreprocessor({
    this.targetWidth = 640,
    this.targetHeight = 640,
  });

  final int targetWidth;
  final int targetHeight;

  @override
  Future<ProcessedImage> process(FrameData frame) {
    return Future<ProcessedImage>.value(processSync(frame));
  }

  /// Same letterbox as Ultralytics: bilinear resize, gray 114 border, integer pads.
  ProcessedImage processSync(FrameData frame) {
    if (!frame.hasPixelData || frame.width <= 0 || frame.height <= 0) {
      throw const InvalidFrameException();
    }
    final upright = uprightFrameSize(frame);
    final w = upright.width;
    final h = upright.height;
    if (w <= 0 || h <= 0) throw const InvalidFrameException();

    final source = Uint8List(w * h * 3);
    for (var uy = 0; uy < h; uy++) {
      for (var ux = 0; ux < w; ux++) {
        final sensor = _sensorPoint(frame, ux, uy, w);
        final pixel = _sample(frame, sensor.$1, sensor.$2);
        final i = (uy * w + ux) * 3;
        source[i] = pixel.$1;
        source[i + 1] = pixel.$2;
        source[i + 2] = pixel.$3;
      }
    }

    final scale = math.min(targetWidth / w, targetHeight / h);
    final resizedW = math.max(1, (w * scale).round());
    final resizedH = math.max(1, (h * scale).round());
    final left = ((targetWidth - resizedW) / 2 - 0.1).round();
    final top = ((targetHeight - resizedH) / 2 - 0.1).round();
    final stepX = w / resizedW;
    final stepY = h / resizedH;

    final rgb = Uint8List(targetWidth * targetHeight * 3);
    rgb.fillRange(0, rgb.length, 114);
    for (var row = 0; row < resizedH; row++) {
      final sy = ((row + 0.5) * stepY - 0.5).clamp(0.0, h - 1.0);
      final y0 = sy.floor();
      final y1 = math.min(y0 + 1, h - 1);
      final fy = sy - y0;
      for (var col = 0; col < resizedW; col++) {
        final sx = ((col + 0.5) * stepX - 0.5).clamp(0.0, w - 1.0);
        final x0 = sx.floor();
        final x1 = math.min(x0 + 1, w - 1);
        final fx = sx - x0;
        final a = (y0 * w + x0) * 3;
        final b = (y0 * w + x1) * 3;
        final c = (y1 * w + x0) * 3;
        final d = (y1 * w + x1) * 3;
        final dst = ((top + row) * targetWidth + left + col) * 3;
        for (var k = 0; k < 3; k++) {
          final upper = source[a + k] + (source[b + k] - source[a + k]) * fx;
          final lower = source[c + k] + (source[d + k] - source[c + k]) * fx;
          rgb[dst + k] = (upper + (lower - upper) * fy).round();
        }
      }
    }

    return ProcessedImage(
      width: targetWidth,
      height: targetHeight,
      rgbBytes: rgb,
      letterboxScale: scale,
      padX: left.toDouble(),
      padY: top.toDouble(),
    );
  }

  (int, int) _sensorPoint(FrameData frame, int ux, int uy, int uprightWidth) {
    var x = ux;
    var y = uy;
    if (frame.mirrored) x = uprightWidth - 1 - x;
    final (int sx, int sy) = switch (frame.rotationDegrees % 360) {
      90 => (y, frame.height - 1 - x),
      180 => (frame.width - 1 - x, frame.height - 1 - y),
      270 => (frame.width - 1 - y, x),
      _ => (x, y),
    };
    return (
      sx.clamp(0, frame.width - 1),
      sy.clamp(0, frame.height - 1),
    );
  }

  (int, int, int) _sample(FrameData frame, int x, int y) {
    return switch (frame.format) {
      FrameFormat.bgra8888 => _sampleBgra(frame, x, y),
      FrameFormat.rgba8888 => _sampleRgba(frame, x, y),
      FrameFormat.yuv420 => _sampleYuv(frame, x, y),
      FrameFormat.jpeg || FrameFormat.unknown => throw const InvalidFrameException(
        'This camera frame format is not supported.',
      ),
    };
  }

  (int, int, int) _sampleBgra(FrameData frame, int x, int y) {
    final plane = frame.planes.first;
    final index = y * plane.bytesPerRow + x * 4;
    return (
      _at(plane.bytes, index + 2),
      _at(plane.bytes, index + 1),
      _at(plane.bytes, index),
    );
  }

  (int, int, int) _sampleRgba(FrameData frame, int x, int y) {
    final plane = frame.planes.first;
    final index = y * plane.bytesPerRow + x * 4;
    return (
      _at(plane.bytes, index),
      _at(plane.bytes, index + 1),
      _at(plane.bytes, index + 2),
    );
  }

  (int, int, int) _sampleYuv(FrameData frame, int x, int y) {
    if (frame.planes.length < 3) {
      throw const InvalidFrameException('YUV frame is missing a plane.');
    }
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final yValue = _at(
      yPlane.bytes,
      y * yPlane.bytesPerRow + x * _pixelStride(yPlane.bytesPerPixel),
    );
    final uValue = _at(
      uPlane.bytes,
      (y >> 1) * uPlane.bytesPerRow +
          (x >> 1) * _pixelStride(uPlane.bytesPerPixel),
    );
    final vValue = _at(
      vPlane.bytes,
      (y >> 1) * vPlane.bytesPerRow +
          (x >> 1) * _pixelStride(vPlane.bytesPerPixel),
    );
    return _yuvToRgb(yValue, uValue, vValue);
  }
}

({int width, int height}) uprightFrameSize(FrameData frame) {
  final swap = frame.rotationDegrees % 180 != 0;
  return (
    width: swap ? frame.height : frame.width,
    height: swap ? frame.width : frame.height,
  );
}

int _pixelStride(int bytesPerPixel) => bytesPerPixel < 1 ? 1 : bytesPerPixel;

int _at(Uint8List bytes, int index) {
  if (bytes.isEmpty) return 0;
  if (index < 0) return bytes[0];
  if (index >= bytes.length) return bytes[bytes.length - 1];
  return bytes[index];
}

int _clampByte(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

/// Camera YUV_420_888 is full-range BT.601 (JFIF), not the 16–235 video range.
(int, int, int) _yuvToRgb(int y, int u, int v) {
  final base = y << 8;
  final d = u - 128;
  final e = v - 128;
  return (
    _clampByte((base + 359 * e + 128) >> 8),
    _clampByte((base - 88 * d - 183 * e + 128) >> 8),
    _clampByte((base + 454 * d + 128) >> 8),
  );
}
