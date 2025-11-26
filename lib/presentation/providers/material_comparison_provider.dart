import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/material_comparison.dart';

/// Провайдер для сравнения материалов.
class MaterialComparisonNotifier extends StateNotifier<List<MaterialComparison>> {
  MaterialComparisonNotifier() : super([]);

  void addComparison(MaterialComparison comparison) {
    state = [...state, comparison];
  }

  void removeComparison(String calculatorId) {
    state = state.where((c) => c.calculatorId != calculatorId).toList();
  }

  MaterialComparison? getComparison(String calculatorId) {
    try {
      return state.firstWhere((c) => c.calculatorId == calculatorId);
    } catch (_) {
      return null;
    }
  }
}

final materialComparisonProvider = 
    StateNotifierProvider<MaterialComparisonNotifier, List<MaterialComparison>>(
  (ref) => MaterialComparisonNotifier(),
);

