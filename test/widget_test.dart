// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:probrab_ai/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProbuilderApp()));

    // Use pump() with a duration instead of pumpAndSettle() to avoid timeout
    await tester.pump(const Duration(seconds: 1));

    // Проверяем что AppBar отображается
    expect(find.byType(AppBar), findsOneWidget);
    // Проверяем что есть поле поиска
    expect(find.byType(TextField), findsWidgets);
  });
}
