import 'dart:typed_data';

enum FrameFormat { yuv420, bgra8888, rgba8888, unknown }

class FramePlane {
  const FramePlane({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel = 1,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
}

class FrameData {
  const FrameData({
    required this.width,
    required this.height,
    required this.timestamp,
    this.rotationDegrees = 0,
    this.format = FrameFormat.unknown,
    this.mirrored = false,
    this.planes = const [],
  });

  factory FrameData.synthetic({
    int width = 1280,
    int height = 720,
    DateTime? timestamp,
  }) {
    return FrameData(
      width: width,
      height: height,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  final int width;
  final int height;
  final DateTime timestamp;
  final int rotationDegrees;
  final FrameFormat format;

  /// Front-camera preview is mirrored. Pixel buffers are not.
  final bool mirrored;
  final List<FramePlane> planes;

  bool get hasPixelData => planes.isNotEmpty;
}
