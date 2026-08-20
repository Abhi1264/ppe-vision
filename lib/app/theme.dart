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
  static const hairline = Color(0xFFD5DCE3);
  static const body = Color(0xFF4A5560);
  static const bodySecondary = Color(0xFF5A646E);
  static const badgeFill = Color(0xFFEFE6C8);
  static const badgeBorder = Color(0xFFD9C784);
  static const badgeText = Color(0xFF5C4A12);
  static const bannerFill = Color(0xCC2A1E16);
  static const bannerText = Color(0xFFF0D9C4);
  static const overlayLabel = Color(0xFF101418);
  static const hudText = Color(0xFFE4E9EE);
  static const fpsScrim = Color(0xCC101418);
  static const fpsText = Color(0xFFE8EEF2);
  static const statValue = Color(0xFFF2F5F7);
  static const statLabel = Color(0xFF8B959E);
  static const buttonOutline = Color(0xFFC5CED6);
  static const previewGrid = Color(0xFF24303A);
  static const previewGround = Color(0xFF3A4A38);
  static const previewStructure = Color(0xFF2C343C);
  static const previewLabel = Color(0x66E8EEF2);
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
      outline: AppColors.hairline,
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
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.highVisDark,
        thumbColor: AppColors.highVisDark,
        overlayColor: AppColors.highVis.withValues(alpha: 0.16),
      ),
      dividerColor: AppColors.hairline,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.8,
        ),
        titleMedium: TextStyle(
          color: AppColors.steel,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: AppColors.body,
          fontSize: 15,
          height: 1.45,
        ),
        labelSmall: TextStyle(
          color: AppColors.highVisDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
        ),
      ),
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
      outline: AppColors.panelBorder,
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
