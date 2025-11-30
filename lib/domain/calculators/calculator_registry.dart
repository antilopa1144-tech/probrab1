import '../models/calculator_definition_v2.dart';
import 'paint_calculator_v2.dart';
import 'laminate_calculator_v2.dart';
import 'screed_calculator_v2.dart';
import 'tile_calculator_v2.dart';
import 'wallpaper_calculator_v2.dart';
import 'strip_foundation_calculator_v2.dart';
import 'slab_foundation_calculator_v2.dart';
import 'metal_roofing_calculator_v2.dart';
import 'soft_roofing_calculator_v2.dart';
import 'warm_floor_calculator_v2.dart';
import 'parquet_calculator_v2.dart';
import 'gkl_ceiling_calculator_v2.dart';
import 'bathroom_tile_calculator_v2.dart';

/// Реестр всех калькуляторов приложения.
///
/// Централизованное хранилище всех доступных калькуляторов V2.
/// Предоставляет методы для поиска, фильтрации и получения калькуляторов.
///
/// ## Основные функции:
///
/// - **Поиск по ID**: `getById(String id)` - получить калькулятор по уникальному идентификатору
/// - **Фильтрация по категории**: `getByCategory(CalculatorCategory)` - получить все калькуляторы категории
/// - **Популярные**: `getPopular({int limit})` - получить топ популярных калькуляторов
/// - **Поиск**: `search(String query)` - поиск по названию, ID или тегам
/// - **Избранные**: `getFavorites()` - получить избранные калькуляторы
/// - **По сложности**: `getByComplexity(int)` - фильтр по уровню сложности
///
/// ## Примеры использования:
///
/// ```dart
/// // Получить калькулятор по ID
/// final calc = CalculatorRegistry.getById('wall_paint');
///
/// // Найти все калькуляторы для полов
/// final floorCalcs = CalculatorRegistry.getByCategory(CalculatorCategory.flooring);
///
/// // Получить топ-5 популярных
/// final popular = CalculatorRegistry.getPopular(limit: 5);
///
/// // Поиск по запросу
/// final results = CalculatorRegistry.search('плитка');
/// ```
///
/// ## Добавление новых калькуляторов:
///
/// 1. Создайте файл `*_calculator_v2.dart` в `lib/domain/calculators/`
/// 2. Определите `final calculatorNameV2 = CalculatorDefinitionV2(...)`
/// 3. Импортируйте файл в `calculator_registry.dart`
/// 4. Добавьте в список `allCalculators`
class CalculatorRegistry {
  /// Все доступные калькуляторы (версия 2)
  static final List<CalculatorDefinitionV2> allCalculators = [
    // Фундамент
    stripFoundationCalculatorV2,
    slabFoundationCalculatorV2,
    
    // Отделка стен
    paintCalculatorV2,
    wallpaperCalculatorV2,
    
    // Полы
    laminateCalculatorV2,
    screedCalculatorV2,
    tileCalculatorV2,
    
    // Кровля
    metalRoofingCalculatorV2,
    softRoofingCalculatorV2,
    
    // Инженерные системы
    warmFloorCalculatorV2,
    
    // Полы (дополнительные)
    parquetCalculatorV2,
    
    // Потолки
    gklCeilingCalculatorV2,
    
    // Отделка (дополнительные)
    bathroomTileCalculatorV2,
    
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
