import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';
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
                width: previewSize.width,
                height: previewSize.height,
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
      painter: SitePreviewPainter(),
      child: SizedBox.expand(),
    );
  }
}

class SitePreviewPainter extends CustomPainter {
  const SitePreviewPainter();

  static const _gridStep = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.detectionBg);

    final grid = Paint()
      ..color = AppColors.previewGrid
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += _gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += _gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final ground = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, Paint()..color = AppColors.previewGround);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.22,
        size.width * 0.76,
        size.height * 0.4,
      ),
      Paint()
        ..color = AppColors.previewStructure
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final label = TextPainter(
      text: const TextSpan(
        text: AppStrings.demoPreview,
        style: TextStyle(
          color: AppColors.previewLabel,
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
