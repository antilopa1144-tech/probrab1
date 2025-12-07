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

    group('toCsvRows', () {
      test('generates correct project header', () {
        final data = ExportData(
          projectName: 'My Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        expect(rows[0], equals(['Проект', 'My Project']));
      });

      test('includes description when provided', () {
        final data = ExportData(
          projectName: 'Project',
          projectDescription: 'Description here',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Описание' && r[1] == 'Description here'), isTrue);
      });

      test('formats date correctly', () {
        final data = ExportData(
          projectName: 'Project',
          createdAt: DateTime(2024, 1, 5),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();
        final dateRow = rows.firstWhere((r) => r.isNotEmpty && r[0] == 'Дата создания');

        expect(dateRow[1], equals('05.01.2024'));
      });

      test('includes table headers', () {
        final data = ExportData(
          projectName: 'Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        expect(
          rows.any((r) =>
              r.length == 6 &&
              r[0] == 'Калькулятор' &&
              r[1] == 'Параметр' &&
              r[2] == 'Значение' &&
              r[3] == 'Единица' &&
              r[4] == 'Стоимость материалов' &&
              r[5] == 'Стоимость работ'),
          isTrue,
        );
      });

      test('includes calculation data', () {
        const calc = ExportCalculation(
          calculatorName: 'Wall Paint',
          inputs: {'area': 50.5},
          results: {'paint': 10.25},
          materialCost: 500.0,
          laborCost: 300.0,
        );

        final data = ExportData(
          projectName: 'Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [calc],
          totalMaterialCost: 500.0,
          totalLaborCost: 300.0,
          totalCost: 800.0,
        );

        final rows = data.toCsvRows();

        // Calculator name row
        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Wall Paint'), isTrue);

        // Input row
        expect(rows.any((r) => r.length > 2 && r[1] == 'area' && r[2] == '50.50'), isTrue);

        // Result row
        expect(rows.any((r) => r.length > 2 && r[1] == 'paint' && r[2] == '10.25'), isTrue);
      });

      test('includes totals section', () {
        final data = ExportData(
          projectName: 'Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1234.56,
          totalLaborCost: 789.12,
          totalCost: 2023.68,
        );

        final rows = data.toCsvRows();

        // ИТОГО row
        expect(rows.any((r) => r.isNotEmpty && r[0] == 'ИТОГО'), isTrue);

        // Материалы row
        final materialRow = rows.firstWhere((r) => r.isNotEmpty && r[0] == 'Материалы');
        expect(materialRow[4], equals('1234.56'));

        // Работы row
        final laborRow = rows.firstWhere((r) => r.isNotEmpty && r[0] == 'Работы');
        expect(laborRow[5], equals('789.12'));

        // ВСЕГО row
        final totalRow = rows.firstWhere((r) => r.isNotEmpty && r[0] == 'ВСЕГО');
        expect(totalRow[4], equals('2023.68'));
      });

      test('includes notes when provided', () {
        final data = ExportData(
          projectName: 'Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
          notes: 'Important project notes',
        );

        final rows = data.toCsvRows();

        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Заметки' && r[1] == 'Important project notes'), isTrue);
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

        final rows = data.toCsvRows();

        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Calc1'), isTrue);
        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Calc2'), isTrue);
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

        final rows = data.toCsvRows();

        // Should still have headers and totals
        expect(rows, isNotEmpty);
        expect(rows.any((r) => r.isNotEmpty && r[0] == 'Проект'), isTrue);
        expect(rows.any((r) => r.isNotEmpty && r[0] == 'ВСЕГО'), isTrue);
      });
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
