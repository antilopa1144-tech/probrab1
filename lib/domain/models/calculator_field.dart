import '../../core/enums/unit_type.dart';
import '../../core/enums/field_input_type.dart';

/// Опция для селекта или радио-кнопок
class FieldOption {
  final double value;
  final String labelKey;
  final String? descriptionKey;

  const FieldOption({
    required this.value,
    required this.labelKey,
    this.descriptionKey,
  });
}

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

  /// Тип поля ввода (по умолчанию number)
  final FieldInputType inputType;

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

  /// Опции для селекта/радио (только для inputType == select или radio)
  final List<FieldOption>? options;

  const CalculatorField({
    required this.key,
    required this.labelKey,
    this.hintKey,
    required this.unitType,
    this.inputType = FieldInputType.number,
    this.defaultValue = 0.0,
    this.minValue,
    this.maxValue,
    this.required = true,
    this.step,
    this.iconName,
    this.group,
    this.order = 0,
    this.dependency,
    this.options,
  });

  /// Создать копию с изменениями
  CalculatorField copyWith({
    String? key,
    String? labelKey,
    String? hintKey,
    UnitType? unitType,
    FieldInputType? inputType,
    double? defaultValue,
    double? minValue,
    double? maxValue,
    bool? required,
    double? step,
    String? iconName,
    String? group,
    int? order,
    FieldDependency? dependency,
    List<FieldOption>? options,
  }) {
    return CalculatorField(
      key: key ?? this.key,
      labelKey: labelKey ?? this.labelKey,
      hintKey: hintKey ?? this.hintKey,
      unitType: unitType ?? this.unitType,
      inputType: inputType ?? this.inputType,
      defaultValue: defaultValue ?? this.defaultValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      required: required ?? this.required,
      step: step ?? this.step,
      iconName: iconName ?? this.iconName,
      group: group ?? this.group,
      order: order ?? this.order,
      dependency: dependency ?? this.dependency,
      options: options ?? this.options,
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
