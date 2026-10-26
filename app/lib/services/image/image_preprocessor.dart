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
    return Future<ProcessedImage>.value(_process(frame));
  }

  ProcessedImage _process(FrameData frame) {
    if (!frame.hasPixelData || frame.width <= 0 || frame.height <= 0) {
      throw const InvalidFrameException();
    }
    final upright = uprightFrameSize(frame);
    if (upright.width <= 0 || upright.height <= 0) {
      throw const InvalidFrameException();
    }

    final scale = math.min(
      targetWidth / upright.width,
      targetHeight / upright.height,
    );
    if (scale <= 0) throw const InvalidFrameException();

    final resizedW = (upright.width * scale).round();
    final resizedH = (upright.height * scale).round();
    final padX = (targetWidth - resizedW) / 2;
    final padY = (targetHeight - resizedH) / 2;

    final rgb = Uint8List(targetWidth * targetHeight * 3);
    // YOLO letterbox pad.
    rgb.fillRange(0, rgb.length, 114);

    final x0 = padX.floor().clamp(0, targetWidth);
    final y0 = padY.floor().clamp(0, targetHeight);
    final x1 = (padX + resizedW).ceil().clamp(0, targetWidth);
    final y1 = (padY + resizedH).ceil().clamp(0, targetHeight);

    for (var my = y0; my < y1; my++) {
      for (var mx = x0; mx < x1; mx++) {
        // ponytail: nearest-neighbor sample; bilinear if box edges look soft
        final ux = ((mx - padX) / scale).round();
        final uy = ((my - padY) / scale).round();
        if (ux < 0 || uy < 0 || ux >= upright.width || uy >= upright.height) {
          continue;
        }
        final sensor = _sensorPoint(frame, ux, uy, upright.width);
        final rgbPixel = _sample(frame, sensor.$1, sensor.$2);
        final dst = (my * targetWidth + mx) * 3;
        rgb[dst] = rgbPixel.$1;
        rgb[dst + 1] = rgbPixel.$2;
        rgb[dst + 2] = rgbPixel.$3;
      }
    }

    return ProcessedImage(
      width: targetWidth,
      height: targetHeight,
      rgbBytes: rgb,
      letterboxScale: scale,
      padX: padX,
      padY: padY,
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
      FrameFormat.unknown => throw const InvalidFrameException(
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

(int, int, int) _yuvToRgb(int y, int u, int v) {
  final c = y - 16;
  final d = u - 128;
  final e = v - 128;
  return (
    _clampByte((298 * c + 409 * e + 128) >> 8),
    _clampByte((298 * c - 100 * d - 208 * e + 128) >> 8),
    _clampByte((298 * c + 516 * d + 128) >> 8),
  );
}
