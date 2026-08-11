import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wirapath/core/theme/app_theme.dart';
import 'package:wirapath/features/simulation/presentation/pages/career_simulation_page.dart';

void main() {
  testWidgets('CareerSimulationPage renders jobdesk analyzer state without errors', (WidgetTester tester) async {
    // Set window size to ensure off-screen list elements are laid out
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CareerSimulationPage(),
        ),
      ),
    );
    
    // Tap on the Jobdesk Analyzer card to switch to SimulationState.jobdeskAnalyzer
    final cardFinder = find.text('Jobdesk Analyzer');
    expect(cardFinder, findsOneWidget);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();
    
    // Check if the chat bubble is found
    expect(find.textContaining('I found several job listings'), findsOneWidget);
    
    // Check if the search bar hint text is found
    expect(find.textContaining('Enter custom job'), findsOneWidget);
    
    // Check if the Gojek job card is found
    expect(find.textContaining('Gojek'), findsOneWidget);
  });
}
