// Модели для конвертера единиц измерения

/// Категории единиц измерения
enum UnitCategory {
  /// Площадь (м², см², мм²)
  area,

  /// Длина (м, см, мм, км)
  length,

  /// Объём (м³, литры, см³)
  volume,

  /// Вес (кг, г, тонны)
  weight,

  /// Количество (штуки, рулоны, мешки, листы)
  quantity,
}

/// Единица измерения с коэффициентом конвертации
class Unit {
  /// Идентификатор единицы
  final String id;

  /// Короткое обозначение (например: "м", "кг")
  final String symbol;

  /// Категория единицы
  final UnitCategory category;

  /// Коэффициент конвертации к базовой единице
  /// Например, для длины базовая единица - метр (коэффициент 1.0)
  /// 1 км = 1000 м, поэтому коэффициент для км = 1000.0
  /// 1 см = 0.01 м, поэтому коэффициент для см = 0.01
  final double toBaseUnit;

  /// Является ли эта единица базовой для своей категории
  final bool isBase;

  const Unit({
    required this.id,
    required this.symbol,
    required this.category,
    required this.toBaseUnit,
    this.isBase = false,
  });

  @override
  String toString() => symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Результат конвертации
class ConversionResult {
  /// Исходное значение
  final double fromValue;

  /// Исходная единица
  final Unit fromUnit;

  /// Результат конвертации
  final double toValue;

  /// Целевая единица
  final Unit toUnit;

  /// Время конвертации
  final DateTime timestamp;

  const ConversionResult({
    required this.fromValue,
    required this.fromUnit,
    required this.toValue,
    required this.toUnit,
    required this.timestamp,
  });

  /// Форматированная строка результата
  /// Например: "10 м = 1000 см"
  String get formatted {
    return '${_formatValue(fromValue)} ${fromUnit.symbol} = ${_formatValue(toValue)} ${toUnit.symbol}';
  }

  /// Форматирование значения (убирает лишние нули)
  String _formatValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // Округляем до 4 знаков после запятой
    return value.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  String toString() => formatted;
}
