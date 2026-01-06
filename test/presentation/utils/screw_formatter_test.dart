import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/utils/screw_formatter.dart';

void main() {
  group('ScrewFormatter', () {
    group('formatWithWeight', () {
      test('formats known screw size correctly', () {
        // 3.5x25 screw weighs 1.8g
        final result = ScrewFormatter.formatWithWeight(
          quantity: 1000,
          diameter: 3.5,
          length: 25,
        );
        // 1000 * 1.8g = 1800g = 1.80 kg
        expect(result, '1.80 кг (~1000 шт)');
      });

      test('formats another known screw size', () {
        // 3.5x35 screw weighs 2.3g
        final result = ScrewFormatter.formatWithWeight(
          quantity: 500,
          diameter: 3.5,
          length: 35,
        );
        // 500 * 2.3g = 1150g = 1.15 kg
        expect(result, '1.15 кг (~500 шт)');
      });

      test('formats small quantity in grams', () {
        // 3.5x25 screw weighs 1.8g
        final result = ScrewFormatter.formatWithWeight(
          quantity: 50,
          diameter: 3.5,
          length: 25,
        );
        // 50 * 1.8g = 90g (less than 100g)
        expect(result, '90 г (~50 шт)');
      });

      test('uses estimated weight for unknown screw size', () {
        final result = ScrewFormatter.formatWithWeight(
          quantity: 100,
          diameter: 5.0,
          length: 100,
        );
        // Weight estimate: 5^2 * 100 * 0.006 = 15g per screw
        // 100 * 15 = 1500g = 1.50 kg
        expect(result, contains('кг'));
        expect(result, contains('100 шт'));
      });

      test('formats LN screw (klopy)', () {
        // 3.5x9.5 screw weighs 0.8g
        final result = ScrewFormatter.formatWithWeight(
          quantity: 100,
          diameter: 3.5,
          length: 9.5,
        );
        // 100 * 0.8g = 80g (less than 100g)
        expect(result, '80 г (~100 шт)');
      });

      test('formats OSB screw 4.0x40', () {
        // 4.0x40 screw weighs 3.2g
        final result = ScrewFormatter.formatWithWeight(
          quantity: 200,
          diameter: 4.0,
          length: 40,
        );
        // 200 * 3.2g = 640g = 0.64 kg
        expect(result, '0.64 кг (~200 шт)');
      });
    });

    group('formatWeightOnly', () {
      test('returns only weight part', () {
        final result = ScrewFormatter.formatWeightOnly(
          quantity: 1000,
          diameter: 3.5,
          length: 25,
        );
        expect(result, '1.80 кг');
        expect(result, isNot(contains('шт')));
      });

      test('returns grams for small quantity', () {
        final result = ScrewFormatter.formatWeightOnly(
          quantity: 50,
          diameter: 3.5,
          length: 25,
        );
        expect(result, '90 г');
      });
    });

    group('edge cases', () {
      test('handles zero quantity', () {
        final result = ScrewFormatter.formatWithWeight(
          quantity: 0,
          diameter: 3.5,
          length: 25,
        );
        expect(result, '0 г (~0 шт)');
      });

      test('handles large quantity', () {
        final result = ScrewFormatter.formatWithWeight(
          quantity: 10000,
          diameter: 3.5,
          length: 25,
        );
        // 10000 * 1.8g = 18000g = 18.00 kg
        expect(result, '18.00 кг (~10000 шт)');
      });

      test('handles very small screws', () {
        final result = ScrewFormatter.formatWithWeight(
          quantity: 100,
          diameter: 2.0,
          length: 10,
        );
        // Uses formula: 2^2 * 10 * 0.006 = 0.24g per screw
        // 100 * 0.24 = 24g
        expect(result, contains('г'));
      });
    });
  });
}
