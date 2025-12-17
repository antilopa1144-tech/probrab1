import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/data/work_catalog.dart';

void main() {
  group('Calculator Availability Test', () {
    test('all calculator IDs in work_catalog should be available in V2 registry', () {
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

      // Проверяем наличие в V2-реестре
      final List<String> missing = [];
      for (final id in catalogCalculatorIds) {
        if (!CalculatorRegistry.exists(id)) {
          missing.add(id);
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'Некоторые калькуляторы из work_catalog отсутствуют в реестре V2: ${missing.join(', ')}',
      );
    });
  });
}
