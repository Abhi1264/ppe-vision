import 'package:flutter/material.dart';

import '../screens/detection_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import 'routes.dart';
import 'theme.dart';

class PpeVisionApp extends StatelessWidget {
  const PpeVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PPE Vision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.detection: (_) => const DetectionScreen(),
        AppRoutes.history: (_) => const HistoryScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
