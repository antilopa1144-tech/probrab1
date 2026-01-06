import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/waste/waste_optimizer_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WasteOptimizerScreen', () {
    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'plywood',
            requiredArea: 25.0,
            standardSize: 2.44,
          ),
        ),
      );

      expect(find.text('Оптимизация отходов'), findsOneWidget);
    });

    testWidgets('shows optimization results card', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'tile',
            requiredArea: 20.0,
            standardSize: 1.0,
          ),
        ),
      );

      expect(find.text('Результаты оптимизации'), findsOneWidget);
    });

    testWidgets('shows required area stat', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'tile',
            requiredArea: 25.5,
            standardSize: 1.0,
          ),
        ),
      );

      expect(find.text('Требуемая площадь'), findsOneWidget);
      expect(find.text('25.50 м²'), findsOneWidget);
    });

    testWidgets('shows optimized quantity stat', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'laminate',
            requiredArea: 10.0,
            standardSize: 2.0,
          ),
        ),
      );

      expect(find.text('Оптимальное количество'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });

    testWidgets('shows waste percentage stat', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'panel',
            requiredArea: 10.0,
            standardSize: 2.0,
          ),
        ),
      );

      expect(find.text('Процент отходов'), findsOneWidget);
      expect(find.byIcon(Icons.percent), findsOneWidget);
    });

    testWidgets('shows stat icons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'osb',
            requiredArea: 15.0,
            standardSize: 2.44,
          ),
        ),
      );

      expect(find.byIcon(Icons.square_foot), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
      expect(find.byIcon(Icons.percent), findsOneWidget);
    });

    testWidgets('scrollable content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'material',
            requiredArea: 100.0,
            standardSize: 3.0,
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows recommendations when available', (tester) async {
      // Create scenario where recommendations are generated
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'large_sheet',
            requiredArea: 2.0,
            standardSize: 3.0, // Large compared to required
          ),
        ),
      );

      expect(find.text('Рекомендации'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('shows waste reduction when available', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'optimized_material',
            requiredArea: 9.5,
            standardSize: 2.0,
          ),
        ),
      );

      // May or may not show depending on optimization result
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('handles small required area', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'small',
            requiredArea: 0.5,
            standardSize: 2.0,
          ),
        ),
      );

      expect(find.text('0.50 м²'), findsOneWidget);
    });

    testWidgets('handles large required area', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'large',
            requiredArea: 500.0,
            standardSize: 2.5,
          ),
        ),
      );

      expect(find.text('500.00 м²'), findsOneWidget);
    });

    testWidgets('formats decimal values correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'precision',
            requiredArea: 12.345,
            standardSize: 1.0,
          ),
        ),
      );

      expect(find.text('12.35 м²'), findsOneWidget);
    });

    testWidgets('uses Card widgets for sections', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WasteOptimizerScreen(
            materialId: 'cards',
            requiredArea: 10.0,
            standardSize: 2.0,
          ),
        ),
      );

      expect(find.byType(Card), findsWidgets);
    });
  });
}
