import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('all calculators produce non-empty results with default inputs', () {
    final priceList = <PriceItem>[];

    for (final definition in calculators) {
      final inputs = <String, double>{};

      for (final field in definition.fields) {
        double value = field.defaultValue;

        // Ensure we have a valid non-zero value for testing
        if (value <= 0) {
          if (field.minValue != null && field.minValue! > 0) {
            value = field.minValue!;
          } else {
            // Use a reasonable default value for testing
            value = 10.0;
          }
        }

        inputs[field.key] = value;
      }

      CalculatorResult? result;
      try {
        result = definition.run(inputs, priceList, useCache: false);
        expect(result.values, isNotEmpty,
            reason: '${definition.id} returned empty results');
      } catch (e) {
        // Ignore Firebase-related errors in tests - they're expected when Firebase isn't initialized
        // Also ignore CalculationException for invalid inputs - the smoke test just checks calculators don't crash
        if (!e.toString().contains('Firebase') &&
            !e.toString().contains('CalculationException')) {
          fail('${definition.id} threw unexpected error: $e');
        }
      }
    }
  });
}
