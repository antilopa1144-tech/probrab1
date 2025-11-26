/// Расценка на работы.
class LaborRate {
  final String category; // категория работ
  final String region; // регион
  final double pricePerUnit; // цена за единицу
  final String unit; // м², м, шт
  final double minPrice; // минимальная стоимость
  final String? notes;

  const LaborRate({
    required this.category,
    required this.region,
    required this.pricePerUnit,
    required this.unit,
    this.minPrice = 0,
    this.notes,
  });
}

/// Расчёт трудозатрат.
class LaborCostCalculation {
  final String calculatorId;
  final double quantity;
  final LaborRate rate;
  final double totalCost;
  final int estimatedHours;
  final int estimatedDays;

  const LaborCostCalculation({
    required this.calculatorId,
    required this.quantity,
    required this.rate,
    required this.totalCost,
    required this.estimatedHours,
    required this.estimatedDays,
  });

  /// Создать расчёт на основе калькулятора.
  factory LaborCostCalculation.fromCalculator(
    String calculatorId,
    double quantity,
    LaborRate rate,
  ) {
    // Базовые нормы времени (часы на единицу)
    final hoursPerUnit = _getHoursPerUnit(calculatorId);
    final hours = (quantity * hoursPerUnit).ceil();
    final days = (hours / 8).ceil(); // 8 часов в день
    
    final cost = (quantity * rate.pricePerUnit).clamp(rate.minPrice, double.infinity);
    
    return LaborCostCalculation(
      calculatorId: calculatorId,
      quantity: quantity,
      rate: rate,
      totalCost: cost,
      estimatedHours: hours,
      estimatedDays: days,
    );
  }

  static double _getHoursPerUnit(String calculatorId) {
    // Базовые нормы времени для разных типов работ
    final rates = {
      'walls_paint': 0.5, // 0.5 часа на м²
      'walls_wallpaper': 0.8,
      'floors_laminate': 0.3,
      'floors_tile': 0.6,
      'floors_screed': 0.2,
      'ceilings_paint': 0.4,
      'ceilings_stretch': 2.0, // сложнее
      'partitions_gkl': 1.0,
    };
    
    return rates[calculatorId] ?? 0.5; // по умолчанию 0.5 часа
  }
}

