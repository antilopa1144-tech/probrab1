/// Расчёт экономии при самостоятельной работе vs найм мастеров.
class SavingsCalculation {
  final String workType;
  final double materialCost;
  final double laborCost; // стоимость работы мастеров
  final double selfWorkTimeHours; // время самостоятельной работы
  final double hourlyRate; // ваша почасовая ставка (если работаете)
  final double savings; // экономия
  final double timeCost; // стоимость вашего времени
  final bool isWorthIt; // стоит ли делать самому

  const SavingsCalculation({
    required this.workType,
    required this.materialCost,
    required this.laborCost,
    required this.selfWorkTimeHours,
    required this.hourlyRate,
    required this.savings,
    required this.timeCost,
    required this.isWorthIt,
  });

  /// Рассчитать экономию.
  factory SavingsCalculation.calculate({
    required String workType,
    required double materialCost,
    required double laborCost,
    required double selfWorkTimeHours,
    double hourlyRate = 0, // если 0, не учитываем стоимость времени
  }) {
    final timeCost = selfWorkTimeHours * hourlyRate;
    final totalSelfCost = materialCost + timeCost;
    final totalHiredCost = materialCost + laborCost;
    final savings = totalHiredCost - totalSelfCost;
    
    // Стоит делать самому, если экономия положительная и разумная
    final isWorthIt = savings > 0 && (hourlyRate == 0 || savings > timeCost * 0.5);
    
    return SavingsCalculation(
      workType: workType,
      materialCost: materialCost,
      laborCost: laborCost,
      selfWorkTimeHours: selfWorkTimeHours,
      hourlyRate: hourlyRate,
      savings: savings,
      timeCost: timeCost,
      isWorthIt: isWorthIt,
    );
  }

  /// Получить рекомендацию.
  String getRecommendation() {
    if (!isWorthIt) {
      return 'Рекомендуется нанять мастеров. Экономия незначительна или отсутствует.';
    }
    
    if (savings > laborCost * 0.5) {
      return 'Выгодно делать самостоятельно. Экономия составляет ${savings.toStringAsFixed(0)} ₽.';
    }
    
    return 'Можно делать самостоятельно, но экономия небольшая.';
  }
}

/// Расчёт окупаемости материалов.
class MaterialPayback {
  final String materialId;
  final String materialName;
  final double initialCost;
  final double alternativeCost; // стоимость альтернативы
  final int durabilityYears;
  final int alternativeDurabilityYears;
  final double annualSavings;
  final double paybackYears; // окупаемость в годах

  const MaterialPayback({
    required this.materialId,
    required this.materialName,
    required this.initialCost,
    required this.alternativeCost,
    required this.durabilityYears,
    required this.alternativeDurabilityYears,
    required this.annualSavings,
    required this.paybackYears,
  });

  /// Рассчитать окупаемость.
  factory MaterialPayback.calculate({
    required String materialId,
    required String materialName,
    required double initialCost,
    required double alternativeCost,
    required int durabilityYears,
    required int alternativeDurabilityYears,
  }) {
    // Стоимость в год для каждого варианта
    final costPerYear = initialCost / durabilityYears;
    final altCostPerYear = alternativeCost / alternativeDurabilityYears;
    
    final annualSavings = altCostPerYear - costPerYear;
    
    // Окупаемость: разница в начальной стоимости / годовая экономия
    final costDifference = initialCost - alternativeCost;
    final paybackYears = annualSavings > 0 
        ? (costDifference / annualSavings).abs()
        : double.infinity;
    
    return MaterialPayback(
      materialId: materialId,
      materialName: materialName,
      initialCost: initialCost,
      alternativeCost: alternativeCost,
      durabilityYears: durabilityYears,
      alternativeDurabilityYears: alternativeDurabilityYears,
      annualSavings: annualSavings,
      paybackYears: paybackYears,
    );
  }

  /// Получить рекомендацию.
  String getRecommendation() {
    if (paybackYears.isInfinite) {
      return 'Альтернативный вариант дешевле в долгосрочной перспективе.';
    }
    
    if (paybackYears < 2) {
      return 'Отличная инвестиция! Окупится за ${paybackYears.toStringAsFixed(1)} лет.';
    }
    
    if (paybackYears < 5) {
      return 'Хорошая инвестиция. Окупится за ${paybackYears.toStringAsFixed(1)} лет.';
    }
    
    return 'Долгосрочная инвестиция. Окупится за ${paybackYears.toStringAsFixed(1)} лет.';
  }
}

