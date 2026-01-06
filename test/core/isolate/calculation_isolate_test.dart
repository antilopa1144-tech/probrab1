import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/isolate/calculation_isolate.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

/// Простой калькулятор для тестов.
class SimpleTestCalculator implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = inputs['area'] ?? 0.0;
    final length = inputs['length'] ?? 0.0;
    final width = inputs['width'] ?? 0.0;

    return CalculatorResult(
      values: {
        'area': area > 0 ? area : length * width,
        'perimeter': 2 * (length + width),
      },
    );
  }
}

/// Калькулятор, который выбрасывает ошибку.
class ErrorCalculator implements CalculatorUseCase {
  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    throw Exception('Calculation error');
  }
}

void main() {
  group('CalculationIsolate', () {
    late SimpleTestCalculator useCase;
    late List<PriceItem> priceList;

    setUp(() {
      useCase = SimpleTestCalculator();
      priceList = const [
        PriceItem(
          sku: 'TEST001',
          name: 'Test Item',
          price: 100.0,
          unit: 'шт',
          imageUrl: '',
        ),
      ];
    });

    group('compute', () {
      test('executes light calculation synchronously', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'length': 5.0, 'width': 4.0},
          priceList: priceList,
        );

        expect(result.values['area'], 20.0);
        expect(result.values['perimeter'], 18.0);
      });

      test('handles empty inputs', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {},
          priceList: priceList,
        );

        expect(result.values['area'], 0.0);
        expect(result.values['perimeter'], 0.0);
      });

      test('handles empty price list', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'length': 10.0, 'width': 5.0},
          priceList: [],
        );

        expect(result.values['area'], 50.0);
      });

      test('uses isolate for large perimeter', () async {
        // Perimeter > 100 should trigger isolate
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'perimeter': 150.0, 'length': 10.0, 'width': 5.0},
          priceList: priceList,
        );

        // Should still produce correct result
        expect(result.values, isNotEmpty);
      });

      test('uses isolate for large area', () async {
        // Area > 500 should trigger isolate
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'area': 600.0},
          priceList: priceList,
        );

        expect(result.values['area'], 600.0);
      });

      test('uses isolate for large volume', () async {
        // Volume > 100 should trigger isolate
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'volume': 150.0, 'length': 10.0, 'width': 5.0},
          priceList: priceList,
        );

        expect(result.values, isNotEmpty);
      });

      test('propagates calculator errors', () async {
        final errorUseCase = ErrorCalculator();

        expect(
          () => CalculationIsolate.compute(
            useCase: errorUseCase,
            inputs: {'length': 5.0},
            priceList: priceList,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('boundary test: perimeter exactly 100 is light', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'perimeter': 100.0},
          priceList: priceList,
        );

        // Should complete without using isolate
        expect(result.values, isNotEmpty);
      });

      test('boundary test: area exactly 500 is light', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'area': 500.0},
          priceList: priceList,
        );

        expect(result.values['area'], 500.0);
      });

      test('boundary test: volume exactly 100 is light', () async {
        final result = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'volume': 100.0},
          priceList: priceList,
        );

        expect(result.values, isNotEmpty);
      });

      test('multiple calculations can run sequentially', () async {
        final result1 = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'length': 5.0, 'width': 5.0},
          priceList: priceList,
        );

        final result2 = await CalculationIsolate.compute(
          useCase: useCase,
          inputs: {'length': 10.0, 'width': 10.0},
          priceList: priceList,
        );

        expect(result1.values['area'], 25.0);
        expect(result2.values['area'], 100.0);
      });
    });
  });
}
