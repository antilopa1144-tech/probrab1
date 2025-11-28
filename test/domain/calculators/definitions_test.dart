import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('InputFieldDefinition', () {
    test('creates field with default values', () {
      const field = InputFieldDefinition(
        key: 'test',
        labelKey: 'test.label',
      );

      expect(field.key, equals('test'));
      expect(field.labelKey, equals('test.label'));
      expect(field.type, equals('number'));
      expect(field.defaultValue, equals(0.0));
      expect(field.minValue, isNull);
      expect(field.maxValue, isNull);
      expect(field.required, isTrue);
    });

    test('creates field with custom values', () {
      const field = InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        type: 'number',
        defaultValue: 10.0,
        minValue: 1.0,
        maxValue: 1000.0,
        required: false,
      );

      expect(field.key, equals('area'));
      expect(field.defaultValue, equals(10.0));
      expect(field.minValue, equals(1.0));
      expect(field.maxValue, equals(1000.0));
      expect(field.required, isFalse);
    });
  });

  group('CalculatorDefinition', () {
    test('creates definition with required fields', () {
      final mockUseCase = _MockCalculatorUseCase();
      final definition = CalculatorDefinition(
        id: 'test.calculator',
        titleKey: 'test.title',
        fields: const [
          InputFieldDefinition(key: 'area', labelKey: 'input.area'),
        ],
        resultLabels: {'result': 'result.label'},
        useCase: mockUseCase,
      );

      expect(definition.id, equals('test.calculator'));
      expect(definition.titleKey, equals('test.title'));
      expect(definition.fields.length, equals(1));
      expect(definition.resultLabels.length, equals(1));
      expect(definition.useCase, equals(mockUseCase));
    });

    test('runs calculation correctly', () {
      final mockUseCase = _MockCalculatorUseCase();
      final definition = CalculatorDefinition(
        id: 'test.calculator',
        titleKey: 'test.title',
        fields: const [],
        resultLabels: {},
        useCase: mockUseCase,
      );

      final inputs = {'area': 10.0};
      final priceList = <PriceItem>[];

      final result = definition.run(inputs, priceList);

      expect(result.values['test'], equals(10.0));
      expect(mockUseCase.callCount, equals(1));
    });

    test('computes returns values map', () {
      final mockUseCase = _MockCalculatorUseCase();
      final definition = CalculatorDefinition(
        id: 'test.calculator',
        titleKey: 'test.title',
        fields: const [],
        resultLabels: {},
        useCase: mockUseCase,
      );

      final inputs = {'area': 10.0};
      final priceList = <PriceItem>[];

      final values = definition.compute(inputs, priceList);

      expect(values['test'], equals(10.0));
    });

    test('calculate is alias for compute', () {
      final mockUseCase = _MockCalculatorUseCase();
      final definition = CalculatorDefinition(
        id: 'test.calculator',
        titleKey: 'test.title',
        fields: const [],
        resultLabels: {},
        useCase: mockUseCase,
      );

      final inputs = {'area': 10.0};
      final priceList = <PriceItem>[];

      final values1 = definition.compute(inputs, priceList);
      final values2 = definition.calculate(inputs, priceList);

      expect(values1, equals(values2));
    });
  });
}

/// Mock калькулятор для тестирования
class _MockCalculatorUseCase implements CalculatorUseCase {
  int callCount = 0;

  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    callCount++;
    return CalculatorResult(
      values: {'test': inputs['area'] ?? 0.0},
      totalPrice: null,
    );
  }
}
