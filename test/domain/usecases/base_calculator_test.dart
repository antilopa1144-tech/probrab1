import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/models/calculator_constant.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

// Test implementation of BaseCalculator
class TestCalculator extends BaseCalculator {
  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', defaultValue: 10.0);
    final price = findPrice(priceList, ['test_material']);
    final totalPrice = calculateCost(area, price?.price);

    return createResult(
      values: {'area': area},
      totalPrice: totalPrice,
    );
  }
}

PriceItem _createPriceItem(String sku, String name, double price) {
  return PriceItem(
    sku: sku,
    name: name,
    price: price,
    unit: 'шт',
    imageUrl: '',
  );
}

CalculatorConstants _createConstants(Map<String, CalculatorConstant> constants) {
  return CalculatorConstants(
    calculatorId: 'test',
    version: '1.0',
    lastUpdated: DateTime(2024, 1, 1),
    constants: constants,
  );
}

CalculatorConstant _createConstant(String key, Map<String, dynamic> values) {
  return CalculatorConstant(
    key: key,
    category: ConstantCategory.coefficients,
    description: 'Test constant',
    values: values,
  );
}

void main() {
  late TestCalculator calculator;

  setUp(() {
    calculator = TestCalculator();
  });

  group('BaseCalculator - getInput', () {
    test('returns value when key exists', () {
      final inputs = {'area': 25.0};
      expect(calculator.getInput(inputs, 'area'), 25.0);
    });

    test('returns defaultValue when key missing', () {
      final inputs = <String, double>{};
      expect(calculator.getInput(inputs, 'area', defaultValue: 10.0), 10.0);
    });

    test('applies minValue constraint', () {
      final inputs = {'area': 5.0};
      expect(calculator.getInput(inputs, 'area', minValue: 10.0), 10.0);
    });

    test('applies maxValue constraint', () {
      final inputs = {'area': 100.0};
      expect(calculator.getInput(inputs, 'area', maxValue: 50.0), 50.0);
    });

    test('applies both min and max constraints', () {
      final inputs = {'area': 200.0};
      expect(
        calculator.getInput(inputs, 'area', minValue: 10.0, maxValue: 100.0),
        100.0,
      );
    });
  });

  group('BaseCalculator - getIntInput', () {
    test('returns rounded integer value', () {
      final inputs = {'count': 5.7};
      expect(calculator.getIntInput(inputs, 'count'), 6);
    });

    test('returns defaultValue when key missing', () {
      final inputs = <String, double>{};
      expect(calculator.getIntInput(inputs, 'count', defaultValue: 3), 3);
    });

    test('applies minValue constraint', () {
      final inputs = {'count': 2.0};
      expect(calculator.getIntInput(inputs, 'count', minValue: 5), 5);
    });

    test('applies maxValue constraint', () {
      final inputs = {'count': 20.0};
      expect(calculator.getIntInput(inputs, 'count', maxValue: 10), 10);
    });
  });

  group('BaseCalculator - findPrice', () {
    test('finds price by first SKU', () {
      final priceList = [
        _createPriceItem('cement', 'Cement', 500),
        _createPriceItem('sand', 'Sand', 200),
      ];

      final result = calculator.findPrice(priceList, ['cement']);
      expect(result?.sku, 'cement');
      expect(result?.price, 500);
    });

    test('finds price by second SKU when first not found', () {
      final priceList = [
        _createPriceItem('sand', 'Sand', 200),
      ];

      final result = calculator.findPrice(priceList, ['cement', 'sand']);
      expect(result?.sku, 'sand');
    });

    test('returns null when no SKU found', () {
      final priceList = [
        _createPriceItem('gravel', 'Gravel', 300),
      ];

      final result = calculator.findPrice(priceList, ['cement', 'sand']);
      expect(result, isNull);
    });

    test('returns null for empty price list', () {
      final result = calculator.findPrice([], ['cement']);
      expect(result, isNull);
    });
  });

  group('BaseCalculator - calculateVolume', () {
    test('calculates volume correctly', () {
      expect(calculator.calculateVolume(10, 50), 0.5);
    });

    test('returns 0 for zero area', () {
      expect(calculator.calculateVolume(0, 50), 0);
    });

    test('returns 0 for zero thickness', () {
      expect(calculator.calculateVolume(10, 0), 0);
    });

    test('returns 0 for negative values', () {
      expect(calculator.calculateVolume(-10, 50), 0);
      expect(calculator.calculateVolume(10, -50), 0);
    });
  });

  group('BaseCalculator - addMargin', () {
    test('adds 10% margin correctly', () {
      expect(calculator.addMargin(100, 10), closeTo(110, 0.001));
    });

    test('adds 15% margin correctly', () {
      expect(calculator.addMargin(200, 15), closeTo(230, 0.001));
    });

    test('returns 0 for zero quantity', () {
      expect(calculator.addMargin(0, 10), 0);
    });

    test('returns 0 for negative quantity', () {
      expect(calculator.addMargin(-100, 10), 0);
    });
  });

  group('BaseCalculator - safeDivide', () {
    test('divides correctly', () {
      expect(calculator.safeDivide(100, 4), 25);
    });

    test('returns defaultValue on zero divisor', () {
      expect(calculator.safeDivide(100, 0, defaultValue: -1), -1);
    });

    test('throws on zero divisor when throwOnZero is true', () {
      expect(
        () => calculator.safeDivide(100, 0, throwOnZero: true),
        throwsA(isA<CalculationException>()),
      );
    });

    test('returns defaultValue for NaN divisor', () {
      expect(calculator.safeDivide(100, double.nan), 0.0);
    });

    test('returns defaultValue for infinite divisor', () {
      expect(calculator.safeDivide(100, double.infinity), 0.0);
    });
  });

  group('BaseCalculator - estimatePerimeter', () {
    test('calculates perimeter for square room', () {
      expect(calculator.estimatePerimeter(25), 20);
    });

    test('returns 0 for zero area', () {
      expect(calculator.estimatePerimeter(0), 0);
    });

    test('returns 0 for negative area', () {
      expect(calculator.estimatePerimeter(-25), 0);
    });
  });

  group('BaseCalculator - calculateUsefulArea', () {
    test('subtracts windows and doors', () {
      expect(
        calculator.calculateUsefulArea(50, windowsArea: 5, doorsArea: 3),
        42,
      );
    });

    test('returns 0 when deductions exceed total', () {
      expect(
        calculator.calculateUsefulArea(10, windowsArea: 8, doorsArea: 5),
        0,
      );
    });

    test('works with only windows', () {
      expect(
        calculator.calculateUsefulArea(30, windowsArea: 5),
        25,
      );
    });
  });

  group('BaseCalculator - calculateUnitsNeeded', () {
    test('calculates units with margin', () {
      // 90 / 10 = 9, with 0% margin = 9, ceil = 9
      expect(calculator.calculateUnitsNeeded(90, 10, marginPercent: 0), 9);
    });

    test('returns 0 for zero quantity', () {
      expect(calculator.calculateUnitsNeeded(0, 5), 0);
    });

    test('returns 0 for zero unit size', () {
      expect(calculator.calculateUnitsNeeded(100, 0), 0);
    });
  });

  group('BaseCalculator - calculateTileArea', () {
    test('calculates tile area in m² from cm', () {
      expect(calculator.calculateTileArea(30, 30), closeTo(0.09, 0.001));
    });

    test('returns 0 for zero dimensions', () {
      expect(calculator.calculateTileArea(0, 30), 0);
      expect(calculator.calculateTileArea(30, 0), 0);
    });
  });

  group('BaseCalculator - ceilToInt', () {
    test('rounds up positive values', () {
      expect(calculator.ceilToInt(2.1), 3);
      expect(calculator.ceilToInt(2.9), 3);
      expect(calculator.ceilToInt(3.0), 3);
    });

    test('returns 0 for zero', () {
      expect(calculator.ceilToInt(0), 0);
    });

    test('returns 0 for negative values', () {
      expect(calculator.ceilToInt(-2.5), 0);
    });
  });

  group('BaseCalculator - calculateCost', () {
    test('calculates cost correctly', () {
      expect(calculator.calculateCost(10, 500), 5000);
    });

    test('returns null when quantity is null', () {
      expect(calculator.calculateCost(null, 500), isNull);
    });

    test('returns null when price is null', () {
      expect(calculator.calculateCost(10, null), isNull);
    });

    test('returns null for zero quantity', () {
      expect(calculator.calculateCost(0, 500), isNull);
    });

    test('returns null for zero price', () {
      expect(calculator.calculateCost(10, 0), isNull);
    });
  });

  group('BaseCalculator - sumCosts', () {
    test('sums non-null costs', () {
      expect(calculator.sumCosts([100, 200, 300]), 600);
    });

    test('ignores null values', () {
      expect(calculator.sumCosts([100, null, 200, null]), 300);
    });

    test('returns null for all null values', () {
      expect(calculator.sumCosts([null, null]), isNull);
    });

    test('returns null for empty list', () {
      expect(calculator.sumCosts([]), isNull);
    });
  });

  group('BaseCalculator - roundBulk', () {
    test('rounds small values to 0.1', () {
      expect(calculator.roundBulk(0.15), 0.2);
      expect(calculator.roundBulk(0.51), 0.6);
    });

    test('rounds medium values to 0.5', () {
      expect(calculator.roundBulk(5.1), 5.5);
      expect(calculator.roundBulk(5.6), 6.0);
    });

    test('rounds large values to integers', () {
      expect(calculator.roundBulk(15.3), 16);
      expect(calculator.roundBulk(27.1), 28);
    });

    test('rounds very large values to 5', () {
      expect(calculator.roundBulk(102), 105);
      expect(calculator.roundBulk(147), 150);
    });

    test('returns 0 for zero or negative', () {
      expect(calculator.roundBulk(0), 0);
      expect(calculator.roundBulk(-5), 0);
    });
  });

  group('BaseCalculator - unit conversions', () {
    test('cmToMeters converts correctly', () {
      expect(calculator.cmToMeters(100), 1.0);
      expect(calculator.cmToMeters(250), 2.5);
    });

    test('mmToMeters converts correctly', () {
      expect(calculator.mmToMeters(1000), 1.0);
      expect(calculator.mmToMeters(500), 0.5);
    });
  });

  group('BaseCalculator - createResult', () {
    test('creates result with rounded values', () {
      final result = calculator.createResult(
        values: {'area': 25.123456},
        decimals: 2,
      );

      expect(result.values['area'], 25.12);
    });

    test('throws on infinite value', () {
      expect(
        () => calculator.createResult(
          values: {'area': double.infinity},
        ),
        throwsA(isA<CalculationException>()),
      );
    });

    test('throws on NaN value', () {
      expect(
        () => calculator.createResult(
          values: {'area': double.nan},
        ),
        throwsA(isA<CalculationException>()),
      );
    });

    test('throws on very large value', () {
      expect(
        () => calculator.createResult(
          values: {'area': 1e12},
        ),
        throwsA(isA<CalculationException>()),
      );
    });

    test('includes norms in result', () {
      final result = calculator.createResult(
        values: {'area': 25.0},
        norms: ['ГЭСН-2024'],
      );

      expect(result.norms, contains('ГЭСН-2024'));
    });
  });

  group('BaseCalculator - validateInputs', () {
    test('returns null for valid inputs', () {
      final inputs = {'area': 25.0, 'height': 2.7};
      expect(calculator.validateInputs(inputs), isNull);
    });

    test('returns error for NaN input', () {
      final inputs = {'area': double.nan};
      expect(calculator.validateInputs(inputs), isNotNull);
    });

    test('returns error for infinite input', () {
      final inputs = {'area': double.infinity};
      expect(calculator.validateInputs(inputs), isNotNull);
    });

    test('returns error for negative input', () {
      final inputs = {'area': -25.0};
      expect(calculator.validateInputs(inputs), isNotNull);
    });
  });

  group('BaseCalculator - call', () {
    test('calls calculate and returns result', () {
      final result = calculator.call({'area': 25.0}, []);

      expect(result.values['area'], 25.0);
    });

    test('caches result for same inputs', () {
      final inputs = {'area': 25.0};
      final result1 = calculator.call(inputs, []);
      final result2 = calculator.call(inputs, []);

      expect(identical(result1, result2), isTrue);
    });

    test('invalidates cache when inputs change', () {
      final result1 = calculator.call({'area': 25.0}, []);
      final result2 = calculator.call({'area': 30.0}, []);

      expect(result1.values['area'], 25.0);
      expect(result2.values['area'], 30.0);
    });

    test('throws for invalid inputs', () {
      expect(
        () => calculator.call({'area': -25.0}, []),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('BaseCalculator - invalidateCache', () {
    test('clears cached result', () {
      final inputs = {'area': 25.0};
      final result1 = calculator.call(inputs, []);
      calculator.invalidateCache();
      final result2 = calculator.call(inputs, []);

      expect(identical(result1, result2), isFalse);
    });
  });

  group('BaseCalculator - constants', () {
    test('hasConstants returns false when no constants', () {
      expect(calculator.hasConstants, isFalse);
    });

    test('hasConstants returns true when constants set', () {
      calculator.constants = _createConstants({});
      expect(calculator.hasConstants, isTrue);
    });

    test('constantsVersion returns version', () {
      calculator.constants = CalculatorConstants(
        calculatorId: 'test',
        version: '2.0',
        lastUpdated: DateTime(2024, 1, 1),
        constants: {},
      );

      expect(calculator.constantsVersion, '2.0');
    });

    test('constantsInfo returns info string', () {
      expect(calculator.constantsInfo, 'Using hardcoded defaults');

      calculator.constants = _createConstants({
        'key': _createConstant('key', {'x': 1}),
      });

      expect(calculator.constantsInfo, contains('v1.0'));
    });

    test('getConstantDouble returns default when no constants', () {
      expect(
        calculator.getConstantDouble('key', 'value', defaultValue: 42.0),
        42.0,
      );
    });

    test('getConstantDouble returns value from constants', () {
      calculator.constants = _createConstants({
        'power': _createConstant('power', {'bathroom': 180.0}),
      });

      expect(
        calculator.getConstantDouble('power', 'bathroom', defaultValue: 100.0),
        180.0,
      );
    });

    test('getConstantInt returns integer value', () {
      calculator.constants = _createConstants({
        'count': _createConstant('count', {'min': 5}),
      });

      expect(
        calculator.getConstantInt('count', 'min', defaultValue: 1),
        5,
      );
    });

    test('getConstantString returns string value', () {
      calculator.constants = _createConstants({
        'unit': _createConstant('unit', {'power': 'Вт/м²'}),
      });

      expect(
        calculator.getConstantString('unit', 'power', defaultValue: 'W/m²'),
        'Вт/м²',
      );
    });

    test('getConstantMap returns values map', () {
      calculator.constants = _createConstants({
        'powers': _createConstant('powers', {'kitchen': 150.0, 'bathroom': 180.0}),
      });

      final map = calculator.getConstantMap('powers');
      expect(map['kitchen'], 150.0);
      expect(map['bathroom'], 180.0);
    });
  });

  group('BaseCalculator - normativeSources', () {
    test('returns default normative sources', () {
      expect(calculator.normativeSources, contains('ГЭСН-2024'));
      expect(calculator.normativeSources, contains('ФЕР-2022'));
    });
  });
}
