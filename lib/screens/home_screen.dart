import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/brand_mark.dart';
import '../widgets/mode_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(settingsProvider.select((s) => s.backend));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > AppLayout.contentBreakpoint
                ? AppLayout.contentMaxWidth
                : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BrandMark(),
                            const SizedBox(height: AppSpacing.hero),
                            Text(
                              AppStrings.siteEyebrow,
                              style: textTheme.labelSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              AppConstants.appName,
                              style: textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppConstants.appSubtitle,
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              AppConstants.appDescription,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(height: AppSpacing.hero),
                            AppButton(
                              label: AppStrings.startDetection,
                              icon: Icons.videocam_outlined,
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.detection),
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              label: AppStrings.detectionHistory,
                              variant: AppButtonVariant.outlined,
                              icon: Icons.history,
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.history),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppButton(
                              label: AppStrings.settings,
                              variant: AppButtonVariant.ghost,
                              icon: Icons.tune,
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.settings),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ModeBadge(
                              label: switch (backend) {
                                DetectionBackend.mock =>
                                  AppStrings.mockModeBadge,
                                DetectionBackend.model =>
                                  AppStrings.modelModeBadge,
                              },
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
