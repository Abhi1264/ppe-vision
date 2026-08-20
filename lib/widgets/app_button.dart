import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants/app_constants.dart';

enum AppButtonVariant { filled, outlined, ghost, accent }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (expand)
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis))
        else
          Text(label),
      ],
    );

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(AppLayout.minTouchTarget, AppLayout.minTouchTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );

    final Color fill = switch (variant) {
      AppButtonVariant.accent => AppColors.highVis,
      _ => AppColors.ink,
    };
    final Color onFill = switch (variant) {
      AppButtonVariant.accent => AppColors.ink,
      _ => AppColors.paper,
    };

    final Widget button = switch (variant) {
      AppButtonVariant.filled || AppButtonVariant.accent => FilledButton(
        onPressed: onPressed,
        style: style.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.steel;
            return fill;
          }),
          foregroundColor: WidgetStatePropertyAll(onFill),
        ),
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style.copyWith(
          foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.buttonOutline),
          ),
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: style.copyWith(
          foregroundColor: const WidgetStatePropertyAll(AppColors.steel),
        ),
        child: child,
      ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
