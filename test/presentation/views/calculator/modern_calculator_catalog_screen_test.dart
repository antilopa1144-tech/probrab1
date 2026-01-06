import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/calculator/modern_calculator_catalog_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ModernCalculatorCatalogScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ModernCalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('has category filter buttons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have category filter labels
      expect(find.text('category.all'), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(ModernCalculatorCatalogScreen), findsNothing);
    });

    testWidgets('search field is functional', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ModernCalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('has scrollable content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const ModernCalculatorCatalogScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have scrollable widgets (CustomScrollView)
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
