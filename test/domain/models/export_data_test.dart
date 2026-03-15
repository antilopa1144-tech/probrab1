import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/export_data.dart';

void main() {
  group('ExportData', () {
    test('creates instance with required fields', () {
      final data = ExportData(
        projectName: 'Test Project',
        createdAt: DateTime(2024, 1, 15),
        calculations: [],
        totalMaterialCost: 1000.0,
        totalLaborCost: 500.0,
        totalCost: 1500.0,
      );

      expect(data.projectName, equals('Test Project'));
      expect(data.createdAt, equals(DateTime(2024, 1, 15)));
      expect(data.calculations, isEmpty);
      expect(data.totalMaterialCost, equals(1000.0));
      expect(data.totalLaborCost, equals(500.0));
      expect(data.totalCost, equals(1500.0));
      expect(data.projectDescription, isNull);
      expect(data.notes, isNull);
    });

    test('creates instance with optional fields', () {
      final data = ExportData(
        projectName: 'Test Project',
        projectDescription: 'Test description',
        createdAt: DateTime(2024, 1, 15),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
        notes: 'Test notes',
      );

      expect(data.projectDescription, equals('Test description'));
      expect(data.notes, equals('Test notes'));
    });

    test('handles multiple calculations', () {
      const calc1 = ExportCalculation(
        calculatorName: 'Calc1',
        inputs: {'a': 1.0},
        results: {},
      );

      const calc2 = ExportCalculation(
        calculatorName: 'Calc2',
        inputs: {'b': 2.0},
        results: {},
      );

      final data = ExportData(
        projectName: 'Project',
        createdAt: DateTime(2024, 1, 15),
        calculations: [calc1, calc2],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      expect(data.calculations.length, 2);
      expect(data.calculations[0].calculatorName, 'Calc1');
      expect(data.calculations[1].calculatorName, 'Calc2');
    });

    test('handles empty calculations list', () {
      final data = ExportData(
        projectName: 'Project',
        createdAt: DateTime(2024, 1, 15),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      expect(data.calculations, isEmpty);
      expect(data.projectName, 'Project');
    });
  });

  group('ExportCalculation', () {
    test('creates instance with required fields', () {
      const calc = ExportCalculation(
        calculatorName: 'Test Calculator',
        inputs: {'a': 1.0, 'b': 2.0},
        results: {'c': 3.0},
      );

      expect(calc.calculatorName, equals('Test Calculator'));
      expect(calc.inputs, equals({'a': 1.0, 'b': 2.0}));
      expect(calc.results, equals({'c': 3.0}));
      expect(calc.materialCost, isNull);
      expect(calc.laborCost, isNull);
      expect(calc.notes, isNull);
    });

    test('creates instance with optional fields', () {
      const calc = ExportCalculation(
        calculatorName: 'Test',
        inputs: {},
        results: {},
        materialCost: 100.0,
        laborCost: 50.0,
        notes: 'Test notes',
      );

      expect(calc.materialCost, equals(100.0));
      expect(calc.laborCost, equals(50.0));
      expect(calc.notes, equals('Test notes'));
    });

    test('handles empty inputs and results', () {
      const calc = ExportCalculation(
        calculatorName: 'Empty',
        inputs: {},
        results: {},
      );

      expect(calc.inputs, isEmpty);
      expect(calc.results, isEmpty);
    });
  });
}
