/// Агрегатор всех калькуляторов приложения.
///
/// Этот файл заменяет старый definitions.dart и импортирует все категории.
/// Используйте его вместо прямого импорта definitions.dart:
///
/// ```dart
/// import 'package:probrab_ai/domain/calculators/registry/all_calculators.dart';
/// ```
library;

// Экспортируем базовые классы
export 'calculator_definitions_base.dart';

// TODO: Раскомментируйте по мере создания файлов категорий
// export 'foundation_calculators.dart';
// export 'wall_calculators.dart';
// export 'floor_calculators.dart';
// export 'ceiling_calculators.dart';
// export 'partition_calculators.dart';
// export 'insulation_calculators.dart';
// export 'exterior_calculators.dart';
// export 'roofing_calculators.dart';
// export 'engineering_calculators.dart';
// export 'bathroom_calculators.dart';
// export 'mixture_calculators.dart';
// export 'windows_doors_calculators.dart';
// export 'sound_insulation_calculators.dart';
// export 'structure_calculators.dart';

/// ВРЕМЕННО: импортируем старый файл для обратной совместимости
/// После завершения рефакторинга удалите эту строку
import '../definitions.dart' as old;

/// Все калькуляторы приложения (временная совместимость).
///
/// ROADMAP рефакторинга:
/// 1. Создайте файлы категорий в registry/
/// 2. Раскомментируйте соответствующие export выше
/// 3. Замените использование old.* на прямые списки
/// 4. Удалите definitions.dart после полной миграции
final List<old.CalculatorDefinition> calculators = old.calculators;
final List<old.CalculatorDefinition> foundationCalculators = old.foundationCalculators;
final List<old.CalculatorDefinition> wallCalculators = old.wallCalculators;
final List<old.CalculatorDefinition> floorCalculators = old.floorCalculators;
final List<old.CalculatorDefinition> ceilingCalculators = old.ceilingCalculators;
final List<old.CalculatorDefinition> partitionCalculators = old.partitionCalculators;
final List<old.CalculatorDefinition> insulationCalculators = old.insulationCalculators;
final List<old.CalculatorDefinition> exteriorCalculators = old.exteriorCalculators;
final List<old.CalculatorDefinition> roofingCalculators = old.roofingCalculators;
final List<old.CalculatorDefinition> engineeringCalculators = old.engineeringCalculators;
final List<old.CalculatorDefinition> bathroomCalculators = old.bathroomCalculators;
final List<old.CalculatorDefinition> mixCalculators = old.mixCalculators;
final List<old.CalculatorDefinition> windowsDoorsCalculators = old.windowsDoorsCalculators;
final List<old.CalculatorDefinition> soundInsulationCalculators = old.soundInsulationCalculators;
final List<old.CalculatorDefinition> structureCalculators = old.structureCalculators;

/// Вспомогательная функция для поиска калькулятора по ID
old.CalculatorDefinition? findCalculatorById(String id) {
  try {
    return calculators.firstWhere((calc) => calc.id == id);
  } catch (_) {
    return null;
  }
}
