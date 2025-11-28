import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

void main() {
  test('all calculators produce non-empty results with default inputs', () {
    final priceList = <PriceItem>[];

    for (final definition in calculators) {
      final inputs = <String, double>{};

      for (final field in definition.fields) {
        double value = field.defaultValue;

        if (value == 0) {
          if (field.minValue != null) {
            value = field.minValue!;
          } else if (field.required) {
            value = 1;
          }
        }

        inputs[field.key] = value;
      }

      late final CalculatorResult result;
      expect(
        () => result = definition.run(inputs, priceList, useCache: false),
        returnsNormally,
        reason: '${definition.id} threw with generated inputs',
      );

      expect(result.values, isNotEmpty,
          reason: '${definition.id} returned empty results');
    }
  });
}
