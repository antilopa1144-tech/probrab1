import '../models/calculator_definition_v2.dart';
import 'paint_calculator_v2.dart';

/// Реестр всех калькуляторов приложения.
class CalculatorRegistry {
  /// Все доступные калькуляторы (версия 2)
  static final List<CalculatorDefinitionV2> allCalculators = [
    paintCalculatorV2,
    // Здесь будут добавляться другие калькуляторы по мере миграции
  ];

  /// Получить калькулятор по ID
  static CalculatorDefinitionV2? getById(String id) {
    try {
      return allCalculators.firstWhere((calc) => calc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Получить калькуляторы по категории
  static List<CalculatorDefinitionV2> getByCategory(dynamic category) {
    return allCalculators.where((calc) => calc.category == category).toList();
  }

  /// Получить популярные калькуляторы
  static List<CalculatorDefinitionV2> getPopular({int limit = 10}) {
    final sorted = List<CalculatorDefinitionV2>.from(allCalculators);
    sorted.sort((a, b) => b.popularity.compareTo(a.popularity));
    return sorted.take(limit).toList();
  }

  /// Поиск калькуляторов по запросу
  static List<CalculatorDefinitionV2> search(String query) {
    if (query.isEmpty) return allCalculators;

    final lowerQuery = query.toLowerCase();
    return allCalculators.where((calc) {
      return calc.titleKey.toLowerCase().contains(lowerQuery) ||
          calc.id.toLowerCase().contains(lowerQuery) ||
          calc.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Получить избранные калькуляторы
  static List<CalculatorDefinitionV2> getFavorites() {
    return allCalculators.where((calc) => calc.isFavorite).toList();
  }

  /// Получить калькуляторы по сложности
  static List<CalculatorDefinitionV2> getByComplexity(int complexity) {
    return allCalculators.where((calc) => calc.complexity == complexity).toList();
  }

  /// Количество калькуляторов
  static int get count => allCalculators.length;

  /// Проверить существование калькулятора
  static bool exists(String id) {
    return allCalculators.any((calc) => calc.id == id);
  }
}
