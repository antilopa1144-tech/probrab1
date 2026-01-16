import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_catalog_screen.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('CalculatorCatalogScreen', () {
    testWidgets('renders calculator catalog', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('has AppBar with title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders list of calculators', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should render ListView with calculator cards
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('search field shows clear button when has text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially no clear button
      expect(find.byIcon(Icons.clear_rounded), findsNothing);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump(const Duration(milliseconds: 300));

      // Clear button should appear
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('clear button clears search text', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'штукатурка');
      await tester.pump(const Duration(milliseconds: 300));

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      // Text should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '');
    });

    testWidgets('renders with subCategoryKey filter', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(
            subCategoryKey: 'subcategory.walls.plaster',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('shows no results message when search yields nothing', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter a search query that won't match anything
      await tester.enterText(find.byType(TextField), 'xyznonexistent12345');
      await tester.pump(const Duration(milliseconds: 300));

      // Should show "no results" message
      expect(find.text('Ничего не найдено'), findsOneWidget);
    });

    testWidgets('calculator cards have favorite toggle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // There should be favorite icons (star outline for non-favorites)
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);
    });

    testWidgets('tapping favorite toggles state', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the first favorite button and tap it
      final starButtons = find.byIcon(Icons.star_outline_rounded);
      if (starButtons.evaluate().isNotEmpty) {
        await tester.tap(starButtons.first);
        await tester.pump();

        // After tapping, there should be at least one filled star
        expect(find.byIcon(Icons.star_rounded), findsWidgets);
      }
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Replace with empty widget - should dispose without errors
      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(CalculatorCatalogScreen), findsNothing);
    });

    testWidgets('debounces search input', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();

      // Type quickly
      await tester.enterText(find.byType(TextField), 'п');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'пл');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'плитка');

      // Wait for debounce to complete
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });
  });

  group('CalculatorCatalogScreen with specific calculators', () {
    testWidgets('renders calculator list from registry', (tester) async {
      setTestViewportSize(tester);
      // Verify the registry has calculators
      expect(CalculatorRegistry.catalogCalculators.isNotEmpty, true);

      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('registry has expected calculators', (tester) async {
      setTestViewportSize(tester);
      final calculators = CalculatorRegistry.catalogCalculators;

      // Should have multiple calculators
      expect(calculators.length, greaterThan(5));

      // Check that some known calculator IDs exist
      expect(CalculatorRegistry.exists('mixes_plaster'), true);
      expect(CalculatorRegistry.exists('walls_wallpaper'), true);
    });
  });
}
