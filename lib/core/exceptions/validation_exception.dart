import 'app_exception.dart';

/// Исключение валидации входных данных.
class ValidationException extends AppException {
  final String? fieldName;
  final dynamic invalidValue;

  const ValidationException(
    super.message, {
    super.code,
    this.fieldName,
    this.invalidValue,
    super.details,
    super.userMessageKey,
    super.userMessageParams,
    super.fallbackUserMessage,
  });

  factory ValidationException.required(String fieldName) {
    return ValidationException(
      'Поле "$fieldName" обязательно для заполнения',
      code: 'REQUIRED_FIELD',
      fieldName: fieldName,
      userMessageKey: 'error.message.validation_required_field',
      userMessageParams: {'field': fieldName},
      fallbackUserMessage: 'Поле "$fieldName" обязательно для заполнения',
    );
  }

  factory ValidationException.minValue(
    String fieldName,
    double minValue,
    double actualValue,
  ) {
    return ValidationException(
      'Значение поля "$fieldName" должно быть не меньше $minValue (указано: $actualValue)',
      code: 'MIN_VALUE',
      fieldName: fieldName,
      invalidValue: actualValue,
      details: {'min': minValue, 'actual': actualValue},
      userMessageKey: 'error.message.validation_min_value',
      userMessageParams: {
        'field': fieldName,
        'min': minValue.toString(),
        'actual': actualValue.toString(),
      },
      fallbackUserMessage:
          'Значение поля "$fieldName" должно быть не меньше $minValue',
    );
  }

  factory ValidationException.maxValue(
    String fieldName,
    double maxValue,
    double actualValue,
  ) {
    return ValidationException(
      'Значение поля "$fieldName" должно быть не больше $maxValue (указано: $actualValue)',
      code: 'MAX_VALUE',
      fieldName: fieldName,
      invalidValue: actualValue,
      details: {'max': maxValue, 'actual': actualValue},
      userMessageKey: 'error.message.validation_max_value',
      userMessageParams: {
        'field': fieldName,
        'max': maxValue.toString(),
        'actual': actualValue.toString(),
      },
      fallbackUserMessage:
          'Значение поля "$fieldName" должно быть не больше $maxValue',
    );
  }

  factory ValidationException.invalidFormat(
    String fieldName,
    String expectedFormat,
  ) {
    return ValidationException(
      'Неверный формат поля "$fieldName". Ожидается: $expectedFormat',
      code: 'INVALID_FORMAT',
      fieldName: fieldName,
      userMessageKey: 'error.message.validation_invalid_format',
      userMessageParams: {
        'field': fieldName,
        'expectedFormat': expectedFormat,
      },
      fallbackUserMessage:
          'Неверный формат поля "$fieldName". Ожидается: $expectedFormat',
    );
  }

  factory ValidationException.negative(String fieldName, double value) {
    return ValidationException(
      'Значение поля "$fieldName" не может быть отрицательным (указано: $value)',
      code: 'NEGATIVE_VALUE',
      fieldName: fieldName,
      invalidValue: value,
      userMessageKey: 'error.message.validation_negative_value',
      userMessageParams: {
        'field': fieldName,
        'value': value.toString(),
      },
      fallbackUserMessage:
          'Значение поля "$fieldName" не может быть отрицательным',
    );
  }

  factory ValidationException.custom(
    String message, {
    String? fieldName,
    String? userMessageKey,
    Map<String, String>? userMessageParams,
  }) {
    return ValidationException(
      message,
      code: 'CUSTOM',
      fieldName: fieldName,
      userMessageKey: userMessageKey,
      userMessageParams: userMessageParams,
      fallbackUserMessage: message,
    );
  }
}
