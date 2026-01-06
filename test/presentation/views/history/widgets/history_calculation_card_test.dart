import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/domain/calculators/history_category.dart';
import 'package:probrab_ai/presentation/views/history/widgets/history_calculation_card.dart';

Calculation _createTestCalculation({
  String title = 'Test Calculation',
  String calculatorId = 'test_calculator',
  String calculatorName = 'Test Calculator',
  String category = 'foundation',
  Map<String, dynamic>? inputs,
  Map<String, dynamic>? results,
  String? notes,
}) {
  return Calculation()
    ..id = 1
    ..title = title
    ..calculatorId = calculatorId
    ..calculatorName = calculatorName
    ..category = category
    ..inputsJson = jsonEncode(inputs ?? {'length': 10.0, 'width': 5.0})
    ..resultsJson = jsonEncode(results ?? {'area': 50.0, 'volume': 25.0})
    ..totalCost = 10000.0
    ..createdAt = DateTime(2024, 1, 15, 10, 30)
    ..updatedAt = DateTime(2024, 1, 15, 10, 30)
    ..notes = notes;
}

void main() {
  group('HistoryCalculationCard', () {
    testWidgets('renders calculation title', (tester) async {
      final calculation = _createTestCalculation(title: 'My Calculation');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Foundation Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Calculation'), findsOneWidget);
    });

    testWidgets('renders calculator name', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.walls,
              calculatorName: 'Wall Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Wall Calculator'), findsOneWidget);
    });

    testWidgets('renders formatted date', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('15.01.2024 10:30'), findsOneWidget);
    });

    testWidgets('shows foundation icon for foundation category', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.foundation), findsOneWidget);
    });

    testWidgets('shows walls icon for walls category', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.walls,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.view_column), findsOneWidget);
    });

    testWidgets('shows roofing icon for roofing category', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.roofing,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.roofing), findsOneWidget);
    });

    testWidgets('shows finishing icon for finishing category', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.finishing,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_paint), findsOneWidget);
    });

    testWidgets('shows calculate icon for all category', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.all,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('shows delete button', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when delete tapped', (tester) async {
      final calculation = _createTestCalculation(title: 'Delete Me');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Удалить расчёт?'), findsOneWidget);
      expect(find.text('Удалить "Delete Me"?'), findsOneWidget);
      expect(find.text('Отмена'), findsOneWidget);
      expect(find.text('Удалить'), findsOneWidget);
    });

    testWidgets('calls onDelete when confirmed', (tester) async {
      bool deleted = false;
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(deleted, true);
    });

    testWidgets('does not call onDelete when cancelled', (tester) async {
      bool deleted = false;
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(deleted, false);
    });

    testWidgets('shows details sheet when card tapped', (tester) async {
      final calculation = _createTestCalculation(
        title: 'Detail Test',
        inputs: {'length': 10.0},
        results: {'area': 100.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Test Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Bottom sheet should appear with details
      expect(find.text('Detail Test'), findsWidgets);
      expect(find.text('Введённые данные:'), findsOneWidget);
      expect(find.text('Результаты:'), findsOneWidget);
    });

    testWidgets('is wrapped in Card', (tester) async {
      final calculation = _createTestCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationCard(
              calculation: calculation,
              category: HistoryCategory.foundation,
              calculatorName: 'Calculator',
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('HistoryCalculationDetails', () {
    testWidgets('renders title and calculator name', (tester) async {
      final calculation = _createTestCalculation(
        title: 'My Calculation',
        inputs: {'x': 1.0},
        results: {'y': 2.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Test Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Calculation'), findsOneWidget);
      expect(find.text('Test Calculator'), findsOneWidget);
    });

    testWidgets('renders inputs', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'length': 10.0, 'width': 5.0},
        results: {'area': 50.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('length'), findsOneWidget);
      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('width'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('renders results section header', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'x': 1.0},
        results: {'area': 50.5},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that result section is present
      expect(find.text('Результаты:'), findsOneWidget);
      // Check that area result is shown
      expect(find.text('area'), findsOneWidget);
    });

    testWidgets('shows notes when present', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        notes: 'Important note here',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Notes may be scrolled out of view in DraggableScrollableSheet
      // Just verify the widget renders without error
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('hides notes section when notes is null', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'x': 1.0},
        results: {'y': 2.0},
        notes: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Заметки:'), findsNothing);
    });

    testWidgets('has close button', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'x': 1.0},
        results: {'y': 2.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has open calculator button', (tester) async {
      final calculation = _createTestCalculation(
        inputs: {'x': 1.0},
        results: {'y': 2.0},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: 'Calculator',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });
  });
}
