// Утилиты для форматирования крепежных элементов (саморезов)
// с учетом веса и количества штук

class ScrewFormatter {
  /// Приблизительный вес одного самореза в граммах
  /// Данные основаны на стандартных весах метизов
  static const Map<String, double> _screwWeights = {
    // Саморезы для ГКЛ (TN - по металлу через гипсокартон)
    '3.5x25': 1.8,  // TN25
    '3.5x35': 2.3,  // TN35

    // Саморезы по металлу (LN - металл-металл)
    '3.5x9.5': 0.8,  // LN (клопы)

    // Саморезы для ОСБ/дерева
    '4.0x40': 3.2,
    '4.2x50': 4.5,
    '4.5x60': 5.8,
    '4.5x75': 7.0,
  };

  /// Форматирует количество саморезов с весом
  ///
  /// Параметры:
  /// - quantity: количество саморезов (штук)
  /// - diameter: диаметр самореза (мм)
  /// - length: длина самореза (мм)
  ///
  /// Возвращает строку вида: "1.2 кг (~460 шт)"
  static String formatWithWeight({
    required int quantity,
    required double diameter,
    required double length,
  }) {
    final key = _getScrewKey(diameter, length);
    final weightPerScrew = _screwWeights[key];

    if (weightPerScrew == null) {
      // Если точного веса нет, используем примерную формулу
      // Вес самореза ≈ (диаметр² × длина × 0.006) грамм
      // Коэффициент 0.006 получен эмпирически для стальных саморезов
      final estimatedWeight = (diameter * diameter * length * 0.006);
      return _formatResult(quantity, estimatedWeight);
    }

    return _formatResult(quantity, weightPerScrew);
  }

  /// Создает ключ для поиска веса самореза
  static String _getScrewKey(double diameter, double length) {
    // Округляем до одного знака для диаметра
    final d = diameter.toStringAsFixed(1);
    // Для длины убираем лишние нули (9.5 → "9.5", 25.0 → "25")
    final l = length % 1 == 0 ? length.toInt().toString() : length.toStringAsFixed(1);
    return '${d}x$l';
  }

  /// Форматирует итоговый результат
  static String _formatResult(int quantity, double weightPerScrewGrams) {
    final totalWeightGrams = quantity * weightPerScrewGrams;
    final totalWeightKg = totalWeightGrams / 1000;

    // Если меньше 100 грамм, показываем в граммах
    if (totalWeightGrams < 100) {
      return '${totalWeightGrams.round()} г (~$quantity шт)';
    }

    // Иначе показываем в килограммах
    return '${totalWeightKg.toStringAsFixed(2)} кг (~$quantity шт)';
  }

  /// Упрощенный метод для частых случаев
  /// Возвращает только вес без количества
  static String formatWeightOnly({
    required int quantity,
    required double diameter,
    required double length,
  }) {
    final full = formatWithWeight(
      quantity: quantity,
      diameter: diameter,
      length: length,
    );
    // Извлекаем только вес (до " (~")
    return full.split(' (~')[0];
  }
}
