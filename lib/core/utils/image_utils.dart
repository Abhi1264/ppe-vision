class ImageUtils {
  ImageUtils._();

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

  /// Maps a point from letterboxed model space back to normalized image space.
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
