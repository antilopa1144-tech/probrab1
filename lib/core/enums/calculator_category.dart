/// Категории калькуляторов.
enum CalculatorCategory {
  /// Фундамент
  foundation,

  /// Стены
  walls,

  /// Кровля
  roofing,

  /// Полы
  flooring,

  /// Потолки
  ceilings,

  /// Отделка стен
  wallFinishing,

  /// Утепление
  insulation,

  /// Инженерные системы
  engineering,

  /// Окна и двери
  windowsDoors,

  /// Фасад
  facade,

  /// Вспомогательные конструкции
  auxiliary,

  /// Прочее
  other;

  /// Получить ключ перевода для категории
  String get translationKey {
    switch (this) {
      case CalculatorCategory.foundation:
        return 'category.foundation';
      case CalculatorCategory.walls:
        return 'category.walls';
      case CalculatorCategory.roofing:
        return 'category.roofing';
      case CalculatorCategory.flooring:
        return 'category.flooring';
      case CalculatorCategory.ceilings:
        return 'category.ceilings';
      case CalculatorCategory.wallFinishing:
        return 'category.wall_finishing';
      case CalculatorCategory.insulation:
        return 'category.insulation';
      case CalculatorCategory.engineering:
        return 'category.engineering';
      case CalculatorCategory.windowsDoors:
        return 'category.windows_doors';
      case CalculatorCategory.facade:
        return 'category.facade';
      case CalculatorCategory.auxiliary:
        return 'category.auxiliary';
      case CalculatorCategory.other:
        return 'category.other';
    }
  }

  /// Получить иконку для категории
  String get iconName {
    switch (this) {
      case CalculatorCategory.foundation:
        return 'foundation';
      case CalculatorCategory.walls:
        return 'walls';
      case CalculatorCategory.roofing:
        return 'roofing';
      case CalculatorCategory.flooring:
        return 'flooring';
      case CalculatorCategory.ceilings:
        return 'ceilings';
      case CalculatorCategory.wallFinishing:
        return 'wall_finishing';
      case CalculatorCategory.insulation:
        return 'insulation';
      case CalculatorCategory.engineering:
        return 'engineering';
      case CalculatorCategory.windowsDoors:
        return 'windows_doors';
      case CalculatorCategory.facade:
        return 'facade';
      case CalculatorCategory.auxiliary:
        return 'auxiliary';
      case CalculatorCategory.other:
        return 'other';
    }
  }
}
