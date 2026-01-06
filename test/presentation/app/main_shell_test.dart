import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/main_shell.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('MainShell', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('has three navigation tabs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.items.length, 3);
    });

    testWidgets('starts with home tab selected', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.homeTabIndex);
    });

    testWidgets('has IndexedStack for tab content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('can switch to projects tab', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap projects tab
      await tester.tap(find.text('Проекты'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.projectsTabIndex);
    });

    testWidgets('can switch to favorites tab', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap favorites tab
      await tester.tap(find.text('Избранное'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.favoritesTabIndex);
    });

    testWidgets('has Scaffold widgets', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have multiple Scaffolds (shell + child screens)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(MainShell), findsNothing);
    });
  });
}
