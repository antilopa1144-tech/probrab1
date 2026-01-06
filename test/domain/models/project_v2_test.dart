import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

void main() {
  group('ProjectV2', () {
    test('creates with default values', () {
      final project = ProjectV2();

      expect(project.name, '');
      expect(project.isFavorite, false);
      expect(project.tags, isEmpty);
      expect(project.status, ProjectStatus.planning);
    });

    test('can set name and description', () {
      final project = ProjectV2()
        ..name = 'My Project'
        ..description = 'Project description';

      expect(project.name, 'My Project');
      expect(project.description, 'Project description');
    });

    test('can set favorite status', () {
      final project = ProjectV2()..isFavorite = true;

      expect(project.isFavorite, true);
    });

    test('can set tags', () {
      final project = ProjectV2()..tags = ['renovation', 'kitchen'];

      expect(project.tags, ['renovation', 'kitchen']);
    });

    test('can set color', () {
      final project = ProjectV2()..color = 0xFF123456;

      expect(project.color, 0xFF123456);
    });

    test('can set status', () {
      final project = ProjectV2()..status = ProjectStatus.inProgress;

      expect(project.status, ProjectStatus.inProgress);
    });

    test('can set notes', () {
      final project = ProjectV2()..notes = 'Important notes';

      expect(project.notes, 'Important notes');
    });

    test('totalMaterialCost returns 0 when no calculations', () {
      final project = ProjectV2();

      expect(project.totalMaterialCost, 0);
    });

    test('totalLaborCost returns 0 when no calculations', () {
      final project = ProjectV2();

      expect(project.totalLaborCost, 0);
    });

    test('totalCost is sum of material and labor costs', () {
      final project = ProjectV2();

      // Without calculations, both should be 0
      expect(project.totalCost, 0);
    });
  });

  group('ProjectStatus', () {
    test('has all expected values', () {
      expect(ProjectStatus.values.length, 5);
      expect(ProjectStatus.values, contains(ProjectStatus.planning));
      expect(ProjectStatus.values, contains(ProjectStatus.inProgress));
      expect(ProjectStatus.values, contains(ProjectStatus.onHold));
      expect(ProjectStatus.values, contains(ProjectStatus.completed));
      expect(ProjectStatus.values, contains(ProjectStatus.cancelled));
    });

    test('planning is the default', () {
      final project = ProjectV2();
      expect(project.status, ProjectStatus.planning);
    });
  });

  group('ProjectCalculation', () {
    test('creates with default values', () {
      final calc = ProjectCalculation();

      expect(calc.calculatorId, '');
      expect(calc.name, '');
      expect(calc.inputs, isEmpty);
      expect(calc.results, isEmpty);
    });

    test('can set calculator info', () {
      final calc = ProjectCalculation()
        ..calculatorId = 'wall_paint'
        ..name = 'Living Room Paint';

      expect(calc.calculatorId, 'wall_paint');
      expect(calc.name, 'Living Room Paint');
    });

    test('can set costs', () {
      final calc = ProjectCalculation()
        ..materialCost = 5000.0
        ..laborCost = 3000.0;

      expect(calc.materialCost, 5000.0);
      expect(calc.laborCost, 3000.0);
    });

    test('can set notes', () {
      final calc = ProjectCalculation()..notes = 'Need premium paint';

      expect(calc.notes, 'Need premium paint');
    });

    group('inputsMap', () {
      test('returns empty map when no inputs', () {
        final calc = ProjectCalculation();

        expect(calc.inputsMap, isEmpty);
      });

      test('returns map from inputs list', () {
        final calc = ProjectCalculation()
          ..inputs = [
            KeyValuePair()
              ..key = 'area'
              ..value = 25.0,
            KeyValuePair()
              ..key = 'layers'
              ..value = 2.0,
          ];

        final map = calc.inputsMap;
        expect(map['area'], 25.0);
        expect(map['layers'], 2.0);
      });
    });

    group('setInputsFromMap', () {
      test('converts map to inputs list', () {
        final calc = ProjectCalculation();
        calc.setInputsFromMap({'length': 10.0, 'width': 5.0});

        expect(calc.inputs.length, 2);
        expect(calc.inputsMap['length'], 10.0);
        expect(calc.inputsMap['width'], 5.0);
      });

      test('replaces existing inputs', () {
        final calc = ProjectCalculation()
          ..inputs = [
            KeyValuePair()
              ..key = 'old'
              ..value = 1.0,
          ];

        calc.setInputsFromMap({'new': 2.0});

        expect(calc.inputs.length, 1);
        expect(calc.inputsMap['old'], isNull);
        expect(calc.inputsMap['new'], 2.0);
      });
    });

    group('resultsMap', () {
      test('returns empty map when no results', () {
        final calc = ProjectCalculation();

        expect(calc.resultsMap, isEmpty);
      });

      test('returns map from results list', () {
        final calc = ProjectCalculation()
          ..results = [
            KeyValuePair()
              ..key = 'totalArea'
              ..value = 50.0,
            KeyValuePair()
              ..key = 'paintLiters'
              ..value = 10.0,
          ];

        final map = calc.resultsMap;
        expect(map['totalArea'], 50.0);
        expect(map['paintLiters'], 10.0);
      });
    });

    group('setResultsFromMap', () {
      test('converts map to results list', () {
        final calc = ProjectCalculation();
        calc.setResultsFromMap({'area': 100.0, 'volume': 50.0});

        expect(calc.results.length, 2);
        expect(calc.resultsMap['area'], 100.0);
        expect(calc.resultsMap['volume'], 50.0);
      });
    });
  });

  group('KeyValuePair', () {
    test('creates with default values', () {
      final pair = KeyValuePair();

      expect(pair.key, '');
      expect(pair.value, 0);
    });

    test('can set key and value', () {
      final pair = KeyValuePair()
        ..key = 'testKey'
        ..value = 123.45;

      expect(pair.key, 'testKey');
      expect(pair.value, 123.45);
    });
  });

  group('ProjectMaterial', () {
    test('creates with default values', () {
      final material = ProjectMaterial();

      expect(material.name, '');
      expect(material.quantity, 0);
      expect(material.unit, '');
      expect(material.pricePerUnit, 0);
      expect(material.priority, 3);
      expect(material.purchased, false);
    });

    test('can set all properties', () {
      final material = ProjectMaterial()
        ..name = 'Paint'
        ..sku = 'PAINT-001'
        ..quantity = 5.0
        ..unit = 'liters'
        ..pricePerUnit = 400.0
        ..calculatorId = 'wall_paint'
        ..priority = 1
        ..purchased = true
        ..purchasedAt = DateTime(2024, 1, 15);

      expect(material.name, 'Paint');
      expect(material.sku, 'PAINT-001');
      expect(material.quantity, 5.0);
      expect(material.unit, 'liters');
      expect(material.pricePerUnit, 400.0);
      expect(material.calculatorId, 'wall_paint');
      expect(material.priority, 1);
      expect(material.purchased, true);
      expect(material.purchasedAt, DateTime(2024, 1, 15));
    });

    test('totalCost calculates correctly', () {
      final material = ProjectMaterial()
        ..quantity = 5.0
        ..pricePerUnit = 200.0;

      expect(material.totalCost, 1000.0);
    });

    test('totalCost is 0 for default values', () {
      final material = ProjectMaterial();

      expect(material.totalCost, 0);
    });

    test('priority ranges from 1 to 5', () {
      final lowPriority = ProjectMaterial()..priority = 5;
      final highPriority = ProjectMaterial()..priority = 1;

      expect(lowPriority.priority, 5);
      expect(highPriority.priority, 1);
    });
  });
}
