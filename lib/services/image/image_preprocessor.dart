import 'dart:typed_data';

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
  Future<ProcessedImage> process(FrameData frame) async {
    // TODO: YUV/BGRA → RGB, rotate, letterbox, normalize.
    return ProcessedImage(
      width: frame.width,
      height: frame.height,
      rgbBytes: Uint8List(0),
      letterboxScale: 1,
      padX: 0,
      padY: 0,
    );
  }
}
