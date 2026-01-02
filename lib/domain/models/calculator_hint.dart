/// Тип подсказки калькулятора.
enum HintType {
  /// Информация перед расчётом
  info,

  /// Предупреждение
  warning,

  /// Совет мастера
  tip,

  /// Важное замечание
  important,
}

/// Подсказка калькулятора.
class CalculatorHint {
  /// Тип подсказки
  final HintType type;

  /// Ключ перевода для текста подсказки (используется если message не задан)
  final String? messageKey;

  /// Прямой текст подсказки (приоритет над messageKey)
  final String? message;

  /// Условие отображения подсказки
  final HintCondition? condition;

  /// Иконка подсказки
  final String? iconName;

  const CalculatorHint({
    required this.type,
    this.messageKey,
    this.message,
    this.condition,
    this.iconName,
  }) : assert(messageKey != null || message != null, 'Either messageKey or message must be provided');
}

/// Условие отображения подсказки.
class HintCondition {
  /// Тип условия
  final HintConditionType type;

  /// Ключ поля для проверки
  final String? fieldKey;

  /// Ключ результата для проверки
  final String? resultKey;

  /// Значение для сравнения
  final double? value;

  /// Диапазон значений
  final (double min, double max)? range;

  const HintCondition({
    required this.type,
    this.fieldKey,
    this.resultKey,
    this.value,
    this.range,
  });

  /// Проверить условие на входных данных
  bool isSatisfiedByInputs(Map<String, double> inputs) {
    if (fieldKey == null) return false;
    final fieldValue = inputs[fieldKey];
    if (fieldValue == null) return false;

    return _checkCondition(fieldValue);
  }

  /// Проверить условие на результатах
  bool isSatisfiedByResults(Map<String, double> results) {
    if (resultKey == null) return false;
    final resultValue = results[resultKey];
    if (resultValue == null) return false;

    return _checkCondition(resultValue);
  }

  bool _checkCondition(double actualValue) {
    return switch (type) {
      HintConditionType.always => true,
      HintConditionType.greaterThan => value != null && actualValue > value!,
      HintConditionType.lessThan => value != null && actualValue < value!,
      HintConditionType.equals => value != null && actualValue == value!,
      HintConditionType.inRange =>
        range != null && actualValue >= range!.$1 && actualValue <= range!.$2,
      HintConditionType.outOfRange =>
        range != null && (actualValue < range!.$1 || actualValue > range!.$2),
    };
  }
}

/// Тип условия для подсказки
enum HintConditionType {
  /// Всегда показывать
  always,

  /// Если значение больше указанного
  greaterThan,

  /// Если значение меньше указанного
  lessThan,

  /// Если значение равно указанному
  equals,

  /// Если значение в диапазоне
  inRange,

  /// Если значение вне диапазона
  outOfRange,
}
