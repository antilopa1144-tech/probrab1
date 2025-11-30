import '../exceptions/validation_exception.dart';
import '../../domain/models/calculator_field.dart';

/// Валидатор полей калькулятора.
class FieldValidator {
  /// Валидировать значение поля
  static ValidationException? validate(
    CalculatorField field,
    double? value,
  ) {
    // Проверка обязательности
    if (field.required && value == null) {
      return ValidationException.required(field.key);
    }

    // Если поле не обязательное и значение пустое - валидно
    if (!field.required && value == null) {
      return null;
    }

    // Проверка на отрицательные значения (если minValue >= 0)
    if (field.minValue != null && field.minValue! >= 0 && value! < 0) {
      return ValidationException.negative(field.key, value);
    }

    // Проверка минимального значения
    if (field.minValue != null && value! < field.minValue!) {
      return ValidationException.minValue(
        field.key,
        field.minValue!,
        value,
      );
    }

    // Проверка максимального значения
    if (field.maxValue != null && value! > field.maxValue!) {
      return ValidationException.maxValue(
        field.key,
        field.maxValue!,
        value,
      );
    }

    return null;
  }

  /// Валидировать все поля
  static List<ValidationException> validateAll(
    List<CalculatorField> fields,
    Map<String, double> inputs,
  ) {
    final errors = <ValidationException>[];

    for (final field in fields) {
      final value = inputs[field.key];
      final error = validate(field, value);
      if (error != null) {
        errors.add(error);
      }
    }

    return errors;
  }

  /// Валидировать конкретное поле по ключу
  static ValidationException? validateByKey(
    List<CalculatorField> fields,
    String key,
    double? value,
  ) {
    try {
      final field = fields.firstWhere((f) => f.key == key);
      return validate(field, value);
    } catch (_) {
      return null;
    }
  }

  /// Проверить, все ли обязательные поля заполнены
  static bool areRequiredFieldsFilled(
    List<CalculatorField> fields,
    Map<String, double> inputs,
  ) {
    for (final field in fields) {
      if (field.required && !inputs.containsKey(field.key)) {
        return false;
      }
    }
    return true;
  }

  /// Получить список незаполненных обязательных полей
  static List<String> getMissingRequiredFields(
    List<CalculatorField> fields,
    Map<String, double> inputs,
  ) {
    final missing = <String>[];

    for (final field in fields) {
      if (field.required && !inputs.containsKey(field.key)) {
        missing.add(field.key);
      }
    }

    return missing;
  }

  /// Валидировать логические ограничения (например, длина > ширина недопустима)
  static ValidationException? validateLogical(
    Map<String, double> inputs, {
    String? context,
  }) {
    // Проверка площади
    final area = inputs['area'];
    if (area != null && area > 10000) {
      return ValidationException.custom(
        'Площадь $area м² кажется слишком большой. Проверьте значение.',
        fieldName: 'area',
      );
    }

    // Проверка объёма
    final volume = inputs['volume'];
    if (volume != null && volume > 1000) {
      return ValidationException.custom(
        'Объём $volume м³ кажется слишком большим. Проверьте значение.',
        fieldName: 'volume',
      );
    }

    // Проверка соотношения длины и ширины
    final length = inputs['length'];
    final width = inputs['width'];
    if (length != null && width != null) {
      if (length > width * 10) {
        return ValidationException.custom(
          'Длина ($length м) значительно больше ширины ($width м). Возможно, вы перепутали значения?',
        );
      }
      if (width > length * 10) {
        return ValidationException.custom(
          'Ширина ($width м) значительно больше длины ($length м). Возможно, вы перепутали значения?',
        );
      }
    }

    // Проверка толщины
    final thickness = inputs['thickness'];
    if (thickness != null) {
      if (thickness > 500) {
        return ValidationException.custom(
          'Толщина $thickness мм кажется слишком большой. Проверьте единицы измерения.',
          fieldName: 'thickness',
        );
      }
      if (thickness < 0.1 && thickness > 0) {
        return ValidationException.custom(
          'Толщина $thickness мм кажется слишком маленькой. Проверьте значение.',
          fieldName: 'thickness',
        );
      }
    }

    // Проверка высоты
    final height = inputs['height'];
    if (height != null && height > 10) {
      return ValidationException.custom(
        'Высота $height м кажется слишком большой для помещения. Проверьте значение.',
        fieldName: 'height',
      );
    }

    // Проверка периметра и площади
    final perimeter = inputs['perimeter'];
    if (area != null && perimeter != null) {
      // Для квадрата: P = 4√A
      final minPerimeter = 4 * (area.sqrt());
      if (perimeter < minPerimeter * 0.9) {
        return ValidationException.custom(
          'Периметр ($perimeter м) слишком мал для указанной площади ($area м²). Проверьте значения.',
        );
      }
    }

    return null;
  }

  /// Валидировать расход материала (не должен быть слишком большим)
  static ValidationException? validateConsumption(
    double consumption,
    double area,
    String materialType,
  ) {
    final consumptionPerM2 = consumption / area;

    // Проверка на аномальные значения расхода
    if (materialType.contains('paint') && consumptionPerM2 > 1.0) {
      return ValidationException.custom(
        'Расход краски ($consumptionPerM2 л/м²) кажется слишком большим. Обычно 0.1-0.2 л/м².',
      );
    }

    if (materialType.contains('primer') && consumptionPerM2 > 0.5) {
      return ValidationException.custom(
        'Расход грунтовки ($consumptionPerM2 л/м²) кажется слишком большим. Обычно 0.08-0.15 л/м².',
      );
    }

    if (materialType.contains('plaster') && consumptionPerM2 > 20) {
      return ValidationException.custom(
        'Расход штукатурки ($consumptionPerM2 кг/м²) кажется слишком большим. Проверьте толщину слоя.',
      );
    }

    return null;
  }
}

/// Расширение для извлечения квадратного корня
extension on double {
  double sqrt() => this < 0 ? 0 : toDouble().squareRoot();
}

extension on double {
  double squareRoot() {
    if (this == 0) return 0;
    double x = this;
    double prev = 0;
    while ((x - prev).abs() > 0.0001) {
      prev = x;
      x = (x + this / x) / 2;
    }
    return x;
  }
}
