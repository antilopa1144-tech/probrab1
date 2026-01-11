import '../models/unit_conversion.dart';

/// Сервис для конвертации единиц измерения
///
/// Поддерживает конвертацию между различными единицами измерения
/// для строительных расчетов: площадь, длина, объём, вес, количество
class UnitConverterService {
  // Singleton pattern
  static final UnitConverterService _instance = UnitConverterService._internal();
  factory UnitConverterService() => _instance;
  UnitConverterService._internal();

  /// Получить все доступные единицы
  List<Unit> get allUnits => [
        ...areaUnits,
        ...lengthUnits,
        ...volumeUnits,
        ...weightUnits,
        ...quantityUnits,
      ];

  /// Единицы площади
  List<Unit> get areaUnits => [
        const Unit(
          id: 'sq_m',
          name: 'квадратный метр',
          symbol: 'м²',
          category: UnitCategory.area,
          toBaseUnit: 1.0,
          isBase: true,
        ),
        const Unit(
          id: 'sq_cm',
          name: 'квадратный сантиметр',
          symbol: 'см²',
          category: UnitCategory.area,
          toBaseUnit: 0.0001,
        ),
        const Unit(
          id: 'sq_mm',
          name: 'квадратный миллиметр',
          symbol: 'мм²',
          category: UnitCategory.area,
          toBaseUnit: 0.000001,
        ),
        const Unit(
          id: 'hectare',
          name: 'гектар',
          symbol: 'га',
          category: UnitCategory.area,
          toBaseUnit: 10000.0,
        ),
        const Unit(
          id: 'sq_km',
          name: 'квадратный километр',
          symbol: 'км²',
          category: UnitCategory.area,
          toBaseUnit: 1000000.0,
        ),
      ];

  /// Единицы длины
  List<Unit> get lengthUnits => [
        const Unit(
          id: 'meter',
          name: 'метр',
          symbol: 'м',
          category: UnitCategory.length,
          toBaseUnit: 1.0,
          isBase: true,
        ),
        const Unit(
          id: 'cm',
          name: 'сантиметр',
          symbol: 'см',
          category: UnitCategory.length,
          toBaseUnit: 0.01,
        ),
        const Unit(
          id: 'mm',
          name: 'миллиметр',
          symbol: 'мм',
          category: UnitCategory.length,
          toBaseUnit: 0.001,
        ),
        const Unit(
          id: 'km',
          name: 'километр',
          symbol: 'км',
          category: UnitCategory.length,
          toBaseUnit: 1000.0,
        ),
      ];

  /// Единицы объёма
  List<Unit> get volumeUnits => [
        const Unit(
          id: 'cubic_m',
          name: 'кубический метр',
          symbol: 'м³',
          category: UnitCategory.volume,
          toBaseUnit: 1.0,
          isBase: true,
        ),
        const Unit(
          id: 'liter',
          name: 'литр',
          symbol: 'л',
          category: UnitCategory.volume,
          toBaseUnit: 0.001,
        ),
        const Unit(
          id: 'cubic_cm',
          name: 'кубический сантиметр',
          symbol: 'см³',
          category: UnitCategory.volume,
          toBaseUnit: 0.000001,
        ),
        const Unit(
          id: 'cubic_dm',
          name: 'кубический дециметр',
          symbol: 'дм³',
          category: UnitCategory.volume,
          toBaseUnit: 0.001,
        ),
      ];

  /// Единицы веса
  List<Unit> get weightUnits => [
        const Unit(
          id: 'kg',
          name: 'килограмм',
          symbol: 'кг',
          category: UnitCategory.weight,
          toBaseUnit: 1.0,
          isBase: true,
        ),
        const Unit(
          id: 'gram',
          name: 'грамм',
          symbol: 'г',
          category: UnitCategory.weight,
          toBaseUnit: 0.001,
        ),
        const Unit(
          id: 'ton',
          name: 'тонна',
          symbol: 'т',
          category: UnitCategory.weight,
          toBaseUnit: 1000.0,
        ),
        const Unit(
          id: 'centner',
          name: 'центнер',
          symbol: 'ц',
          category: UnitCategory.weight,
          toBaseUnit: 100.0,
        ),
      ];

