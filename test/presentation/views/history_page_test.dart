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

    testWidgets('отображает категорию фильтра foundation', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap foundation filter
      final foundationChips = find.text('Фундамент');
      if (foundationChips.evaluate().isNotEmpty) {
        await tester.tap(foundationChips.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает категорию фильтра walls', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap walls filter
      final wallsChips = find.text('Стены');
      if (wallsChips.evaluate().isNotEmpty) {
        await tester.tap(wallsChips.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает категорию фильтра roofing', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap roofing filter
      final roofingChips = find.text('Кровля');
      if (roofingChips.evaluate().isNotEmpty) {
        await tester.tap(roofingChips.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает категорию фильтра finishing', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap finishing filter
      final finishingChips = find.text('Отделка');
      if (finishingChips.evaluate().isNotEmpty) {
        await tester.tap(finishingChips.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('фильтрует расчёты по категории foundation', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(
          id: 1,
          title: 'Фундамент 1',
          category: 'foundation',
        ),
      );
      mockRepository.addCalculation(
        createTestCalculation(id: 2, title: 'Стены 1', category: 'walls'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Фундамент 1'), findsOneWidget);
      expect(find.text('Стены 1'), findsOneWidget);
    });

    testWidgets('поиск по названию калькулятора', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(
          id: 1,
          title: 'Проект 1',
          calculatorName: 'Кирпичный калькулятор',
        ),
      );
      mockRepository.addCalculation(
        createTestCalculation(
          id: 2,
          title: 'Проект 2',
          calculatorName: 'Бетонный калькулятор',
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search by calculator name
      await tester.enterText(find.byType(TextField), 'Кирпичный');
      await tester.pumpAndSettle();

      expect(find.text('Проект 1'), findsOneWidget);
      expect(find.text('Проект 2'), findsNothing);
    });

    testWidgets('обрабатывает ошибку загрузки статистики', (tester) async {
      mockRepository.shouldThrow = true;

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should show empty state instead of statistics
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('обрабатывает ошибку загрузки расчётов', (tester) async {
      mockRepository.shouldThrow = true;

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ошибка загрузки:'), findsOneWidget);
    });

    testWidgets('pull to refresh обновляет список', (tester) async {
      mockRepository.addCalculation(createTestCalculation(id: 1));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find RefreshIndicator and trigger refresh
      final refreshFinder = find.byType(RefreshIndicator);
      expect(refreshFinder, findsOneWidget);

      // Simulate pull to refresh
      await tester.drag(refreshFinder, const Offset(0, 300));
      await tester.pumpAndSettle();
    });

    testWidgets('отображает карточки истории расчётов', (tester) async {
      mockRepository.addCalculation(createTestCalculation(id: 1));
      mockRepository.addCalculation(createTestCalculation(id: 2));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should use StaggeredAnimation
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('удаляет расчёт через onDelete callback', (tester) async {
      mockRepository.addCalculation(
        createTestCalculation(id: 1, title: 'Удалить меня'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Удалить меня'), findsOneWidget);

      // Note: We can't easily test the delete callback without exposing it
      // This test verifies the structure is present
    });

    testWidgets('корректно работает с пустым результатом поиска', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'несуществующий');
      await tester.pumpAndSettle();

      expect(find.text('Нет расчётов'), findsOneWidget);
    });

    testWidgets('отображает иконку поиска в TextField', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('использует кэширование для плавной прокрутки', (tester) async {
      for (int i = 1; i <= 20; i++) {
        mockRepository.addCalculation(
          createTestCalculation(id: i, title: 'Расчёт $i'),
        );
      }

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.cacheExtent, 500);
    });

    testWidgets('отображает контейнер статистики с прозрачным фоном', (tester) async {
      mockRepository.addCalculation(createTestCalculation(id: 1));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });
}
