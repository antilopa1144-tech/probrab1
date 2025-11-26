/// Оптимизация отходов материала.
class WasteOptimization {
  final String materialId;
  final double requiredArea;
  final double standardSize; // стандартный размер материала
  final double wastePercentage;
  final double optimizedQuantity;
  final double wasteReduction; // процент снижения отходов
  final List<String> recommendations;

  const WasteOptimization({
    required this.materialId,
    required this.requiredArea,
    required this.standardSize,
    required this.wastePercentage,
    required this.optimizedQuantity,
    required this.wasteReduction,
    this.recommendations = const [],
  });

  /// Рассчитать оптимальное количество с учётом отходов.
  factory WasteOptimization.calculate({
    required String materialId,
    required double requiredArea,
    required double standardSize,
    double baseWaste = 10.0, // базовый процент отходов
  }) {
    // Улучшенный расчёт с учётом оптимальной раскройки
    final optimizedQuantity = _optimizeCutting(requiredArea, standardSize);
    final optimizedWaste = ((optimizedQuantity * standardSize - requiredArea) / 
        (optimizedQuantity * standardSize) * 100.0).clamp(0.0, 100.0);
    
    final wasteReduction = baseWaste - optimizedWaste;
    
    final recommendations = <String>[];
    if (wasteReduction > 2) {
      recommendations.add('Используйте оптимальную раскройку для снижения отходов');
    }
    if (standardSize > requiredArea * 0.5) {
      recommendations.add('Рассмотрите материалы меньшего размера');
    }
    
    return WasteOptimization(
      materialId: materialId,
      requiredArea: requiredArea,
      standardSize: standardSize,
      wastePercentage: optimizedWaste,
      optimizedQuantity: optimizedQuantity,
      wasteReduction: wasteReduction,
      recommendations: recommendations,
    );
  }

  static double _optimizeCutting(double area, double standardSize) {
    // Простая оптимизация: округляем вверх с учётом эффективности раскройки
    final base = (area / standardSize).ceil();
    
    // Если остаток меньше 30% от стандартного размера, можно оптимизировать
    final remainder = (area / standardSize) % 1;
    if (remainder < 0.3 && base > 1) {
      // Можно использовать остатки от предыдущих листов
      return base - 0.2; // небольшое снижение
    }
    
    return base.toDouble();
  }
}

