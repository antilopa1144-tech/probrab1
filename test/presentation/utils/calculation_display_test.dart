import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/domain/calculators/history_category.dart';
import 'package:probrab_ai/presentation/utils/calculation_display.dart';

Calculation createTestCalculation({
  int id = 1,
  String title = 'Test',
  String calculatorId = 'foundation_concrete',
  String calculatorName = 'Бетон для фундамента',
  String category = 'foundation',
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
    ..totalCost = 0
    ..createdAt = now
    ..updatedAt = now;
}

void main() {
  group('CalculationDisplay', () {
    group('historyCategory', () {
      test('returns foundation for foundation_concrete calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'foundation_concrete',
          category: 'foundation',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.foundation);
      });

      test('returns foundation for foundation_rebar calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'foundation_rebar',
          category: 'foundation',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.foundation);
      });

      test('returns foundation for foundation_slab calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'foundation_slab',
          category: 'foundation',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.foundation);
      });

      test('returns walls for walls_brick calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'walls_brick',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('returns walls for wall_gasblock calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'wall_gasblock',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('returns walls for walls_paint calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'walls_paint',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('returns walls for paint_universal calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'paint_universal',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('returns roofing for roofing_metal calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'roofing_metal',
          category: 'roofing',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.roofing);
      });

      test('returns roofing for roofing_shingles calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'roofing_shingles',
          category: 'roofing',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.roofing);
      });

      test('returns roofing for roofing_tiles calculator', () {
        final calculation = createTestCalculation(
          calculatorId: 'roofing_tiles',
          category: 'roofing',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.roofing);
      });

      test('returns finishing for unknown calculator with finishing category',
          () {
        final calculation = createTestCalculation(
          calculatorId: 'custom_calculator',
          category: 'finishing',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.finishing);
      });

      test('uses fallback category when calculator id is unknown', () {
        final calculation = createTestCalculation(
          calculatorId: 'unknown_calc',
          category: 'foundation',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.foundation);
      });

      test('uses fallback category for walls when id is unknown', () {
        final calculation = createTestCalculation(
          calculatorId: 'unknown_calc',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('uses fallback category for roofing when id is unknown', () {
        final calculation = createTestCalculation(
          calculatorId: 'unknown_calc',
          category: 'roofing',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.roofing);
      });

      test('defaults to finishing for unknown calculator without valid category',
          () {
        final calculation = createTestCalculation(
          calculatorId: 'some_random_id',
          category: 'invalid_category',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.finishing);
      });

      test('defaults to finishing for empty category', () {
        final calculation = createTestCalculation(
          calculatorId: 'some_random_id',
          category: '',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.finishing);
      });

      test('handles wall_ prefix without underscore correctly', () {
        final calculation = createTestCalculation(
          calculatorId: 'wall_plaster',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });

      test('handles walls_ prefix correctly', () {
        final calculation = createTestCalculation(
          calculatorId: 'walls_insulation',
          category: 'walls',
        );

        final result = CalculationDisplay.historyCategory(calculation);

        expect(result, HistoryCategory.walls);
      });
    });
  });
}
