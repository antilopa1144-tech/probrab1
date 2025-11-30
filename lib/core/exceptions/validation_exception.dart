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
  });

  factory ValidationException.required(String fieldName) {
    return ValidationException(
      'Поле "$fieldName" обязательно для заполнения',
      code: 'REQUIRED_FIELD',
      fieldName: fieldName,
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
    );
  }

  factory ValidationException.negative(String fieldName, double value) {
    return ValidationException(
      'Значение поля "$fieldName" не может быть отрицательным (указано: $value)',
      code: 'NEGATIVE_VALUE',
      fieldName: fieldName,
      invalidValue: value,
    );
  }

  factory ValidationException.custom(String message, {String? fieldName}) {
    return ValidationException(
      message,
      code: 'CUSTOM',
      fieldName: fieldName,
    );
  }

  @override
  String getUserMessage() {
    return message;
  }
}
