/// Категории калькуляторов (упрощенная структура).
enum CalculatorCategory {
  /// Внутренняя отделка (полы, стены, потолки, перегородки, сантехника)
  interior,

  /// Наружная отделка (фасад, кровля, фундамент, утепление)
  exterior;

  /// Получить ключ перевода для категории
  String get translationKey {
    switch (this) {
      case CalculatorCategory.interior:
        return 'category.interior';
      case CalculatorCategory.exterior:
        return 'category.exterior';
    }
  }

  /// Получить иконку для категории
  String get iconName {
    switch (this) {
      case CalculatorCategory.interior:
        return 'interior';
      case CalculatorCategory.exterior:
        return 'exterior';
    }
  }
}
