/// Материал для сравнения.
class MaterialOption {
  final String id;
  final String name;
  final String category;
  final double pricePerUnit;
  final String unit; // м², м, шт, кг
  final Map<String, dynamic> properties; // характеристики
  final int durabilityYears; // срок службы
  final String? supplier;
  final String? notes;

  const MaterialOption({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    this.properties = const {},
    this.durabilityYears = 10,
    this.supplier,
    this.notes,
  });

  /// Рассчитать общую стоимость для проекта.
  double calculateTotalCost(double quantity) {
    return pricePerUnit * quantity;
  }

  /// Рассчитать стоимость за год службы.
  double getCostPerYear(double quantity) {
    if (durabilityYears <= 0) return double.infinity;
    return calculateTotalCost(quantity) / durabilityYears;
  }
}

/// Результат сравнения материалов.
class MaterialComparison {
  final String calculatorId;
  final double requiredQuantity;
  final List<MaterialOption> options;
  final MaterialOption? recommended;

  const MaterialComparison({
    required this.calculatorId,
    required this.requiredQuantity,
    required this.options,
    this.recommended,
  });

  /// Получить самое дешёвое решение.
  MaterialOption? get cheapest {
    if (options.isEmpty) return null;
    return options.reduce((a, b) =>
        a.calculateTotalCost(requiredQuantity) <
                b.calculateTotalCost(requiredQuantity)
            ? a
            : b);
  }

  /// Получить самое долговечное решение.
  MaterialOption? get mostDurable {
    if (options.isEmpty) return null;
    return options.reduce((a, b) =>
        a.durabilityYears > b.durabilityYears ? a : b);
  }

  /// Получить оптимальное решение (баланс цена/качество).
  MaterialOption? get optimal {
    if (options.isEmpty) return null;
    
    // Считаем индекс: цена/год службы
    MaterialOption? best;
    double bestIndex = double.infinity;
    
    for (final option in options) {
      final index = option.getCostPerYear(requiredQuantity);
      if (index < bestIndex) {
        bestIndex = index;
        best = option;
      }
    }
    
    return best;
  }
}

