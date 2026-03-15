/// Оптимизация отходов материала.
class WasteOptimization {
  final String materialId;
  final double requiredArea;
  final double standardSize;
  final double wastePercentage;
  final double optimizedQuantity;
  final double wasteReduction;
  final List<String> recommendationKeys;

  const WasteOptimization({
    required this.materialId,
    required this.requiredArea,
    required this.standardSize,
    required this.wastePercentage,
    required this.optimizedQuantity,
    required this.wasteReduction,
    this.recommendationKeys = const [],
  });

  /// Рассчитать оптимальное количество с учётом отходов.
  factory WasteOptimization.calculate({
    required String materialId,
    required double requiredArea,
    required double standardSize,
    double baseWaste = 10.0,
  }) {
    final optimizedQuantity = _optimizeCutting(requiredArea, standardSize);
    final optimizedWaste = ((optimizedQuantity * standardSize - requiredArea) /
            (optimizedQuantity * standardSize) *
            100.0)
        .clamp(0.0, 100.0);

    final wasteReduction = baseWaste - optimizedWaste;

    final recommendationKeys = <String>[];
    if (wasteReduction > 2) {
      recommendationKeys.add('waste.recommendation.optimize');
    }
    if (standardSize > requiredArea * 0.5) {
      recommendationKeys.add('waste.recommendation.smaller_size');
    }

    return WasteOptimization(
      materialId: materialId,
      requiredArea: requiredArea,
      standardSize: standardSize,
      wastePercentage: optimizedWaste,
      optimizedQuantity: optimizedQuantity,
      wasteReduction: wasteReduction,
      recommendationKeys: recommendationKeys,
    );
  }

  static double _optimizeCutting(double area, double standardSize) {
    final base = (area / standardSize).ceil();
    final remainder = (area / standardSize) % 1;
    if (remainder < 0.3 && base > 1) {
      return base - 0.2;
    }
    return base.toDouble();
  }
}
