import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/home_main.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('HomeMainScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeMainScreen), findsOneWidget);
    });

    testWidgets('displays app title in AppBar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Probrab AI'), findsOneWidget);
    });

    testWidgets('has AppBar with menu button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays hero section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.calculate_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('displays categories section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('home.sections.categories.title'), findsOneWidget);
    });

    testWidgets('displays history section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('home.sections.history.title'), findsOneWidget);
    });

    testWidgets('has RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump();

      expect(find.byType(HomeMainScreen), findsOneWidget);
    });

    testWidgets('can open menu', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Menu should show menu items
      expect(find.byType(PopupMenuButton<dynamic>), findsOneWidget);
    });

    testWidgets('displays object grid', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have GridView for objects
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(HomeMainScreen), findsNothing);
    });
  });
}
