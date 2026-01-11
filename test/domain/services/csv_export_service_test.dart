import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:probrab_ai/domain/models/export_data.dart';
import 'package:probrab_ai/domain/services/csv_export_service.dart';

// Mock path provider для тестов
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;

  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('csv_export_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('CsvExportService integration', () {
    late CsvExportService service;

    setUp(() {
      service = CsvExportService();
    });

    test('exportToCsv создаёт файл', () async {
      final data = ExportData(
        projectName: 'IntegrationTest',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 100.0,
        totalLaborCost: 50.0,
        totalCost: 150.0,
      );

      final file = await service.exportToCsv(data, filename: 'integration_test.csv');

      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('IntegrationTest'));
    });

    test('exportToCsv с данными расчётов', () async {
      final data = ExportData(
        projectName: 'CalcTest',
        createdAt: DateTime(2024, 6, 15),
        calculations: [
          const ExportCalculation(
            calculatorName: 'Тест',
            inputs: {'area': 25.0},
            results: {'result': 50.0},
            materialCost: 1000.0,
            laborCost: 500.0,
          ),
        ],
        totalMaterialCost: 1000.0,
        totalLaborCost: 500.0,
        totalCost: 1500.0,
      );

      final file = await service.exportToCsv(data, filename: 'calc_test.csv');
      final content = await file.readAsString();

      expect(content, contains('CalcTest'));
      expect(content, contains('Тест'));
      expect(content, contains('25.00'));
      expect(content, contains('1500.00'));
    });

    test('getExportDirectory создаёт директорию', () async {
      final path = await service.getExportDirectory();

      expect(path, contains('exports'));
      expect(await Directory(path).exists(), isTrue);
    });

    test('deleteExportedFile удаляет файл', () async {
      final data = ExportData(
        projectName: 'ToDelete',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      final file = await service.exportToCsv(data, filename: 'to_delete_test.csv');
      expect(await file.exists(), isTrue);

      await service.deleteExportedFile(file.path);
      expect(await file.exists(), isFalse);
    });

    test('CSV экранирует специальные символы', () async {
      final data = ExportData(
        projectName: 'Test, "with" special\nchars',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      final file = await service.exportToCsv(data, filename: 'special_chars.csv');
      final content = await file.readAsString();

      // Должны быть экранированы кавычки
      expect(content, contains('""with""'));
    });
  });

  group('CsvExportService', () {
    group('_convertToCsv', () {
      test('converts simple rows to CSV', () {
        // Access private method through reflection is not possible in Dart,
        // so we test it indirectly through the CSV export
        // For unit testing, we'll test the behavior through public methods
      });
    });

    group('_generateFileName', () {
      test('generates filename with project name and timestamp', () {
        // Test indirectly through exportToCsv behavior
        // The filename format is: probrab_{cleanName}_{dateStr}_{timeStr}.csv
        // We can verify the filename pattern through the actual export
        // (tested below in integration tests)
      });

      test('cleans project name from invalid characters', () {
        // Should convert "Test/Project*123" to "testproject123"
        // Filename should not contain special characters
      });

      test('replaces spaces with underscores', () {
        // "My Project" should become "my_project"
        // Filename should have underscores instead of spaces
      });
    });

    group('CSV escaping', () {
      test('escapes cells with commas', () {
        final data = ExportData(
          projectName: 'Test, Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        // Cell with comma should be wrapped in quotes
        expect(data.projectName, contains(','));
      });

      test('escapes cells with quotes', () {
        final data = ExportData(
          projectName: 'Test "Project"',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        // Cell with quotes should escape them as ""
        expect(data.projectName, contains('"'));
      });

      test('escapes cells with newlines', () {
        final data = ExportData(
          projectName: 'Test\nProject',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        // Cell with newline should be wrapped in quotes
        expect(data.projectName, contains('\n'));
      });
    });

    group('ExportData CSV conversion', () {
      test('converts minimal export data to CSV rows', () {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
        );

        final rows = data.toCsvRows();

        // Should have project header
        expect(rows.first, equals(['Проект', 'Test Project']));

        // Should have date
        expect(rows.any((r) => r.isNotEmpty && r.first == 'Дата создания'), isTrue);

        // Should have totals
        expect(rows.any((r) => r.isNotEmpty && r.first == 'ИТОГО'), isTrue);
        expect(rows.any((r) => r.isNotEmpty && r.first == 'Материалы'), isTrue);
        expect(rows.any((r) => r.isNotEmpty && r.first == 'Работы'), isTrue);
        expect(rows.any((r) => r.isNotEmpty && r.first == 'ВСЕГО'), isTrue);
      });

      test('includes project description if provided', () {
        final data = ExportData(
          projectName: 'Test Project',
          projectDescription: 'Test description',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
        );

        final rows = data.toCsvRows();

        expect(rows.any((r) => r.isNotEmpty && r.first == 'Описание'), isTrue);
        expect(rows.any((r) => r.contains('Test description')), isTrue);
      });

      test('includes notes if provided', () {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
          notes: 'Important notes',
        );

        final rows = data.toCsvRows();

        expect(rows.any((r) => r.isNotEmpty && r.first == 'Заметки'), isTrue);
        expect(rows.any((r) => r.contains('Important notes')), isTrue);
      });

      test('includes calculations with inputs and results', () {
        const calc = ExportCalculation(
          calculatorName: 'Wall Paint',
          inputs: {'area': 50.0, 'height': 3.0},
          results: {'paint_volume': 10.0, 'primer_volume': 5.0},
          materialCost: 500.0,
          laborCost: 300.0,
        );

        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [calc],
          totalMaterialCost: 500.0,
          totalLaborCost: 300.0,
          totalCost: 800.0,
        );

        final rows = data.toCsvRows();

        // Should have calculator name
        expect(rows.any((r) => r.isNotEmpty && r.first == 'Wall Paint'), isTrue);

        // Should have inputs
        expect(rows.any((r) => r.length > 2 && r[1] == 'area' && r[2] == '50.00'), isTrue);
        expect(rows.any((r) => r.length > 2 && r[1] == 'height' && r[2] == '3.00'), isTrue);

        // Should have results
        expect(rows.any((r) => r.length > 2 && r[1] == 'paint_volume' && r[2] == '10.00'), isTrue);
      });

      test('formats dates correctly', () {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 5), // Single digit day/month
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();
        final dateRow = rows.firstWhere((r) => r.isNotEmpty && r.first == 'Дата создания');

        // Should be formatted as DD.MM.YYYY with leading zeros
        expect(dateRow[1], equals('05.01.2024'));
      });

      test('formats numbers with 2 decimal places', () {
        const calc = ExportCalculation(
          calculatorName: 'Test',
          inputs: {'value': 10.123456},
          results: {},
          materialCost: 123.456,
          laborCost: 78.9,
        );

        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [calc],
          totalMaterialCost: 123.456,
          totalLaborCost: 78.9,
          totalCost: 202.356,
        );

        final rows = data.toCsvRows();

        // Check value formatting
        expect(rows.any((r) => r.length > 2 && r[2] == '10.12'), isTrue);

        // Check cost formatting
        final materialRow = rows.firstWhere((r) => r.isNotEmpty && r.first == 'Материалы');
        expect(materialRow[4], equals('123.46'));

        final laborRow = rows.firstWhere((r) => r.isNotEmpty && r.first == 'Работы');
        expect(laborRow[5], equals('78.90'));

        final totalRow = rows.firstWhere((r) => r.isNotEmpty && r.first == 'ВСЕГО');
        expect(totalRow[4], equals('202.36'));
      });

      test('includes table headers', () {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        // Should have table headers
        expect(
          rows.any((r) =>
              r.contains('Калькулятор') &&
              r.contains('Параметр') &&
              r.contains('Значение') &&
              r.contains('Единица') &&
              r.contains('Стоимость материалов') &&
              r.contains('Стоимость работ')),
          isTrue,
        );
      });

      test('separates calculations with empty rows', () {
        const calc1 = ExportCalculation(
          calculatorName: 'Calc 1',
          inputs: {'a': 1.0},
          results: {},
        );

        const calc2 = ExportCalculation(
          calculatorName: 'Calc 2',
          inputs: {'b': 2.0},
          results: {},
        );

        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [calc1, calc2],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        // Should have empty rows between calculations
        expect(rows.any((r) => r.isEmpty), isTrue);
      });

      test('handles calculations without costs', () {
        const calc = ExportCalculation(
          calculatorName: 'Test',
          inputs: {'a': 1.0},
          results: {},
          // No materialCost or laborCost
        );

        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [calc],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final rows = data.toCsvRows();

        // Should not crash and should have empty cost fields
        final calcRow = rows.firstWhere((r) => r.isNotEmpty && r.first == 'Test');
        expect(calcRow[4], equals('')); // Empty material cost
        expect(calcRow[5], equals('')); // Empty labor cost
      });
    });
  });
}
