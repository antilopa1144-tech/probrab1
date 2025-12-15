import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions/calculation_exception.dart';
import '../../core/validation/field_validator.dart';
import '../../core/validation/input_sanitizer.dart';
import '../../core/isolate/calculation_isolate.dart';
import '../../domain/models/calculator_definition_v2.dart';
import '../../domain/usecases/calculator_usecase.dart';
import '../../domain/usecases/base_calculator.dart';
import '../providers/price_provider.dart';

/// Контроллер для управления состоянием калькулятора.
///
/// Выносит бизнес-логику из UI, обеспечивая:
/// - Валидацию входных данных
/// - Выполнение расчётов
/// - Обработку ошибок
/// - Управление состоянием
///
/// ## Пример использования:
///
/// ```dart
/// final controller = ref.read(calculatorControllerProvider);
/// final result = await controller.calculate(
///   definition: calculatorDefinition,
///   inputs: {'area': 50.0, 'thickness': 10.0},
/// );
/// ```
class CalculatorController {
  CalculatorController(this.ref);

  final Ref ref;

  /// Выполнить расчёт.
  ///
  /// - [definition]: определение калькулятора
  /// - [inputs]: входные данные
  /// - [useIsolate]: использовать Isolate для тяжёлых расчётов (по умолчанию true)
  ///
  /// Возвращает результат расчёта или выбрасывает исключение.
  Future<Map<String, double>> calculate({
    required CalculatorDefinitionV2 definition,
    required Map<String, double> inputs,
    bool useIsolate = true,
  }) async {
    // Валидация входных данных
    final validationError = _validateInputs(definition, inputs);
    if (validationError != null) {
      throw CalculationException.invalidInput(definition.id, validationError);
    }

    // Получаем список цен
    final priceList = await ref.read(priceListProvider.future);

    // Выполняем расчёт
    CalculatorResult result;
    if (useIsolate && _isHeavyCalculation(definition, inputs)) {
      // Используем Isolate для тяжёлых расчётов
      result = await CalculationIsolate.compute(
        useCase: definition.useCase,
        inputs: inputs,
        priceList: priceList,
      );
    } else {
      // Обычный расчёт
      result = definition.calculate(inputs, priceList);
    }

    return result.values;
  }

  /// Валидация входных данных.
  String? _validateInputs(
    CalculatorDefinitionV2 definition,
    Map<String, double> inputs,
  ) {
    // Проверка обязательных полей
    for (final field in definition.fields) {
      if (field.required) {
        final value = inputs[field.key];
        if (value == null || value == 0) {
          return 'Поле ${field.labelKey} обязательно для заполнения';
        }
      }
    }

    // Валидация логических ограничений
    final logicalError = FieldValidator.validateLogical(inputs);
    if (logicalError != null) {
      return logicalError.getUserMessage();
    }

    // Валидация через useCase, если он поддерживает
    if (definition.useCase is BaseCalculator) {
      final baseCalculator = definition.useCase as BaseCalculator;
      final validationError = baseCalculator.validateInputs(inputs);
      if (validationError != null) {
        return validationError;
      }
    }

    return null;
  }

  /// Проверка, является ли расчёт тяжёлым.
  bool _isHeavyCalculation(
    CalculatorDefinitionV2 definition,
    Map<String, double> inputs,
  ) {
    // Калькуляторы фундамента и отопления считаются тяжёлыми
    final heavyCalculatorIds = [
      'foundation_strip',
      'foundation_slab',
      'foundation_basement',
      'engineering_heating',
      'floors_warm',
    ];

    if (heavyCalculatorIds.contains(definition.id)) {
      return true;
    }

    // Проверка на большие значения
    final perimeter = inputs['perimeter'] ?? 0.0;
    final area = inputs['area'] ?? 0.0;
    final volume = inputs['volume'] ?? 0.0;

    return perimeter > 100 || area > 500 || volume > 100;
  }

  /// Парсинг входных данных из текстовых контроллеров.
  Map<String, double> parseInputs(
    CalculatorDefinitionV2 definition,
    Map<String, String> textInputs,
  ) {
    final inputs = <String, double>{};
    for (final field in definition.fields) {
      final text = textInputs[field.key] ?? '';
      final value = InputSanitizer.parseDouble(text) ?? field.defaultValue;
      inputs[field.key] = value;
    }
    return inputs;
  }

  /// Форматирование результатов для отображения.
  Map<String, String> formatResults(Map<String, double> results) {
    final formatted = <String, String>{};
    for (final entry in results.entries) {
      formatted[entry.key] = InputSanitizer.formatNumber(entry.value);
    }
    return formatted;
  }
}

/// Provider для CalculatorController.
final calculatorControllerProvider = Provider<CalculatorController>((ref) {
  return CalculatorController(ref);
});