  /// Единицы количества
  List<Unit> get quantityUnits => [
        const Unit(
          id: 'piece',
          name: 'штука',
          symbol: 'шт',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
          isBase: true,
        ),
        const Unit(
          id: 'roll',
          name: 'рулон',
          symbol: 'рул',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
        ),
        const Unit(
          id: 'bag',
          name: 'мешок',
          symbol: 'меш',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
        ),
        const Unit(
          id: 'sheet',
          name: 'лист',
          symbol: 'лист',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
        ),
        const Unit(
          id: 'pack',
          name: 'упаковка',
          symbol: 'уп',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
        ),
        const Unit(
          id: 'box',
          name: 'коробка',
          symbol: 'кор',
          category: UnitCategory.quantity,
          toBaseUnit: 1.0,
        ),
      ];

  /// Получить единицы по категории
  List<Unit> getUnitsByCategory(UnitCategory category) {
    switch (category) {
      case UnitCategory.area:
        return areaUnits;
      case UnitCategory.length:
        return lengthUnits;
      case UnitCategory.volume:
        return volumeUnits;
      case UnitCategory.weight:
        return weightUnits;
      case UnitCategory.quantity:
        return quantityUnits;
    }
  }

  /// Найти единицу по ID
  Unit? findUnitById(String id) {
    try {
      return allUnits.firstWhere((unit) => unit.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Конвертировать значение между единицами
  ///
  /// Возвращает [ConversionResult] или null, если конвертация невозможна
  ConversionResult? convert({
    required double value,
    required Unit from,
    required Unit to,
  }) {
    // Проверка, что единицы относятся к одной категории
    if (from.category != to.category) {
      return null; // Невозможно конвертировать между разными категориями
    }

    // Для количества конвертация 1:1 (все единицы эквивалентны)
    if (from.category == UnitCategory.quantity) {
      return ConversionResult(
        fromValue: value,
        fromUnit: from,
        toValue: value,
        toUnit: to,
        timestamp: DateTime.now(),
      );
    }

    // Конвертация через базовую единицу
    // 1. Конвертируем исходное значение в базовую единицу
    final baseValue = value * from.toBaseUnit;

    // 2. Конвертируем базовую единицу в целевую
    final result = baseValue / to.toBaseUnit;

    return ConversionResult(
      fromValue: value,
      fromUnit: from,
      toValue: result,
      toUnit: to,
      timestamp: DateTime.now(),
    );
  }

  /// Быстрая конвертация по ID единиц
  double? convertById({
    required double value,
    required String fromId,
    required String toId,
  }) {
    final fromUnit = findUnitById(fromId);
    final toUnit = findUnitById(toId);

    if (fromUnit == null || toUnit == null) {
      return null;
    }

    final result = convert(value: value, from: fromUnit, to: toUnit);
    return result?.toValue;
  }

  /// Получить базовую единицу для категории
  Unit getBaseUnit(UnitCategory category) {
    return getUnitsByCategory(category).firstWhere((unit) => unit.isBase);
  }

  /// Популярные конвертации для быстрого доступа
  List<ConversionPreset> get popularPresets => [
        ConversionPreset(
          name: 'м² → см²',
          fromUnit: findUnitById('sq_m')!,
          toUnit: findUnitById('sq_cm')!,
        ),
        ConversionPreset(
          name: 'м → см',
          fromUnit: findUnitById('meter')!,
          toUnit: findUnitById('cm')!,
        ),
        ConversionPreset(
          name: 'м³ → литры',
          fromUnit: findUnitById('cubic_m')!,
          toUnit: findUnitById('liter')!,
        ),
        ConversionPreset(
          name: 'кг → г',
          fromUnit: findUnitById('kg')!,
          toUnit: findUnitById('gram')!,
        ),
        ConversionPreset(
          name: 'т → кг',
          fromUnit: findUnitById('ton')!,
          toUnit: findUnitById('kg')!,
        ),
      ];
}

/// Пресет конвертации для быстрого доступа
class ConversionPreset {
  final String name;
  final Unit fromUnit;
  final Unit toUnit;

  const ConversionPreset({
    required this.name,
    required this.fromUnit,
    required this.toUnit,
  });
}
