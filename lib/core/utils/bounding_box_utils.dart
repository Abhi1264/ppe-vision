import '../../models/detection.dart';

class BoundingBoxUtils {
  BoundingBoxUtils._();

  static double width(Detection box) => box.x2 - box.x1;
  static double height(Detection box) => box.y2 - box.y1;

  static double area(Detection box) {
    final w = width(box);
    final h = height(box);
    if (w <= 0 || h <= 0) return 0;
    return w * h;
  }

  static ({double x, double y}) center(Detection box) {
    return (x: box.centerX, y: box.centerY);
  }

  static double intersectionArea(Detection a, Detection b) {
    final xLeft = a.x1 > b.x1 ? a.x1 : b.x1;
    final yTop = a.y1 > b.y1 ? a.y1 : b.y1;
    final xRight = a.x2 < b.x2 ? a.x2 : b.x2;
    final yBottom = a.y2 < b.y2 ? a.y2 : b.y2;
    final w = xRight - xLeft;
    final h = yBottom - yTop;
    if (w <= 0 || h <= 0) return 0;
    return w * h;
  }

  static double calculateIoU(Detection a, Detection b) {
    final inter = intersectionArea(a, b);
    if (inter <= 0) return 0;
    final union = area(a) + area(b) - inter;
    if (union <= 0) return 0;
    return inter / union;
  }

  static bool isInside(Detection child, Detection parent, {double tolerance = 0.02}) {
    return child.x1 >= parent.x1 - tolerance &&
        child.y1 >= parent.y1 - tolerance &&
        child.x2 <= parent.x2 + tolerance &&
        child.y2 <= parent.y2 + tolerance;
  }

  static bool centerInside(Detection child, Detection parent) {
    final c = center(child);
    return c.x >= parent.x1 &&
        c.x <= parent.x2 &&
        c.y >= parent.y1 &&
        c.y <= parent.y2;
  }

  static double relativeCenterY(Detection child, Detection parent) {
    final parentHeight = height(parent);
    if (parentHeight <= 0) return 0;
    return (child.centerY - parent.y1) / parentHeight;
  }
}
