import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../models/detection.dart';
import '../models/person_detection.dart';
import 'detection_box.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.detections,
    this.people = const [],
    this.showConfidence = true,
    this.enabled = true,
  });

  final List<Detection> detections;
  final List<PersonDetection> people;
  final bool showConfidence;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.expand();
    return CustomPaint(
      painter: DetectionOverlayPainter(
        detections: detections,
        people: people,
        showConfidence: showConfidence,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class DetectionOverlayPainter extends CustomPainter {
  const DetectionOverlayPainter({
    required this.detections,
    required this.people,
    required this.showConfidence,
  });

  final List<Detection> detections;
  final List<PersonDetection> people;
  final bool showConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      _paintDetection(canvas, size, detection);
    }
  }

  void _paintDetection(Canvas canvas, Size size, Detection detection) {
    final rect = Rect.fromLTRB(
      detection.x1 * size.width,
      detection.y1 * size.height,
      detection.x2 * size.width,
      detection.y2 * size.height,
    );
    if (rect.width <= 1 || rect.height <= 1) return;

    final bool? compliant = detection.classType == DetectionClass.person
        ? _complianceFor(detection)
        : null;
    final color = DetectionBoxStyle.colorFor(
      detection.classType,
      compliant: compliant,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = DetectionBoxStyle.strokeFor(detection.classType);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AppLayout.overlayCorner),
      ),
      paint,
    );
    _paintLabel(canvas, size, rect, detection, color);
  }

  void _paintLabel(
    Canvas canvas,
    Size size,
    Rect rect,
    Detection detection,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: DetectionBoxStyle.caption(
          detection,
          showConfidence: showConfidence,
        ),
        style: const TextStyle(
          color: AppColors.overlayLabel,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width);

    const padH = AppLayout.overlayLabelPadH;
    const padV = AppLayout.overlayLabelPadV;
    final labelHeight = textPainter.height + padV * 2;
    final labelTop = rect.top - labelHeight >= 0
        ? rect.top - labelHeight
        : rect.top;
    final labelRect = Rect.fromLTWH(
      rect.left,
      labelTop,
      (textPainter.width + padH * 2).clamp(0, size.width - rect.left),
      labelHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
      Paint()..color = color,
    );
    textPainter.paint(canvas, Offset(labelRect.left + padH, labelRect.top + padV));
  }

  bool? _complianceFor(Detection person) {
    for (final item in people) {
      if (item.person == person) return item.isCompliant;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.people != people ||
        oldDelegate.showConfidence != showConfidence;
  }
}
