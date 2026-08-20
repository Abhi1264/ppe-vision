import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: const SizedBox(
        width: AppLayout.brandMarkSize,
        height: AppLayout.brandMarkSize,
        child: CustomPaint(painter: HardHatMarkPainter()),
      ),
    );
  }
}

class HardHatMarkPainter extends CustomPainter {
  const HardHatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.highVis
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppLayout.overlayStrokePerson
      ..strokeJoin = StrokeJoin.round;

    final hat = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.18,
        size.width * 0.78,
        size.height * 0.52,
      )
      ..lineTo(size.width * 0.84, size.height * 0.52)
      ..lineTo(size.width * 0.84, size.height * 0.6)
      ..lineTo(size.width * 0.16, size.height * 0.6)
      ..lineTo(size.width * 0.16, size.height * 0.52)
      ..close();
    canvas.drawPath(hat, paint);

    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.66),
      Offset(size.width * 0.86, size.height * 0.66),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
