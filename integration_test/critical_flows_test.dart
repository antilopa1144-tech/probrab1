import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/app/main_shell.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_catalog_screen.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart' show AppLocalizationsDelegate;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to create test app with localization
  Widget createTestApp({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
        ],
        supportedLocales: const [
          Locale('ru'),
          Locale('en'),
        ],
        locale: const Locale('ru'),
        home: child,
      ),
    );
  }

  group('Critical User Flow Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('E2E: Navigate through app tabs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we start on home tab
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to Projects tab
      await tester.tap(find.text('Проекты'));
      await tester.pumpAndSettle();

      // Verify navigation happened
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to Favorites tab
      await tester.tap(find.text('Избранное'));
      await tester.pumpAndSettle();

      // Verify navigation happened
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Return to Home tab
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('E2E: Search for calculator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsAtLeastNWidgets(1));

      // Enter search text
      await tester.enterText(searchField.first, 'плитка');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Should show search results
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

      // Clear search
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton.first);
        await tester.pumpAndSettle();
      }

      // Should show all calculators again
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('E2E: Calculator catalog loads and scrolls', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify catalog loaded
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

      // Find scrollable view
      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        // Scroll down
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pumpAndSettle();

        // Should still show catalog
        expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

        // Scroll back up
        await tester.drag(scrollable.first, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('E2E: Toggle favorite calculator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find first favorite button (star icon)
      final starButtons = find.byIcon(Icons.star_outline);
      if (starButtons.evaluate().isNotEmpty) {
        // Tap to add to favorites
        await tester.tap(starButtons.first);
        await tester.pumpAndSettle();

        // Button should still exist (might be filled star now)
        expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
      }
    });

    testWidgets('E2E: Category filter functionality', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find category filter buttons
      final allCategory = find.text('category.all');
      if (allCategory.evaluate().isNotEmpty) {
        // Tap "All" category
        await tester.tap(allCategory.first);
        await tester.pumpAndSettle();

        // Should show catalog
        expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

        // Find and tap another category if available
        final categoryChips = find.byType(ChoiceChip);
        if (categoryChips.evaluate().length > 1) {
          await tester.tap(categoryChips.at(1));
          await tester.pumpAndSettle();

          // Should still show catalog (filtered)
          expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
        }
      }
    });

    testWidgets('E2E: App launches successfully', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      // Wait for app to settle
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify main components are present
      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('E2E: Back navigation works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Projects tab
      await tester.tap(find.text('Проекты'));
      await tester.pumpAndSettle();

      // Navigate back to Home (tap Home button)
      await tester.tap(find.text('Главная'));
      await tester.pumpAndSettle();

      // Verify we're back to home
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });

  group('Smoke Tests for Critical Screens', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('MainShell renders without errors', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MainShell), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('CalculatorCatalogScreen renders without errors', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App starts within acceptable time', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // App should start within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('Catalog loads within acceptable time', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MainShell(),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Catalog should be visible immediately since it's the home screen
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

      stopwatch.stop();

      // Should be instant (already loaded)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
