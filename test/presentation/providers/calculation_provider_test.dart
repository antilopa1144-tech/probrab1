import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/calculation_provider.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/data/repositories/calculation_repository.dart';

/// Mock repository для тестирования без Isar
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
  Future<List<Calculation>> getCalculationsByCategory(String category) async {
    if (shouldThrow) throw Exception('Test error');
    return _calculations.where((c) => c.category == category).toList();
  }

  @override
  Future<Map<String, dynamic>> getStatistics() async {
    if (shouldThrow) throw Exception('Test error');
    double totalCost = 0;
    final categoryCount = <String, int>{};
    for (final calc in _calculations) {
      totalCost += calc.totalCost;
      categoryCount[calc.category] = (categoryCount[calc.category] ?? 0) + 1;
    }
    return {
      'totalCalculations': _calculations.length,
      'totalCost': totalCost,
      'categoryCount': categoryCount,
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
  DateTime? updatedAt,
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
    ..updatedAt = updatedAt ?? now;
}

void main() {
  group('CalculationProvider', () {
    late MockCalculationRepository mockRepository;

    setUp(() {
      mockRepository = MockCalculationRepository();
    });

    group('calculationsProvider', () {
      test('returns empty list when no calculations', () async {
        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(calculationsProvider.future);

        expect(calculations, isEmpty);
      });

      test('returns calculations sorted by date', () async {
        final now = DateTime.now();
        mockRepository.addCalculation(createTestCalculation(
          id: 1,
          title: 'Old',
          updatedAt: now.subtract(const Duration(days: 2)),
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 2,
          title: 'New',
          updatedAt: now,
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 3,
          title: 'Middle',
          updatedAt: now.subtract(const Duration(days: 1)),
        ));

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(calculationsProvider.future);

        expect(calculations.length, 3);
        expect(calculations[0].title, 'New');
        expect(calculations[1].title, 'Middle');
        expect(calculations[2].title, 'Old');
      });

      test('returns empty list on error', () async {
        mockRepository.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(calculationsProvider.future);

        expect(calculations, isEmpty);
      });
    });

    group('calculationsByCategoryProvider', () {
      test('returns calculations for specific category', () async {
        mockRepository.addCalculation(createTestCalculation(
          id: 1,
          category: 'foundation',
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 2,
          category: 'walls',
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 3,
          category: 'foundation',
        ));

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final foundationCalcs = await container.read(
          calculationsByCategoryProvider('foundation').future,
        );

        expect(foundationCalcs.length, 2);
        expect(foundationCalcs.every((c) => c.category == 'foundation'), true);
      });

      test('returns empty list for non-existent category', () async {
        mockRepository.addCalculation(createTestCalculation(
          id: 1,
          category: 'foundation',
        ));

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final roofingCalcs = await container.read(
          calculationsByCategoryProvider('roofing').future,
        );

        expect(roofingCalcs, isEmpty);
      });

      test('returns empty list on error', () async {
        mockRepository.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(
          calculationsByCategoryProvider('foundation').future,
        );

        expect(calculations, isEmpty);
      });
    });

    group('statisticsProvider', () {
      test('returns correct statistics', () async {
        mockRepository.addCalculation(createTestCalculation(
          id: 1,
          category: 'foundation',
          totalCost: 100000,
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 2,
          category: 'walls',
          totalCost: 50000,
        ));
        mockRepository.addCalculation(createTestCalculation(
          id: 3,
          category: 'foundation',
          totalCost: 75000,
        ));

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final stats = await container.read(statisticsProvider.future);

        expect(stats['totalCalculations'], 3);
        expect(stats['totalCost'], 225000);
        final categoryCount = stats['categoryCount'] as Map<String, dynamic>;
        expect(categoryCount['foundation'], 2);
        expect(categoryCount['walls'], 1);
      });

      test('returns empty statistics when no calculations', () async {
        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final stats = await container.read(statisticsProvider.future);

        expect(stats['totalCalculations'], 0);
        expect(stats['totalCost'], 0);
      });

      test('returns empty map on error', () async {
        mockRepository.shouldThrow = true;

        final container = ProviderContainer(
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final stats = await container.read(statisticsProvider.future);

        expect(stats, isEmpty);
      });
    });

    group('PaginatedCalculationsNotifier', () {
      test('loads calculations on initialization', () async {
        for (int i = 1; i <= 5; i++) {
          mockRepository.addCalculation(createTestCalculation(
            id: i,
            title: 'Calc $i',
          ));
        }

        final notifier = PaginatedCalculationsNotifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.hasValue, true);
        expect(notifier.state.value!.length, 5);
      });

      test('loads more calculations on loadMore', () async {
        for (int i = 1; i <= 25; i++) {
          final now = DateTime.now();
          mockRepository.addCalculation(createTestCalculation(
            id: i,
            title: 'Calc $i',
            updatedAt: now.subtract(Duration(minutes: i)),
          ));
        }

        final notifier = PaginatedCalculationsNotifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        // First page (20 items)
        expect(notifier.state.value!.length, 20);

        await notifier.loadMore();
        await Future.delayed(const Duration(milliseconds: 100));

        // Second page (5 more items)
        expect(notifier.state.value!.length, 25);
      });

      test('refresh resets pagination', () async {
        for (int i = 1; i <= 5; i++) {
          mockRepository.addCalculation(createTestCalculation(
            id: i,
            title: 'Calc $i',
          ));
        }

        final notifier = PaginatedCalculationsNotifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.length, 5);

        // Add more calculations
        for (int i = 6; i <= 10; i++) {
          mockRepository.addCalculation(createTestCalculation(
            id: i,
            title: 'Calc $i',
          ));
        }

        await notifier.refresh();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.length, 10);
      });

      test('handles error state', () async {
        mockRepository.shouldThrow = true;

        final notifier = PaginatedCalculationsNotifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.hasError, true);
      });
    });
  });
}
