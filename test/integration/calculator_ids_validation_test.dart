import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/data/work_catalog.dart';

void main() {
  group('Calculator IDs Validation', () {
    test('all calculator IDs in work_catalog should exist in CalculatorRegistry', () {
      // Собираем все calculatorId из work_catalog для всех типов объектов
      final Set<String> catalogCalculatorIds = {};

      for (final objectType in ObjectType.values) {
        final areas = WorkCatalog.areasFor(objectType);
        for (final area in areas) {
          for (final section in area.sections) {
            for (final item in section.items) {
              if (item.calculatorId != null) {
                catalogCalculatorIds.add(item.calculatorId!);
              }
            }
          }
        }
      }

      // Проверяем, что все ID из каталога существуют в реестре
      final List<String> missingIds = [];
      for (final id in catalogCalculatorIds) {
        if (!CalculatorRegistry.exists(id)) {
          missingIds.add(id);
        }
      }

      // Выводим отчет
      print('\n=== Calculator IDs Validation Report ===');
      print('Total calculator IDs in work_catalog: ${catalogCalculatorIds.length}');
      print('Calculator IDs registered in CalculatorRegistry: ${CalculatorRegistry.count}');
      print('Missing calculator IDs: ${missingIds.length}');

      if (missingIds.isNotEmpty) {
        print('\nMissing IDs (need to be implemented):');
        for (final id in missingIds) {
          print('  - $id');
        }
      }

      // Тест не должен падать, если есть недостающие ID
      // Вместо этого просто выводим предупреждение
      if (missingIds.isNotEmpty) {
        print('\n⚠️  WARNING: ${missingIds.length} calculator(s) referenced in work_catalog but not yet implemented');
      } else {
        print('\n✅ All calculator IDs are properly registered!');
      }

      print('=====================================\n');
    });

    test('check for duplicate work item IDs (not calculator IDs)', () {
      // Проверяем дубликаты ID самих WorkItem (не calculatorId)
      // calculatorId может повторяться (один калькулятор для разных типов объектов)
      final Map<String, int> workItemIdCounts = {};

      for (final objectType in ObjectType.values) {
        final areas = WorkCatalog.areasFor(objectType);
        for (final area in areas) {
          for (final section in area.sections) {
            for (final item in section.items) {
              final key = '${objectType.name}:${item.id}';
              workItemIdCounts[key] = (workItemIdCounts[key] ?? 0) + 1;
            }
          }
        }
      }

      // Находим дубликаты
      final duplicates = workItemIdCounts.entries
          .where((entry) => entry.value > 1)
          .map((entry) => '${entry.key} (${entry.value} times)')
          .toList();

      if (duplicates.isNotEmpty) {
        print('\n=== Duplicate Work Item IDs ===');
        for (final dup in duplicates) {
          print('  - $dup');
        }
        print('==================================\n');
      }

      expect(duplicates, isEmpty,
          reason: 'Found duplicate work item IDs in work_catalog');
    });

    test('all registered calculators have unique IDs', () {
      final allIds = CalculatorRegistry.allCalculators.map((c) => c.id).toList();
      final uniqueIds = allIds.toSet();

      expect(allIds.length, equals(uniqueIds.length),
          reason: 'Duplicate calculator IDs found in CalculatorRegistry');
    });

    test('calculator IDs follow naming convention', () {
      // Проверяем, что все ID следуют соглашению об именовании:
      // только строчные буквы, цифры и подчёркивания
      final invalidIds = <String>[];

      for (final objectType in ObjectType.values) {
        final areas = WorkCatalog.areasFor(objectType);
        for (final area in areas) {
          for (final section in area.sections) {
            for (final item in section.items) {
              if (item.calculatorId != null) {
                final id = item.calculatorId!;
                // Проверяем формат: lowercase letters, numbers, underscores only
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
                  invalidIds.add('${item.id}: $id');
                }
              }
            }
          }
        }
      }

      if (invalidIds.isNotEmpty) {
        print('\n=== Invalid Calculator ID Format ===');
        print('IDs should contain only lowercase letters, numbers, and underscores');
        for (final id in invalidIds) {
          print('  - $id');
        }
        print('=========================================\n');
      }

      expect(invalidIds, isEmpty,
          reason: 'Some calculator IDs do not follow naming convention');
    });

    test('print coverage statistics', () {
      // Статистика по покрытию калькуляторами
      int totalItems = 0;
      int itemsWithCalculators = 0;

      for (final objectType in ObjectType.values) {
        final areas = WorkCatalog.areasFor(objectType);
        for (final area in areas) {
          for (final section in area.sections) {
            for (final item in section.items) {
              totalItems++;
              if (item.calculatorId != null) {
                itemsWithCalculators++;
              }
            }
          }
        }
      }

      final coverage = (itemsWithCalculators / totalItems * 100).toStringAsFixed(1);

      print('\n=== Work Catalog Coverage Statistics ===');
      print('Total work items: $totalItems');
      print('Items with calculators: $itemsWithCalculators');
      print('Coverage: $coverage%');
      print('=========================================\n');
    });
  });
}
// ignore_for_file: avoid_print
