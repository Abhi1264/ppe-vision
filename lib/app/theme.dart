import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const ink = Color(0xFF171C22);
  static const steel = Color(0xFF2A323C);
  static const mist = Color(0xFFE6EBEF);
  static const paper = Color(0xFFF3F5F7);
  static const highVis = Color(0xFFC99612);
  static const highVisDark = Color(0xFF8C6A0A);
  static const safetyOrange = Color(0xFFC45C1A);
  static const compliant = Color(0xFF2C8A5E);
  static const violation = Color(0xFFC2473C);
  static const helmet = Color(0xFFE2C24A);
  static const vest = Color(0xFFE07A2F);
  static const personStroke = Color(0xFFE8EEF2);
  static const detectionBg = Color(0xFF101418);
  static const panel = Color(0xE61C2228);
  static const panelBorder = Color(0xFF3A434D);
  static const muted = Color(0xFF6B7580);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.highVis,
      onSecondary: AppColors.ink,
      error: AppColors.violation,
      onError: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      tertiary: AppColors.steel,
      onTertiary: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.mist,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mist,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD5DCE3)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.highVisDark,
        thumbColor: AppColors.highVisDark,
        overlayColor: AppColors.highVis.withValues(alpha: 0.16),
      ),
      dividerColor: const Color(0xFFD5DCE3),
    );
  }

  static ThemeData detection() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.highVis,
      onPrimary: AppColors.ink,
      secondary: AppColors.steel,
      onSecondary: AppColors.paper,
      error: AppColors.violation,
      onError: Colors.white,
      surface: AppColors.detectionBg,
      onSurface: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.detectionBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.paper,
        elevation: 0,
      ),
    );
  }
}
