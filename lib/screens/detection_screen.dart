import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../core/constants/app_constants.dart';
import '../providers/detection_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/camera_view.dart';
import '../widgets/compliance_card.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/detection_session_binder.dart';
import '../widgets/detection_status_chip.dart';
import '../widgets/feedback_banners.dart';
import '../widgets/fps_indicator.dart';
import '../widgets/statistics_panel.dart';

class DetectionScreen extends ConsumerWidget {
  const DetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(detectionSessionProvider);
    final settings = ref.watch(settingsProvider);

    return Theme(
      data: AppTheme.detection(),
      child: DetectionSessionBinder(
        child: Scaffold(
          backgroundColor: AppColors.detectionBg,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const CameraView(),
              DetectionOverlay(
                detections: session.detections,
                people: session.compliance.people,
                showConfidence: settings.showConfidence,
                enabled: settings.showOverlay,
              ),
              DetectionHud(session: session),
              if (session.capturedFlash)
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 92),
                    child: CaptureToast(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetectionHud extends StatelessWidget {
  const DetectionHud({super.key, required this.session});

  final DetectionSessionState session;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          DetectionTopBar(
            onSettings: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
          const DetectionFpsBar(),
          if (session.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: MessageBanner(text: session.errorMessage!),
            ),
          const Spacer(),
          DetectionBottomPanel(session: session),
        ],
      ),
    );
  }
}

class DetectionTopBar extends StatelessWidget {
  const DetectionTopBar({super.key, this.onSettings});

  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.xs, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: color,
          ),
          Expanded(
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSettings != null)
            IconButton(
              tooltip: AppStrings.settings,
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
              color: color,
            ),
        ],
      ),
    );
  }
}

class DetectionFpsBar extends ConsumerWidget {
  const DetectionFpsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(detectionSessionProvider);
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FpsIndicator(
          fps: session.fps,
          inferenceTime: session.inferenceTime,
          showFps: settings.showFps,
          showInferenceTime: settings.showInferenceTime,
        ),
      ),
    );
  }
}

class DetectionBottomPanel extends ConsumerWidget {
  const DetectionBottomPanel({super.key, required this.session});

  final DetectionSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = session.compliance.statistics;
    return ColoredBox(
      color: AppColors.panel,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.panelBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              14,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${stats.peopleCount} ${AppStrings.peopleDetectedSuffix}',
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StatisticsPanel(statistics: stats),
                const SizedBox(height: AppSpacing.md),
                ComplianceCard(result: session.compliance),
                const SizedBox(height: AppSpacing.md),
                DetectionStatusChip(
                  active: session.isDetecting,
                  label: session.statusMessage,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: AppStrings.capture,
                  icon: Icons.camera_outlined,
                  variant: AppButtonVariant.accent,
                  onPressed: session.canCapture
                      ? () => ref.read(detectionSessionProvider.notifier).capture()
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
