import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_constants.dart';

void main() {
  group('Calculator Constants', () {
    test('kCalculatorAccentColor is valid color value', () {
      expect(kCalculatorAccentColor, isA<int>());
      expect(kCalculatorAccentColor, greaterThan(0));
      // Should be a valid ARGB color (starts with 0xFF for full opacity)
      expect(kCalculatorAccentColor & 0xFF000000, 0xFF000000);
    });

    test('kCalculatorAccentColor is Material Blue', () {
      // 0xFF2196F3 is Material Blue 500
      expect(kCalculatorAccentColor, 0xFF2196F3);
    });
  });

  group('calculatorTitleKey', () {
    test('generates correct key for simple id', () {
      expect(calculatorTitleKey('foundation'), 'calculator.foundation.title');
    });

    test('generates correct key for compound id', () {
      expect(
        calculatorTitleKey('foundation_concrete'),
        'calculator.foundation_concrete.title',
      );
    });

    test('generates correct key for floors_laminate', () {
      expect(
        calculatorTitleKey('floors_laminate'),
        'calculator.floors_laminate.title',
      );
    });

    test('generates correct key for roofing_metal', () {
      expect(
        calculatorTitleKey('roofing_metal'),
        'calculator.roofing_metal.title',
      );
    });

    test('handles empty string', () {
      expect(calculatorTitleKey(''), 'calculator..title');
    });

    test('handles special characters', () {
      expect(
        calculatorTitleKey('my-calc_v2'),
        'calculator.my-calc_v2.title',
      );
    });
  });

  group('calculatorDescriptionKey', () {
    test('generates correct key for simple id', () {
      expect(
        calculatorDescriptionKey('foundation'),
        'calculator.foundation.description',
      );
    });

    test('generates correct key for compound id', () {
      expect(
        calculatorDescriptionKey('foundation_concrete'),
        'calculator.foundation_concrete.description',
      );
    });

    test('generates correct key for floors_tile', () {
      expect(
        calculatorDescriptionKey('floors_tile'),
        'calculator.floors_tile.description',
      );
    });

    test('generates correct key for walls_brick', () {
      expect(
        calculatorDescriptionKey('walls_brick'),
        'calculator.walls_brick.description',
      );
    });

    test('handles empty string', () {
      expect(calculatorDescriptionKey(''), 'calculator..description');
    });

    test('handles special characters', () {
      expect(
        calculatorDescriptionKey('my-calc_v2'),
        'calculator.my-calc_v2.description',
      );
    });
  });

  group('key format consistency', () {
    test('title and description keys have same prefix', () {
      const id = 'test_calculator';
      final titleKey = calculatorTitleKey(id);
      final descKey = calculatorDescriptionKey(id);

      // Both should start with "calculator.test_calculator."
      expect(titleKey.startsWith('calculator.$id.'), isTrue);
      expect(descKey.startsWith('calculator.$id.'), isTrue);
    });

    test('title ends with .title', () {
      expect(calculatorTitleKey('any').endsWith('.title'), isTrue);
    });

    test('description ends with .description', () {
      expect(calculatorDescriptionKey('any').endsWith('.description'), isTrue);
    });
  });
}
