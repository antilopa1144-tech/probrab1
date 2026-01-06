import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

void main() {
  group('CalculatorResult', () {
    test('creates with required values', () {
      const result = CalculatorResult(
        values: {'area': 25.0, 'volume': 10.0},
      );

      expect(result.values['area'], 25.0);
      expect(result.values['volume'], 10.0);
      expect(result.totalPrice, isNull);
      expect(result.norms, isEmpty);
    });

    test('creates with totalPrice', () {
      const result = CalculatorResult(
        values: {'quantity': 100.0},
        totalPrice: 5000.0,
      );

      expect(result.values['quantity'], 100.0);
      expect(result.totalPrice, 5000.0);
    });

    test('creates with norms', () {
      const result = CalculatorResult(
        values: {'result': 1.0},
        norms: ['ГЭСН-2024', 'ФЕР-2022'],
      );

      expect(result.norms, hasLength(2));
      expect(result.norms, contains('ГЭСН-2024'));
      expect(result.norms, contains('ФЕР-2022'));
    });

    test('creates with all parameters', () {
      const result = CalculatorResult(
        values: {'area': 50.0, 'volume': 25.0, 'price': 1000.0},
        totalPrice: 25000.0,
        norms: ['ГОСТ-2020'],
      );

      expect(result.values.length, 3);
      expect(result.totalPrice, 25000.0);
      expect(result.norms, ['ГОСТ-2020']);
    });

    test('empty values map is allowed', () {
      const result = CalculatorResult(values: {});

      expect(result.values, isEmpty);
    });

    test('default norms is empty list', () {
      const result = CalculatorResult(values: {'x': 1.0});

      expect(result.norms, isA<List<String>>());
      expect(result.norms, isEmpty);
    });
  });
}
