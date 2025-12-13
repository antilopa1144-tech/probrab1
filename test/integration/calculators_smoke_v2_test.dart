import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';

void main() {
  group('CalculatorRegistry V2 smoke', () {
    test('all calculators calculate with safe defaults', () {
      final emptyPriceList = <PriceItem>[];

      for (final calc in CalculatorRegistry.allCalculators) {
        final inputs = _buildValidDefaults(calc);

        try {
          final result = calc.useCase.call(inputs, emptyPriceList);

          expect(result.values.isNotEmpty, isTrue, reason: calc.id);
          for (final entry in result.values.entries) {
            expect(entry.value.isNaN, isFalse,
                reason: '${calc.id}.${entry.key} is NaN');
            expect(entry.value.isInfinite, isFalse,
                reason: '${calc.id}.${entry.key} is Infinite');
          }
        } on CalculationException catch (e) {
          fail('Calculator ${calc.id} threw CalculationException: ${e.message}');
        } catch (e) {
          fail('Calculator ${calc.id} threw unexpected error: $e');
        }
      }
    });
  });
}

Map<String, double> _buildValidDefaults(CalculatorDefinitionV2 calc) {
  final inputs = <String, double>{};

  // 1) Ставим дефолты для всех полей.
  for (final field in calc.fields) {
    inputs[field.key] = field.defaultValue;
  }

  // 2) Для обязательных полей гарантируем валидное значение (даже если они скрыты по дефолту).
  for (final field in calc.fields) {
    var value = inputs[field.key] ?? field.defaultValue;
    final hasZeroOption =
        field.options?.any((option) => option.value == 0) ?? false;
    if (field.required && value == 0 && !hasZeroOption) {
      if (field.minValue != null && field.minValue! > 0) {
        value = field.minValue!;
      } else if (field.maxValue != null && field.maxValue! > 0) {
        value = field.maxValue!;
      } else {
        value = 1.0;
      }
    }

    if (field.minValue != null && value < field.minValue!) {
      value = field.minValue!;
    }
    if (field.maxValue != null && value > field.maxValue!) {
      value = field.maxValue!;
    }

    inputs[field.key] = value;
  }

  // 4) Если есть поля площади и все они нулевые, поднимаем первую площадь.
  final areaFields = calc.fields
      .where((f) => f.key.toLowerCase().contains('area'))
      .toList();
  if (areaFields.isNotEmpty &&
      areaFields.every((f) => (inputs[f.key] ?? 0) <= 0)) {
    final first = areaFields.first;
    inputs[first.key] =
        (first.minValue != null && first.minValue! > 0) ? first.minValue! : 1.0;
  }

  return inputs;
}
