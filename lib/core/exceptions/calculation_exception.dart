import 'app_exception.dart';

/// Исключение при выполнении расчётов.
class CalculationException extends AppException {
  final String? calculatorId;
  final Map<String, double>? inputs;

  const CalculationException(
    super.message, {
    super.code,
    this.calculatorId,
    this.inputs,
    super.details,
  });

  factory CalculationException.divisionByZero(String context) {
    return CalculationException(
      'Деление на ноль в расчёте: $context',
      code: 'DIVISION_BY_ZERO',
      details: context,
    );
  }

  factory CalculationException.invalidInput(
    String calculatorId,
    String reason,
  ) {
    return CalculationException(
      'Некорректные входные данные для калькулятора "$calculatorId": $reason',
      code: 'INVALID_INPUT',
      calculatorId: calculatorId,
      details: reason,
    );
  }

  factory CalculationException.overflow(String context) {
    return CalculationException(
      'Переполнение при расчёте: $context',
      code: 'OVERFLOW',
      details: context,
    );
  }

  factory CalculationException.missingData(String dataType) {
    return CalculationException(
      'Отсутствуют необходимые данные: $dataType',
      code: 'MISSING_DATA',
      details: dataType,
    );
  }

  factory CalculationException.custom(
    String message, {
    String? calculatorId,
    Map<String, double>? inputs,
  }) {
    return CalculationException(
      message,
      code: 'CUSTOM',
      calculatorId: calculatorId,
      inputs: inputs,
    );
  }

  @override
  String getUserMessage() {
    return 'Ошибка расчёта: $message';
  }
}
