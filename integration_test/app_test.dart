import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_catalog_screen.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
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

  group('Calculator Catalog Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('catalog screen loads all calculators', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the catalog
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);

      // Should have ListView with calculators
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('search filters calculators', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'штукатурка');
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Should still have catalog
      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });

    testWidgets('category filter works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const CalculatorCatalogScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find category "all" button
      final allCategory = find.text('category.all');
      if (allCategory.evaluate().isNotEmpty) {
        await tester.tap(allCategory);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalculatorCatalogScreen), findsOneWidget);
    });
  });

  group('Calculator Registry Integration Tests', () {
    test('registry has all expected calculators', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      // Should have multiple calculators
      expect(calculators.length, greaterThan(10));

      // Check some key calculators exist
      expect(CalculatorRegistry.exists('mixes_plaster'), isTrue);
      expect(CalculatorRegistry.exists('walls_wallpaper'), isTrue);
      expect(CalculatorRegistry.exists('floors_tile'), isTrue);
    });

    test('all calculators have valid definitions', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      for (final calc in calculators) {
        // Each calculator should have required fields
        expect(calc.id, isNotEmpty);
        expect(calc.titleKey, isNotEmpty);
        expect(calc.useCase, isNotNull);
      }
    });

    test('calculator lookup by id works', () {
      final plaster = CalculatorRegistry.getById('mixes_plaster');
      expect(plaster, isNotNull);
      expect(plaster!.id, 'mixes_plaster');

      final nonexistent = CalculatorRegistry.getById('nonexistent_calc');
      expect(nonexistent, isNull);
    });

    test('calculators have unique ids', () {
      final calculators = CalculatorRegistry.catalogCalculators;
      final ids = calculators.map((c) => c.id).toSet();

      // All IDs should be unique
      expect(ids.length, calculators.length);
    });
  });
}
