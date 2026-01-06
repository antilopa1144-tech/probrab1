import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/material_repository.dart';
import 'package:probrab_ai/domain/entities/material_comparison.dart';
import 'package:probrab_ai/presentation/views/material/material_comparison_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MaterialComparisonScreen', () {
    setUp(() {
      setupMocks();
    });

    final mockOptions = [
      const MaterialOption(
        id: 'opt1',
        name: 'Материал 1',
        category: 'test_category',
        unit: 'м²',
        pricePerUnit: 100,
        durabilityYears: 10,
      ),
      const MaterialOption(
        id: 'opt2',
        name: 'Материал 2',
        category: 'test_category',
        unit: 'м²',
        pricePerUnit: 150,
        durabilityYears: 15,
      ),
      const MaterialOption(
        id: 'opt3',
        name: 'Материал 3',
        category: 'test_category',
        unit: 'м²',
        pricePerUnit: 200,
        durabilityYears: 20,
      ),
    ];

    Widget createWidget({
      String calculatorId = 'test_calc',
      double requiredQuantity = 50.0,
      List<MaterialOption>? materials,
      bool isLoading = false,
      bool hasError = false,
    }) {
      return createTestApp(
        overrides: [
          materialsForCalculatorProvider(calculatorId).overrideWith(
            (_) async {
              if (isLoading) {
                await Future.delayed(const Duration(seconds: 10));
                return [];
              }
              if (hasError) {
                throw Exception('Test error');
              }
              return materials ?? mockOptions;
            },
          ),
        ],
        child: MaterialComparisonScreen(
          calculatorId: calculatorId,
          requiredQuantity: requiredQuantity,
        ),
      );
    }

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(createWidget(hasError: true));
      await tester.pump();

      expect(find.text('Не удалось загрузить материалы'), findsOneWidget);
      expect(find.text('Сравнение материалов'), findsOneWidget);
    });

    testWidgets('shows empty state when no options', (tester) async {
      await tester.pumpWidget(createWidget(materials: []));
      await tester.pump();

      expect(find.text('Нет вариантов для сравнения'), findsOneWidget);
    });

    testWidgets('renders recommendations section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Рекомендации'), findsOneWidget);
      expect(find.text('Самое дешёвое'), findsOneWidget);
      expect(find.text('Самое долговечное'), findsOneWidget);
      expect(find.text('Оптимальное'), findsOneWidget);
    });

    testWidgets('shows material options list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Материал 1'), findsWidgets);
      expect(find.text('Материал 2'), findsWidgets);
      expect(find.text('Материал 3'), findsWidgets);
    });

    testWidgets('displays durability years', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Срок службы: 10 лет'), findsOneWidget);
      expect(find.text('Срок службы: 15 лет'), findsOneWidget);
      expect(find.text('Срок службы: 20 лет'), findsOneWidget);
    });

    testWidgets('has add button in app bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows add option dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Добавить вариант'), findsOneWidget);
      expect(find.text('Функция в разработке'), findsOneWidget);
      expect(find.text('Закрыть'), findsOneWidget);
    });

    testWidgets('closes add option dialog', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Open dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Close dialog
      await tester.tap(find.text('Закрыть'));
      await tester.pumpAndSettle();

      expect(find.text('Добавить вариант'), findsNothing);
    });

    testWidgets('renders list with numbered avatars', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(CircleAvatar), findsNWidgets(3));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('first option is selected by default', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // First option should have check_circle icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(2));
    });

    testWidgets('can select different option by tapping', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Initially first option is selected
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap second option ListTile
      final listTiles = find.byType(ListTile);
      await tester.tap(listTiles.at(1));
      await tester.pump();

      // Second option should now be selected
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('can select option using icon button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Find outline icons (unselected)
      final outlineIcons = find.byIcon(Icons.check_circle_outline);
      expect(outlineIcons, findsNWidgets(2));

      // Tap first outline icon
      await tester.tap(outlineIcons.first);
      await tester.pump();

      // Check that selection changed
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders cards in list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // 3 material cards + 3 recommendation cards
      expect(find.byType(Card), findsNWidgets(6));
    });

    testWidgets('renders star icons in recommendations', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should have 3 star icons (one per recommendation)
      expect(find.byIcon(Icons.star), findsNWidgets(3));
    });

    testWidgets('has scrollable list', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
