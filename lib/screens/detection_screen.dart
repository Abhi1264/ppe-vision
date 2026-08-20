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
import '../widgets/detection_status_chip.dart';
import '../widgets/fps_indicator.dart';
import '../widgets/statistics_panel.dart';

class DetectionScreen extends ConsumerStatefulWidget {
  const DetectionScreen({super.key});

  @override
  ConsumerState<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends ConsumerState<DetectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(detectionSessionProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(detectionSessionProvider);
    final settings = ref.watch(settingsProvider);

    return Theme(
      data: AppTheme.detection(),
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            ref.read(detectionSessionProvider.notifier).stop();
          }
        },
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
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    onSettings: () {
                      Navigator.of(context).pushNamed(AppRoutes.settings);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FpsIndicator(
                        fps: session.fps,
                        inferenceTime: session.inferenceTime,
                        showFps: settings.showFps,
                        showInferenceTime: settings.showInferenceTime,
                      ),
                    ),
                  ),
                  if (session.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _MessageBanner(text: session.errorMessage!),
                    ),
                  const Spacer(),
                  _BottomPanel(session: session),
                ],
              ),
            ),
            if (session.capturedFlash)
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 92),
                  child: _CaptureToast(),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.paper,
          ),
          const Expanded(
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                color: AppColors.paper,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.paper,
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends ConsumerWidget {
  const _BottomPanel({required this.session});

  final DetectionSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.panelBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${session.compliance.statistics.peopleCount} People Detected',
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatisticsPanel(statistics: session.compliance.statistics),
              const SizedBox(height: 12),
              ComplianceCard(result: session.compliance),
              const SizedBox(height: 12),
              DetectionStatusChip(
                active: session.isDetecting,
                label: session.statusMessage ??
                    (session.isDetecting ? 'Detection active' : 'Detection idle'),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Capture',
                icon: Icons.camera_outlined,
                variant: AppButtonVariant.accent,
                onPressed: session.latestFrame == null
                    ? null
                    : () => ref.read(detectionSessionProvider.notifier).capture(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC2A1E16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.safetyOrange.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF0D9C4),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}

class _CaptureToast extends StatelessWidget {
  const _CaptureToast();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.highVis.withValues(alpha: 0.7)),
        ),
        child: const Text(
          'Saved to detection history',
          style: TextStyle(
            color: AppColors.paper,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
