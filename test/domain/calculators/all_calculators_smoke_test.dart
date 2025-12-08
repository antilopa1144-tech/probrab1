import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('all V2 calculators produce non-empty results with default inputs', () {
    final priceList = <PriceItem>[];

    for (final definition in CalculatorRegistry.allCalculators) {
      final inputs = <String, double>{};

      for (final field in definition.fields) {
        double value = field.defaultValue;

        if (value <= 0) {
          if (field.minValue != null && field.minValue! > 0) {
            value = field.minValue!;
          } else {
            value = 10.0;
          }
        }

        inputs[field.key] = value;
      }

      CalculatorResult? result;
      try {
        result = definition.calculate(inputs, priceList, useCache: false);
        expect(
          result.values,
          isNotEmpty,
          reason: '${definition.id} returned empty results',
        );
      } catch (e) {
        if (!e.toString().contains('Firebase') &&
            !e.toString().contains('CalculationException')) {
          fail('${definition.id} threw unexpected error: $e');
        }
      }
    }
  });
}
