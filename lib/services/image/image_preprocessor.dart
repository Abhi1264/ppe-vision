import 'dart:typed_data';

import '../../models/frame_data.dart';
import '../../models/processed_image.dart';

/// Camera-frame preprocessing used by a future model backend.
///
/// Keep this independent of the TFLite interpreter. The model provider should
/// call an implementation here, then feed `ProcessedImage.rgbBytes` into
/// the interpreter.
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
    // TODO (model integration):
    // - YUV → RGB (or BGRA → RGB)
    // - rotation correction using frame.rotationDegrees
    // - cropping
    // - resizing
    // - letterboxing to [targetWidth] x [targetHeight]
    // - normalization
    //
    // Mock detection does not need pixel conversion. This returns a
    // dimension-preserving placeholder so the contract exists today.
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
