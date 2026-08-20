import 'dart:typed_data';

class ProcessedImage {
  const ProcessedImage({
    required this.width,
    required this.height,
    required this.rgbBytes,
    this.letterboxScale = 1,
    this.padX = 0,
    this.padY = 0,
  });

  final int width;
  final int height;
  final Uint8List rgbBytes;
  final double letterboxScale;
  final double padX;
  final double padY;
}
