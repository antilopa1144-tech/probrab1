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
    super.userMessageKey,
    super.userMessageParams,
    super.fallbackUserMessage,
  });

  factory CalculationException.divisionByZero(String context) {
    return CalculationException(
      'Деление на ноль в расчёте: $context',
      code: 'DIVISION_BY_ZERO',
      details: context,
      userMessageKey: 'error.message.calculation_division_by_zero',
      userMessageParams: {'context': context},
      fallbackUserMessage: 'Ошибка расчёта. Деление на ноль: $context',
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
      userMessageKey: 'error.message.calculation_invalid_input',
      userMessageParams: {
        'calculatorId': calculatorId,
        'reason': reason,
      },
      fallbackUserMessage:
          'Некорректные входные данные для расчёта "$calculatorId": $reason',
    );
  }

  factory CalculationException.overflow(String context) {
    return CalculationException(
      'Переполнение при расчёте: $context',
      code: 'OVERFLOW',
      details: context,
      userMessageKey: 'error.message.calculation_overflow',
      userMessageParams: {'context': context},
      fallbackUserMessage: 'Ошибка расчёта. Слишком большое значение: $context',
    );
  }

  factory CalculationException.missingData(String dataType) {
    return CalculationException(
      'Отсутствуют необходимые данные: $dataType',
      code: 'MISSING_DATA',
      details: dataType,
      userMessageKey: 'error.message.calculation_missing_data',
      userMessageParams: {'dataType': dataType},
      fallbackUserMessage: 'Не хватает данных для расчёта: $dataType',
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
      fallbackUserMessage: message,
    );
  }

  @override
  String getUserMessage([String Function(String key)? translate]) {
    if (userMessageKey != null) {
      return super.getUserMessage(translate);
    }

    final title = translate != null
        ? translate('error.calculation')
        : 'Ошибка расчёта';
    final baseMessage = fallbackUserMessage ?? message;
    return '$title: $baseMessage';
  }
}
