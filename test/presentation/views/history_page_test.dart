import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/data/repositories/calculation_repository.dart';
import 'package:probrab_ai/presentation/providers/calculation_provider.dart';
import 'package:probrab_ai/presentation/views/history_page.dart';

import '../../helpers/test_helpers.dart';

/// Mock repository для тестирования
class MockCalculationRepository implements CalculationRepository {
  final List<Calculation> _calculations = [];
  bool shouldThrow = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Calculation>> getAllCalculations() async {
    if (shouldThrow) throw Exception('Test error');
    return List.from(_calculations);
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    if (shouldThrow) throw Exception('Test error');
    double totalCost = 0;
    for (final calc in _calculations) {
      totalCost += calc.totalCost;
    }
    return {
      'totalCalculations': _calculations.length,
      'totalCost': totalCost,
    };
  }

  void addCalculation(Calculation calculation) {
    _calculations.add(calculation);
  }

  void clear() {
    _calculations.clear();
  }
}

Calculation createTestCalculation({
  int id = 1,
  String title = 'Test',
  String calculatorId = 'test_calc',
  String calculatorName = 'Test Calculator',
  String category = 'foundation',
  double totalCost = 1000,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Calculation()
    ..id = id
    ..title = title
    ..calculatorId = calculatorId
    ..calculatorName = calculatorName
    ..category = category
    ..inputsJson = '{}'
    ..resultsJson = '{}'
    ..totalCost = totalCost
    ..createdAt = createdAt ?? now
    ..updatedAt = now;
}

void main() {
  group('HistoryPage', () {
    late MockCalculationRepository mockRepository;

    setUp(() {
      mockRepository = MockCalculationRepository();
      setupMocks();
    });

    Widget createWidget() {
      return createTestApp(
        overrides: [
          calculationRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const Scaffold(body: HistoryPage()),
      );
    }

    testWidgets('renders loading state initially', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders statistics when data is loaded', (tester) async {
      mockRepository.addCalculation(createTestCalculation(id: 1));
      mockRepository.addCalculation(createTestCalculation(id: 2));
      mockRepository.addCalculation(createTestCalculation(id: 3));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Расчётов'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Поиск расчётов...'), findsOneWidget);
    });

    testWidgets('search filters calculations', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Расчёт фундамента'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 2, title: 'Расчёт стен'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 3, title: 'Расчёт кровли'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially all calculations should be visible
      expect(find.text('Расчёт фундамента'), findsOneWidget);
      expect(find.text('Расчёт стен'), findsOneWidget);
      expect(find.text('Расчёт кровли'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'фундамента');
      await tester.pumpAndSettle();

      // Only matching calculation should be visible
      expect(find.text('Расчёт фундамента'), findsOneWidget);
      expect(find.text('Расчёт стен'), findsNothing);
      expect(find.text('Расчёт кровли'), findsNothing);
    });

    testWidgets('renders category filter chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find filter chips container (horizontal scroll)
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('shows empty state when no calculations', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Нет расчётов'), findsOneWidget);
      expect(
        find.text('Создайте первый расчёт, чтобы он появился здесь'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when search has no results', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Расчёт фундамента'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query that doesn't match anything
      await tester.enterText(find.byType(TextField), 'нет такого');
      await tester.pumpAndSettle();

      expect(find.text('Нет расчётов'), findsOneWidget);
      expect(
        find.text('Попробуйте изменить поисковый запрос'),
        findsOneWidget,
      );
    });

    testWidgets('renders calculation list', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Расчёт фундамента'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 2, title: 'Расчёт стен'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 3, title: 'Расчёт кровли'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Расчёт фундамента'), findsOneWidget);
      expect(find.text('Расчёт стен'), findsOneWidget);
      expect(find.text('Расчёт кровли'), findsOneWidget);
    });

    testWidgets('has refresh indicator', (tester) async {
      mockRepository.addCalculation(createTestCalculation(id: 1));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('displays horizontal scroll for filter chips', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verify that horizontal scroll view exists for filter chips
      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsWidgets);

      // Find horizontal scroll views
      final horizontalScrolls = tester.widgetList<SingleChildScrollView>(
        scrollViews,
      ).where((w) => w.scrollDirection == Axis.horizontal);

      expect(horizontalScrolls.isNotEmpty, isTrue);
    });

    testWidgets('search is case insensitive', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Расчёт фундамента'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 2, title: 'Расчёт стен'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search with different case
      await tester.enterText(find.byType(TextField), 'ФУНДАМЕНТА');
      await tester.pumpAndSettle();

      expect(find.text('Расчёт фундамента'), findsOneWidget);
      expect(find.text('Расчёт стен'), findsNothing);
    });

    testWidgets('clears search results when query is cleared', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Расчёт фундамента'),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 2, title: 'Расчёт стен'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'фундамента');
      await tester.pumpAndSettle();
      expect(find.text('Расчёт стен'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // All calculations should be visible again
      expect(find.text('Расчёт фундамента'), findsOneWidget);
      expect(find.text('Расчёт стен'), findsOneWidget);
    });
  });
}
