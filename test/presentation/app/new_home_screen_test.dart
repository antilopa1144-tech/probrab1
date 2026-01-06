import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/new_home_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('NewHomeScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('displays app title', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Probrab AI'), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays quick access section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Быстрый доступ'), findsOneWidget);
    });

    testWidgets('displays categories section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Категории'), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('search clear button appears when typing', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'краска');
      await tester.pump(const Duration(milliseconds: 300));

      // Clear button should appear
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('can clear search', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'краска');
      await tester.pump(const Duration(milliseconds: 300));

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('has favorites button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('displays calculator categories grid', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have GridView for categories
      expect(find.byType(GridView), findsAtLeastNWidgets(1));
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const NewHomeScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(NewHomeScreen), findsNothing);
    });
  });
}
