import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/history_category.dart';

void main() {
  group('HistoryCategory', () {
    test('has all expected values', () {
      expect(HistoryCategory.values, contains(HistoryCategory.all));
      expect(HistoryCategory.values, contains(HistoryCategory.foundation));
      expect(HistoryCategory.values, contains(HistoryCategory.walls));
      expect(HistoryCategory.values, contains(HistoryCategory.roofing));
      expect(HistoryCategory.values, contains(HistoryCategory.finishing));
    });

    test('has exactly 5 values', () {
      expect(HistoryCategory.values.length, 5);
    });
  });

  group('HistoryCategoryX', () {
    test('returns correct translationKey for all', () {
      expect(HistoryCategory.all.translationKey, 'history.category.all');
    });

    test('returns correct translationKey for foundation', () {
      expect(
        HistoryCategory.foundation.translationKey,
        'history.category.foundation',
      );
    });

    test('returns correct translationKey for walls', () {
      expect(HistoryCategory.walls.translationKey, 'history.category.walls');
    });

    test('returns correct translationKey for roofing', () {
      expect(
        HistoryCategory.roofing.translationKey,
        'history.category.roofing',
      );
    });

    test('returns correct translationKey for finishing', () {
      expect(
        HistoryCategory.finishing.translationKey,
        'history.category.finishing',
      );
    });
  });

  group('HistoryCategoryResolver', () {
    group('tryParse', () {
      test('parses enum name "all"', () {
        expect(HistoryCategoryResolver.tryParse('all'), HistoryCategory.all);
      });

      test('parses enum name "foundation"', () {
        expect(
          HistoryCategoryResolver.tryParse('foundation'),
          HistoryCategory.foundation,
        );
      });

      test('parses enum name "walls"', () {
        expect(HistoryCategoryResolver.tryParse('walls'), HistoryCategory.walls);
      });

      test('parses enum name "roofing"', () {
        expect(
          HistoryCategoryResolver.tryParse('roofing'),
          HistoryCategory.roofing,
        );
      });

      test('parses enum name "finishing"', () {
        expect(
          HistoryCategoryResolver.tryParse('finishing'),
          HistoryCategory.finishing,
        );
      });

      test('parses translation key', () {
        expect(
          HistoryCategoryResolver.tryParse('history.category.foundation'),
          HistoryCategory.foundation,
        );
      });

      test('parses Russian "фундамент"', () {
        expect(
          HistoryCategoryResolver.tryParse('Фундамент'),
          HistoryCategory.foundation,
        );
      });

      test('parses Russian "стены"', () {
        expect(
          HistoryCategoryResolver.tryParse('Стены'),
          HistoryCategory.walls,
        );
      });

      test('parses Russian "кровля"', () {
        expect(
          HistoryCategoryResolver.tryParse('Кровля'),
          HistoryCategory.roofing,
        );
      });

      test('parses Russian "отделка"', () {
        expect(
          HistoryCategoryResolver.tryParse('Отделка'),
          HistoryCategory.finishing,
        );
      });

      test('parses Russian "все"', () {
        expect(
          HistoryCategoryResolver.tryParse('Все'),
          HistoryCategory.all,
        );
      });

      test('parses lowercase Russian', () {
        expect(
          HistoryCategoryResolver.tryParse('фундамент'),
          HistoryCategory.foundation,
        );
      });

      test('returns null for empty string', () {
        expect(HistoryCategoryResolver.tryParse(''), isNull);
      });

      test('returns null for whitespace only', () {
        expect(HistoryCategoryResolver.tryParse('   '), isNull);
      });

      test('returns null for unknown string', () {
        expect(HistoryCategoryResolver.tryParse('unknown'), isNull);
      });

      test('trims input before parsing', () {
        expect(
          HistoryCategoryResolver.tryParse('  foundation  '),
          HistoryCategory.foundation,
        );
      });
    });

    group('fromCalculatorId', () {
      test('returns foundation for foundation_ prefix', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('foundation_concrete'),
          HistoryCategory.foundation,
        );
      });

      test('returns foundation for foundation_rebar', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('foundation_rebar'),
          HistoryCategory.foundation,
        );
      });

      test('returns roofing for roofing_ prefix', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('roofing_metal'),
          HistoryCategory.roofing,
        );
      });

      test('returns roofing for roofing_shingles', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('roofing_shingles'),
          HistoryCategory.roofing,
        );
      });

      test('returns walls for walls_ prefix', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('walls_brick'),
          HistoryCategory.walls,
        );
      });

      test('returns walls for wall_ prefix', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('wall_gasblock'),
          HistoryCategory.walls,
        );
      });

      test('returns walls for paint_universal', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('paint_universal'),
          HistoryCategory.walls,
        );
      });

      test('uses fallback category when available', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'unknown_calc',
            fallbackStoredCategory: 'foundation',
          ),
          HistoryCategory.foundation,
        );
      });

      test('uses fallback for walls category', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'unknown_calc',
            fallbackStoredCategory: 'walls',
          ),
          HistoryCategory.walls,
        );
      });

      test('uses fallback for roofing category', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'unknown_calc',
            fallbackStoredCategory: 'roofing',
          ),
          HistoryCategory.roofing,
        );
      });

      test('ignores "all" fallback category', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'unknown_calc',
            fallbackStoredCategory: 'all',
          ),
          HistoryCategory.finishing,
        );
      });

      test('defaults to finishing for unknown id without fallback', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId('unknown_calc'),
          HistoryCategory.finishing,
        );
      });

      test('defaults to finishing for invalid fallback', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'unknown_calc',
            fallbackStoredCategory: 'invalid',
          ),
          HistoryCategory.finishing,
        );
      });

      test('id prefix takes precedence over fallback', () {
        expect(
          HistoryCategoryResolver.fromCalculatorId(
            'foundation_concrete',
            fallbackStoredCategory: 'walls',
          ),
          HistoryCategory.foundation,
        );
      });
    });
  });
}
