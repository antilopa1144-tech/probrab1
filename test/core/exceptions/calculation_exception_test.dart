import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/core/exceptions/app_exception.dart';

void main() {
  group('CalculationException', () {
    test('extends AppException', () {
      const exception = CalculationException('test');
      expect(exception, isA<AppException>());
    });

    test('stores message correctly', () {
      const exception = CalculationException('Test error message');
      expect(exception.message, 'Test error message');
    });

    test('stores optional parameters', () {
      const exception = CalculationException(
        'Test error',
        code: 'TEST_CODE',
        calculatorId: 'plaster',
        inputs: {'area': 20.0},
        details: 'Additional details',
      );

      expect(exception.code, 'TEST_CODE');
      expect(exception.calculatorId, 'plaster');
      expect(exception.inputs, {'area': 20.0});
      expect(exception.details, 'Additional details');
    });

    group('factory constructors', () {
      test('divisionByZero creates correct exception', () {
        final exception = CalculationException.divisionByZero('calculating area');

        expect(exception.code, 'DIVISION_BY_ZERO');
        expect(exception.message, contains('Деление на ноль'));
        expect(exception.message, contains('calculating area'));
        expect(exception.details, 'calculating area');
      });

      test('invalidInput creates correct exception', () {
        final exception = CalculationException.invalidInput(
          'plaster',
          'area must be positive',
        );

        expect(exception.code, 'INVALID_INPUT');
        expect(exception.calculatorId, 'plaster');
        expect(exception.message, contains('plaster'));
        expect(exception.message, contains('area must be positive'));
        expect(exception.details, 'area must be positive');
      });

      test('overflow creates correct exception', () {
        final exception = CalculationException.overflow('volume calculation');

        expect(exception.code, 'OVERFLOW');
        expect(exception.message, contains('Переполнение'));
        expect(exception.message, contains('volume calculation'));
        expect(exception.details, 'volume calculation');
      });

      test('missingData creates correct exception', () {
        final exception = CalculationException.missingData('price data');

        expect(exception.code, 'MISSING_DATA');
        expect(exception.message, contains('Отсутствуют'));
        expect(exception.message, contains('price data'));
        expect(exception.details, 'price data');
      });

      test('custom creates correct exception', () {
        final exception = CalculationException.custom(
          'Custom error message',
          calculatorId: 'tile',
          inputs: {'width': 10.0, 'height': 5.0},
        );

        expect(exception.code, 'CUSTOM');
        expect(exception.message, 'Custom error message');
        expect(exception.calculatorId, 'tile');
        expect(exception.inputs, {'width': 10.0, 'height': 5.0});
      });
    });

    group('getUserMessage', () {
      test('returns formatted user message', () {
        const exception = CalculationException('something went wrong');
        expect(exception.getUserMessage(), 'Ошибка расчёта: something went wrong');
      });
    });
  });
}
