import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wirapath/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set window size to standard phone resolution to prevent layout overflows
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: WirapathApp(),
      ),
    );
    await tester.pump();

    // Splash screen should show the logo images
    expect(find.byType(Image), findsNWidgets(2));

    // Fast-forward the virtual time to trigger and complete all delayed timers
    // in SplashPage (300ms + 2500ms + 1100ms = 3900ms) to ensure they are disposed.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
