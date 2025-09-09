import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:compressor/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app with light theme for testing
    await tester.pumpWidget(const ConvertApp(initialThemeId: "light"));

    // Verify that app title is visible
    expect(find.text('Compressor'), findsOneWidget);

    // Verify theme switcher button exists
    expect(find.byIcon(Icons.settings_brightness), findsOneWidget);
  });

  testWidgets('Theme switching works', (WidgetTester tester) async {
    // Build with light theme
    await tester.pumpWidget(const ConvertApp(initialThemeId: "light"));

    // Tap theme switcher
    await tester.tap(find.byIcon(Icons.settings_brightness));
    await tester.pump();

    // Verify theme changed (пример проверки через цвет AppBar)
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, equals(Colors.blueGrey));
  });
}