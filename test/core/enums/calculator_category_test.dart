import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';

void main() {
  group('CalculatorCategory', () {
    test('has interior and exterior values', () {
      expect(CalculatorCategory.values, contains(CalculatorCategory.interior));
      expect(CalculatorCategory.values, contains(CalculatorCategory.exterior));
      expect(CalculatorCategory.values.length, 2);
    });

    group('translationKey', () {
      test('interior returns correct key', () {
        expect(
          CalculatorCategory.interior.translationKey,
          'category.interior',
        );
      });

      test('exterior returns correct key', () {
        expect(
          CalculatorCategory.exterior.translationKey,
          'category.exterior',
        );
      });
    });

    group('iconName', () {
      test('interior returns correct icon name', () {
        expect(CalculatorCategory.interior.iconName, 'interior');
      });

      test('exterior returns correct icon name', () {
        expect(CalculatorCategory.exterior.iconName, 'exterior');
      });
    });

    test('all values have translation keys', () {
      for (final category in CalculatorCategory.values) {
        expect(category.translationKey, isNotEmpty);
        expect(category.translationKey, contains('category.'));
      }
    });

    test('all values have icon names', () {
      for (final category in CalculatorCategory.values) {
        expect(category.iconName, isNotEmpty);
      }
    });
  });
}
