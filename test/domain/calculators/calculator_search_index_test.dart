import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/calculators/calculator_search_index.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Mock usecase for testing
class MockCalculatorUseCase implements CalculatorUseCase {
  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    return const CalculatorResult(values: {});
  }
}

void main() {
  group('CalculatorSearchIndex', () {
    late CalculatorSearchIndex index;
    late List<CalculatorDefinitionV2> testCalculators;
    final mockUseCase = MockCalculatorUseCase();

    setUp(() {
      index = CalculatorSearchIndex();
      testCalculators = [
        CalculatorDefinitionV2(
          id: 'paint',
          titleKey: 'Расчёт краски для стен',
          descriptionKey: 'Калькулятор краски',
          iconName: 'paint',
          category: CalculatorCategory.interior,
          subCategoryKey: 'subcategory.paint',
          fields: const [],
          useCase: mockUseCase,
          tags: const ['краска', 'стены', 'отделка'],
        ),
        CalculatorDefinitionV2(
          id: 'tile',
          titleKey: 'Расчёт плитки для пола',
          descriptionKey: 'Калькулятор плитки',
          iconName: 'tile',
          category: CalculatorCategory.interior,
          subCategoryKey: 'subcategory.tile',
          fields: const [],
          useCase: mockUseCase,
          tags: const ['плитка', 'пол', 'керамика'],
        ),
        CalculatorDefinitionV2(
          id: 'facade',
          titleKey: 'Расчёт фасадной штукатурки',
          descriptionKey: 'Калькулятор фасада',
          iconName: 'facade',
          category: CalculatorCategory.exterior,
          subCategoryKey: 'subcategory.facade',
          fields: const [],
          useCase: mockUseCase,
          tags: const ['фасад', 'штукатурка', 'наружка'],
        ),
      ];
    });

    group('buildIndex', () {
      test('builds index without errors', () {
        expect(() => index.buildIndex(testCalculators), returnsNormally);
      });

      test('handles empty list', () {
        expect(() => index.buildIndex([]), returnsNormally);
      });

      test('clears previous index on rebuild', () {
        index.buildIndex(testCalculators);
        final firstResult = index.search('краска');
        expect(firstResult, contains('paint'));

        // Rebuild with different data
        index.buildIndex([testCalculators[1]]);
        final secondResult = index.search('краска');
        expect(secondResult, isEmpty);
      });
    });

    group('search', () {
      setUp(() {
        index.buildIndex(testCalculators);
      });

      test('finds calculator by title word', () {
        final result = index.search('краски');
        expect(result, contains('paint'));
      });

      test('finds calculator by tag', () {
        final result = index.search('керамика');
        expect(result, contains('tile'));
      });

      test('finds calculator by partial title', () {
        final result = index.search('плитки');
        expect(result, contains('tile'));
      });

      test('returns empty for no match', () {
        final result = index.search('несуществующий');
        expect(result, isEmpty);
      });

      test('returns empty for empty query', () {
        final result = index.search('');
        expect(result, isEmpty);
      });

      test('returns empty for short query (<=2 chars)', () {
        final result = index.search('по');
        expect(result, isEmpty);
      });

      test('is case insensitive', () {
        final result1 = index.search('КРАСКИ');
        final result2 = index.search('краски');
        expect(result1, equals(result2));
      });

      test('handles multiple words (AND logic)', () {
        final result = index.search('расчёт плитки');
        expect(result, contains('tile'));
        expect(result, isNot(contains('paint')));
      });

      test('finds exterior calculator', () {
        final result = index.search('фасадной');
        expect(result, contains('facade'));
      });
    });

    group('tokenize behavior', () {
      setUp(() {
        index.buildIndex(testCalculators);
      });

      test('ignores punctuation', () {
        final result = index.search('краски!');
        expect(result, contains('paint'));
      });

      test('handles Russian text', () {
        final result = index.search('штукатурки');
        expect(result, contains('facade'));
      });
    });
  });
}
