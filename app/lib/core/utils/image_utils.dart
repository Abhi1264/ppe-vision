import 'dart:math' as math;

class ImageUtils {
  ImageUtils._();

  /// Destination rect for a cover-fit of [imageWidth]×[imageHeight] in a view.
  static ({double left, double top, double width, double height}) coverRect({
    required double viewWidth,
    required double viewHeight,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0 || viewWidth <= 0 || viewHeight <= 0) {
      return (left: 0, top: 0, width: viewWidth, height: viewHeight);
    }
    final scale = math.max(viewWidth / imageWidth, viewHeight / imageHeight);
    final width = imageWidth * scale;
    final height = imageHeight * scale;
    return (
      left: (viewWidth - width) / 2,
      top: (viewHeight - height) / 2,
      width: width,
      height: height,
    );
  }

  static ({double x, double y}) normalizedToPixel({
    required double nx,
    required double ny,
    required double width,
    required double height,
  }) {
    return (x: nx * width, y: ny * height);
  }

  static ({double x, double y}) pixelToNormalized({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    return (
      x: width == 0 ? 0.0 : x / width,
      y: height == 0 ? 0.0 : y / height,
    );
  }

  static ({double x, double y}) removeLetterbox({
    required double nx,
    required double ny,
    required double scale,
    required double padX,
    required double padY,
    required double modelWidth,
    required double modelHeight,
  }) {
    final x = (nx * modelWidth - padX) / scale;
    final y = (ny * modelHeight - padY) / scale;
    return (x: x, y: y);
  }
}
