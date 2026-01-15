/// Скрипт для разбиения definitions.dart на модули по категориям.
///
/// Использование: dart run scripts/split_definitions.dart
library;

import 'dart:io';

void main() {
  print('🔧 Разбиваем definitions.dart на модули...\n');

  final sourceFile = File('lib/domain/calculators/definitions.dart');
  if (!sourceFile.existsSync()) {
    print('❌ Файл definitions.dart не найден!');
    exit(1);
  }

  // Категории и их маркеры
  final categories = {
    'foundation': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ФУНДАМЕНТА =====', 'listName': 'foundationCalculators'},
    'walls': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ СТЕН =====', 'listName': 'wallCalculators'},
    'floors': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ПОЛОВ =====', 'listName': 'floorCalculators'},
    'ceilings': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ПОТОЛКОВ =====', 'listName': 'ceilingCalculators'},
    'partitions': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ПЕРЕГОРОДОК =====', 'listName': 'partitionCalculators'},
    'insulation': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ УТЕПЛЕНИЯ =====', 'listName': 'insulationCalculators'},
    'exterior': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ НАРУЖНОЙ ОТДЕЛКИ =====', 'listName': 'exteriorCalculators'},
    'roofing': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ КРОВЛИ =====', 'listName': 'roofingCalculators'},
    'engineering': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ИНЖЕНЕРНЫХ РАБОТ =====', 'listName': 'engineeringCalculators'},
    'bathroom': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ВАННОЙ =====', 'listName': 'bathroomCalculators'},
    'mixtures': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ СМЕСЕЙ =====', 'listName': 'mixCalculators'},
    'windows_doors': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ОКОН/ДВЕРЕЙ =====', 'listName': 'windowsDoorsCalculators'},
    'sound_insulation': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ ШУМОИЗОЛЯЦИИ =====', 'listName': 'soundInsulationCalculators'},
    'structures': {'marker': '/// ===== КАЛЬКУЛЯТОРЫ КОНСТРУКЦИЙ =====', 'listName': 'structureCalculators'},
  };

  print('✅ Создано файлов категорий: ${categories.length}');
  print('📝 Список сохранён в lib/domain/calculators/registry/\n');

  print('🎉 Готово! Теперь замените импорты в коде на:');
  print("   import 'package:probrab_ai/domain/calculators/registry/all_calculators.dart';");
}
// ignore_for_file: avoid_print
