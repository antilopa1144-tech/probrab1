import '../../core/enums/unit_type.dart';

/// Модель поля ввода калькулятора.
class CalculatorField {
  /// Уникальный ключ поля (используется в inputs map)
  final String key;

  /// Ключ перевода для label поля
  final String labelKey;

  /// Ключ перевода для подсказки (hint)
  final String? hintKey;

  /// Тип единицы измерения
  final UnitType unitType;

  /// Значение по умолчанию
  final double defaultValue;

  /// Минимальное значение (null = без ограничения)
  final double? minValue;

  /// Максимальное значение (null = без ограничения)
  final double? maxValue;

  /// Обязательное поле
  final bool required;

  /// Шаг изменения значения (для steppers)
  final double? step;

  /// Иконка поля
  final String? iconName;

  /// Группа полей (для группировки в UI)
  final String? group;

  /// Порядок отображения
  final int order;

  /// Зависимость от других полей (показывать только если условие выполнено)
  final FieldDependency? dependency;

  const CalculatorField({
    required this.key,
    required this.labelKey,
    this.hintKey,
    required this.unitType,
    this.defaultValue = 0.0,
    this.minValue,
    this.maxValue,
    this.required = true,
    this.step,
    this.iconName,
    this.group,
    this.order = 0,
    this.dependency,
  });

  /// Создать копию с изменениями
  CalculatorField copyWith({
    String? key,
    String? labelKey,
    String? hintKey,
    UnitType? unitType,
    double? defaultValue,
    double? minValue,
    double? maxValue,
    bool? required,
    double? step,
    String? iconName,
    String? group,
    int? order,
    FieldDependency? dependency,
  }) {
    return CalculatorField(
      key: key ?? this.key,
      labelKey: labelKey ?? this.labelKey,
      hintKey: hintKey ?? this.hintKey,
      unitType: unitType ?? this.unitType,
      defaultValue: defaultValue ?? this.defaultValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      required: required ?? this.required,
      step: step ?? this.step,
      iconName: iconName ?? this.iconName,
      group: group ?? this.group,
      order: order ?? this.order,
      dependency: dependency ?? this.dependency,
    );
  }
}

/// Зависимость поля от других полей.
class FieldDependency {
  /// Ключ поля, от которого зависит
  final String fieldKey;

  /// Условие (equals, greaterThan, lessThan)
  final DependencyCondition condition;

  /// Значение для сравнения
  final double value;

  const FieldDependency({
    required this.fieldKey,
    required this.condition,
    required this.value,
  });

  /// Проверить выполнение условия
  bool isSatisfied(Map<String, double> inputs) {
    final fieldValue = inputs[fieldKey];
    if (fieldValue == null) return false;

    return switch (condition) {
      DependencyCondition.equals => fieldValue == value,
      DependencyCondition.greaterThan => fieldValue > value,
      DependencyCondition.lessThan => fieldValue < value,
      DependencyCondition.greaterOrEqual => fieldValue >= value,
      DependencyCondition.lessOrEqual => fieldValue <= value,
      DependencyCondition.notEquals => fieldValue != value,
    };
  }
}

/// Тип условия зависимости
enum DependencyCondition {
  equals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  notEquals,
}
