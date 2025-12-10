import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';

void main() {
  group('Calculator smoke run', () {
    test('каждый калькулятор возвращает результат без ошибки периметра', () {
      final registry = CalculatorRegistryV1.instance;
      final calculators = registry.getAll();

      for (final calc in calculators) {
        final inputs = <String, double>{};

        for (final field in calc.fields) {
          var value = field.defaultValue;
          if (value <= 0) {
            value = (field.minValue ?? 10.0) > 0 ? (field.minValue ?? 10.0) : 10.0;
          }
          if (field.maxValue != null && value > field.maxValue!) {
            value = field.maxValue!;
          }
          inputs[field.key] = value;
        }

        // Базовые резервные значения, если калькулятор ожидает ключи вне списка полей
        inputs.putIfAbsent('area', () => 100.0);
        inputs.putIfAbsent('width', () => 5.0);
        inputs.putIfAbsent('height', () => 3.0);
        inputs.putIfAbsent('length', () => 5.0);

        expect(
          () {
            final result = calc.run(inputs, const [], useCache: false);
            expect(result, isNotNull);
            expect(result.values.isNotEmpty, true);
          },
          returnsNormally,
          reason: 'Калькулятор ${calc.id} должен работать без обязательного периметра',
        );
      }
    });
  });
}
