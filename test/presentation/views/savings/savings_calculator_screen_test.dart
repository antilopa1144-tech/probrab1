import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/savings/savings_calculator_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('SavingsCalculatorScreen', () {
    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.text('Калькулятор экономии'), findsOneWidget);
    });

    testWidgets('shows input data card', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.text('Входные данные'), findsOneWidget);
    });

    testWidgets('shows labor cost input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.text('Стоимость работы мастеров (₽)'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('shows time input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.text('Время самостоятельной работы (часы)'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows hourly rate input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.textContaining('Ваша почасовая ставка'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('scrollable content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows calculation result after input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      // Enter labor cost
      final laborField = find.widgetWithText(TextField, 'Стоимость работы мастеров (₽)');
      await tester.enterText(laborField, '10000');
      await tester.pump();

      // Enter time
      final timeField = find.widgetWithText(TextField, 'Время самостоятельной работы (часы)');
      await tester.enterText(timeField, '8');
      await tester.pump();

      // Should show result
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows green result for worthwhile DIY', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      // Enter values that make DIY worthwhile
      final laborField = find.widgetWithText(TextField, 'Стоимость работы мастеров (₽)');
      await tester.enterText(laborField, '50000');
      await tester.pump();

      final timeField = find.widgetWithText(TextField, 'Время самостоятельной работы (часы)');
      await tester.enterText(timeField, '10');
      await tester.pump();

      // Hourly rate is 0 by default, so DIY is worthwhile
      expect(find.text('Выгодно делать самостоятельно'), findsOneWidget);
    });

    testWidgets('shows orange result when masters recommended', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      // Enter values with high hourly rate
      final laborField = find.widgetWithText(TextField, 'Стоимость работы мастеров (₽)');
      await tester.enterText(laborField, '5000');
      await tester.pump();

      final timeField = find.widgetWithText(TextField, 'Время самостоятельной работы (часы)');
      await tester.enterText(timeField, '100');
      await tester.pump();

      final hourlyField = find.widgetWithText(TextField, 'Ваша почасовая ставка (₽/час, 0 = не учитывать)');
      await tester.enterText(hourlyField, '1000');
      await tester.pump();

      // With high time cost, masters are recommended
      expect(find.text('Рекомендуется нанять мастеров'), findsOneWidget);
    });

    testWidgets('uses Card for input section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('has 3 text fields', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SavingsCalculatorScreen(
            workType: 'покраска',
            materialCost: 5000.0,
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(3));
    });
  });
}
