import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ppe_vision/app/app.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  testWidgets('home screen shows primary actions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PpeVisionApp()));

    expect(find.text('PPE Vision'), findsWidgets);
    expect(find.text('Helmet & Safety Vest Detection'), findsOneWidget);
    expect(find.text('Start Detection'), findsOneWidget);
    expect(find.text('Detection History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('detection screen runs mock detections in demo mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PpeVisionApp()));
    await tester.tap(find.text('Start Detection'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('People Detected'), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);
  });
}
