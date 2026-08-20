import 'dart:typed_data';

enum FrameFormat { yuv420, bgra8888, unknown }

class FramePlane {
  const FramePlane({
    required this.bytes,
    required this.bytesPerRow,
  });

  final Uint8List bytes;
  final int bytesPerRow;
}

/// Camera-agnostic frame payload consumed by detection providers.
class FrameData {
  const FrameData({
    required this.width,
    required this.height,
    required this.timestamp,
    this.rotationDegrees = 0,
    this.format = FrameFormat.unknown,
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
  final List<FramePlane> planes;

  bool get hasPixelData => planes.isNotEmpty;
}
