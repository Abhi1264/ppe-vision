import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(settingsProvider.select((s) => s.backend));

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 520
                ? 480.0
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Mark(),
                            SizedBox(height: 28),
                            Text(
                              'SITE SAFETY MONITOR',
                              style: TextStyle(
                                color: AppColors.highVisDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              AppConstants.appSubtitle,
                              style: TextStyle(
                                color: AppColors.steel,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              AppConstants.appDescription,
                              style: TextStyle(
                                color: Color(0xFF4A5560),
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: 28),
                            AppButton(
                              label: 'Start Detection',
                              icon: Icons.videocam_outlined,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.detection);
                              },
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: 'Detection History',
                              variant: AppButtonVariant.outlined,
                              icon: Icons.history,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.history);
                              },
                            ),
                            const SizedBox(height: 4),
                            AppButton(
                              label: 'Settings',
                              variant: AppButtonVariant.ghost,
                              icon: Icons.tune,
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.settings);
                              },
                            ),
                            const SizedBox(height: 12),
                            _ModeBadge(
                              label: backend == DetectionBackend.mock
                                  ? 'Mock detections · no model required'
                                  : 'Model provider selected',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const CustomPaint(painter: _HardHatMarkPainter()),
    );
  }
}

class _HardHatMarkPainter extends CustomPainter {
  const _HardHatMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.highVis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
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

    final brim = Paint()
      ..color = AppColors.highVis
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.66),
      Offset(size.width * 0.86, size.height * 0.66),
      brim,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE6C8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9C784)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF5C4A12),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
