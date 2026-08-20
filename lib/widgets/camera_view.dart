import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../providers/camera_provider.dart';
import '../providers/detection_provider.dart';

class CameraView extends ConsumerWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(detectionSessionProvider);
    final camera = ref.watch(cameraServiceProvider);
    final preview = camera.buildPreview();

    if (session.usingFallbackPreview || preview == null) {
      return const FallbackCameraBackground();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = camera.previewSize;
        final child = previewSize == null
            ? preview
            : SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: preview,
              );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
        );
      },
    );
  }
}

class FallbackCameraBackground extends StatelessWidget {
  const FallbackCameraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _SitePreviewPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _SitePreviewPainter extends CustomPainter {
  const _SitePreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.detectionBg;
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFF24303A)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final horizon = Paint()
      ..color = const Color(0xFF3A4A38)
      ..style = PaintingStyle.fill;
    final ground = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, horizon);

    final structure = Paint()
      ..color = const Color(0xFF2C343C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.22,
        size.width * 0.76,
        size.height * 0.4,
      ),
      structure,
    );

    final label = TextPainter(
      text: const TextSpan(
        text: 'DEMO PREVIEW',
        style: TextStyle(
          color: Color(0x66E8EEF2),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset((size.width - label.width) / 2, size.height * 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
