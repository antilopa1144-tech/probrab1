/// Расчёт экономии при самостоятельной работе vs найм мастеров.
class SavingsCalculation {
  final String workType;
  final double materialCost;
  final double laborCost;
  final double selfWorkTimeHours;
  final double hourlyRate;
  final double savings;
  final double timeCost;
  final bool isWorthIt;

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
    double hourlyRate = 0,
  }) {
    final timeCost = selfWorkTimeHours * hourlyRate;
    final totalSelfCost = materialCost + timeCost;
    final totalHiredCost = materialCost + laborCost;
    final savings = totalHiredCost - totalSelfCost;
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

  String get recommendationKey {
    if (!isWorthIt) {
      return 'savings.recommendation.hire';
    }
    if (savings > laborCost * 0.5) {
      return 'savings.recommendation.self_high';
    }
    return 'savings.recommendation.self_small';
  }

  Map<String, String>? get recommendationParams {
    if (recommendationKey == 'savings.recommendation.self_high') {
      return {'amount': savings.toStringAsFixed(0)};
    }
    return null;
  }
}

/// Расчёт окупаемости материалов.
class MaterialPayback {
  final String materialId;
  final String materialName;
  final double initialCost;
  final double alternativeCost;
  final int durabilityYears;
  final int alternativeDurabilityYears;
  final double annualSavings;
  final double paybackYears;

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
    final costPerYear = initialCost / durabilityYears;
    final altCostPerYear = alternativeCost / alternativeDurabilityYears;

    final annualSavings = altCostPerYear - costPerYear;
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

  String get recommendationKey {
    if (paybackYears.isInfinite) {
      return 'savings.payback.alternative';
    }
    if (paybackYears < 2) {
      return 'savings.payback.excellent';
    }
    if (paybackYears < 5) {
      return 'savings.payback.good';
    }
    return 'savings.payback.long_term';
  }

  Map<String, String>? get recommendationParams {
    if (paybackYears.isInfinite) {
      return null;
    }
    return {'years': paybackYears.toStringAsFixed(1)};
  }
}
