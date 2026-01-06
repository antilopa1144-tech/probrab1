import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/labor/labor_cost_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('LaborCostScreen', () {
    setUp(() {
      setupMocks();
    });

    Widget createWidget({
      String calculatorId = 'test_calculator',
      double quantity = 50.0,
    }) {
      return createTestApp(
        child: LaborCostScreen(
          calculatorId: calculatorId,
          quantity: quantity,
        ),
      );
    }

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Расчёт трудозатрат'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders region dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Регион'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows calculation results', (tester) async {
      await tester.pumpWidget(createWidget(quantity: 100.0));
      await tester.pumpAndSettle();

      expect(find.text('Расчёт'), findsOneWidget);
      expect(find.text('Объём работ'), findsOneWidget);
      expect(find.text('Оценка времени'), findsOneWidget);
      expect(find.text('Оценка дней'), findsOneWidget);
    });

    testWidgets('displays quantity in results', (tester) async {
      await tester.pumpWidget(createWidget(quantity: 50.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('50.00'), findsOneWidget);
    });

    testWidgets('shows information card', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Информация'), findsOneWidget);
      expect(
        find.textContaining(
          'Расчёт основан на средних нормах времени',
        ),
        findsOneWidget,
      );
    });

    testWidgets('has info icon', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('can change region via dropdown', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find dropdown
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show region options
      expect(find.text('Москва').hitTestable(), findsWidgets);
      expect(find.text('Санкт‑Петербург').hitTestable(), findsWidgets);
      expect(find.text('Екатеринбург').hitTestable(), findsWidgets);
      expect(find.text('Краснодар').hitTestable(), findsWidgets);
      expect(find.text('Регионы РФ').hitTestable(), findsWidgets);
    });

    testWidgets('renders cards', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should have 3 cards: region selection, results, and information
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('renders dividers in results', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('renders scrollable content', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('displays results with proper formatting', (tester) async {
      await tester.pumpWidget(createWidget(quantity: 100.5));
      await tester.pumpAndSettle();

      // Check quantity formatting
      expect(find.textContaining('100.50'), findsOneWidget);

      // Check that hours and days are displayed
      expect(find.textContaining('часов'), findsOneWidget);
      expect(find.textContaining('дней'), findsWidgets);
    });

    testWidgets('updates calculation when quantity changes', (tester) async {
      await tester.pumpWidget(createWidget(quantity: 50.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('50.00'), findsOneWidget);

      // Rebuild with new quantity
      await tester.pumpWidget(createWidget(quantity: 150.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('150.00'), findsOneWidget);
    });
  });
}
