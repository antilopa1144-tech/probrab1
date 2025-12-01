import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/data/work_catalog.dart';

void main() {
  group('Calculator Availability Test', () {
    test('all calculator IDs in work_catalog should be available in either V2 or legacy system', () {
      // Собираем все calculatorId из work_catalog
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

      // Проверяем наличие в обеих системах
      final List<String> missingInBoth = [];
      final List<String> inV2Only = [];
      final List<String> inLegacyOnly = [];
      final List<String> inBoth = [];

      for (final id in catalogCalculatorIds) {
        final existsInV2 = CalculatorRegistry.exists(id);
        final existsInLegacy = findCalculatorById(id) != null;

        if (!existsInV2 && !existsInLegacy) {
          missingInBoth.add(id);
        } else if (existsInV2 && !existsInLegacy) {
          inV2Only.add(id);
        } else if (!existsInV2 && existsInLegacy) {
          inLegacyOnly.add(id);
        } else {
          inBoth.add(id);
        }
      }

      // Выводим подробный отчет
      print('\n=== Calculator Availability Report ===');
      print('Total calculator IDs in work_catalog: ${catalogCalculatorIds.length}');
      print('');
      print('✅ Available in both systems: ${inBoth.length}');
      if (inBoth.isNotEmpty) {
        for (final id in inBoth) {
          print('  - $id');
        }
      }
      print('');
      print('🆕 Available in V2 only: ${inV2Only.length}');
      if (inV2Only.isNotEmpty) {
        for (final id in inV2Only) {
          print('  - $id');
        }
      }
      print('');
      print('📦 Available in Legacy only: ${inLegacyOnly.length}');
      if (inLegacyOnly.isNotEmpty) {
        for (final id in inLegacyOnly) {
          print('  - $id');
        }
      }
      print('');
      print('❌ MISSING IN BOTH: ${missingInBoth.length}');
      if (missingInBoth.isNotEmpty) {
        for (final id in missingInBoth) {
          print('  - $id');
        }
      }
      print('');
      print('Calculator IDs registered in CalculatorRegistry (V2): ${CalculatorRegistry.count}');
      print('Calculator IDs registered in Legacy system: ${calculators.length}');
      print('=========================================\n');

      // Тест падает, только если калькулятор отсутствует в обеих системах
      if (missingInBoth.isNotEmpty) {
        fail('❌ ${missingInBoth.length} calculator(s) are not available in any system:\n${missingInBoth.join('\n')}');
      } else {
        print('✅ All calculator IDs from work_catalog are available!');
      }
    });
  });
}
