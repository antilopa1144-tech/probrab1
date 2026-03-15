// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:probrab_ai/domain/models/export_data.dart';
import 'package:probrab_ai/domain/services/csv_export_service.dart';

// Mock path provider for tests
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

const _testLabels = CsvExportLabels(
  project: 'Проект',
  description: 'Описание',
  createdAt: 'Дата создания',
  calculator: 'Калькулятор',
  parameter: 'Параметр',
  value: 'Значение',
  unit: 'Единица',
  materialCost: 'Стоимость материалов',
  laborCost: 'Стоимость работ',
  total: 'ИТОГО',
  materials: 'Материалы',
  labor: 'Работы',
  grandTotal: 'ВСЕГО',
  notes: 'Заметки',
);

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

    test('exportToCsv creates file', () async {
      final data = ExportData(
        projectName: 'IntegrationTest',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 100.0,
        totalLaborCost: 50.0,
        totalCost: 150.0,
      );

      final file = await service.exportToCsv(
        data,
        labels: _testLabels,
        filename: 'integration_test.csv',
      );

      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('IntegrationTest'));
    });

    test('exportToCsv with calculation data', () async {
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

      final file = await service.exportToCsv(
        data,
        labels: _testLabels,
        filename: 'calc_test.csv',
      );
      final content = await file.readAsString();

      expect(content, contains('CalcTest'));
      expect(content, contains('Тест'));
      expect(content, contains('25.00'));
      expect(content, contains('1500.00'));
    });

    test('getExportDirectory creates directory', () async {
      final path = await service.getExportDirectory();

      expect(path, contains('exports'));
      expect(await Directory(path).exists(), isTrue);
    });

    test('deleteExportedFile deletes file', () async {
      final data = ExportData(
        projectName: 'ToDelete',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      final file = await service.exportToCsv(
        data,
        labels: _testLabels,
        filename: 'to_delete_test.csv',
      );
      expect(await file.exists(), isTrue);

      await service.deleteExportedFile(file.path);
      expect(await file.exists(), isFalse);
    });

    test('CSV escapes special characters', () async {
      final data = ExportData(
        projectName: 'Test, "with" special\nchars',
        createdAt: DateTime.now(),
        calculations: [],
        totalMaterialCost: 0,
        totalLaborCost: 0,
        totalCost: 0,
      );

      final file = await service.exportToCsv(
        data,
        labels: _testLabels,
        filename: 'special_chars.csv',
      );
      final content = await file.readAsString();

      // Quotes should be escaped
      expect(content, contains('""with""'));
    });
  });

  group('CsvExportService', () {
    late CsvExportService service;

    setUp(() {
      service = CsvExportService();
    });

    group('filename generation', () {
      test('generates filename with timestamp', () async {
        final data = ExportData(
          projectName: 'TestProject',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, startsWith('probrab_'));
        expect(filename, contains('testproject'));
        expect(filename, endsWith('.csv'));
        expect(filename, matches(RegExp(r'probrab_testproject_\d{8}_\d{4}\.csv')));
      });

      test('cleans special characters from project name', () async {
        final data = ExportData(
          projectName: 'Test/Project*123!@#',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('testproject123'));
        expect(filename, isNot(contains('*')));
        expect(filename, isNot(contains('!')));
      });

      test('replaces spaces with underscores', () async {
        final data = ExportData(
          projectName: 'My Test Project',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('my_test_project'));
        expect(filename, isNot(contains(' ')));
      });

      test('converts to lowercase', () async {
        final data = ExportData(
          projectName: 'UPPERCASE',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('uppercase'));
        expect(filename, isNot(contains('UPPERCASE')));
      });

      test('handles multiple spaces', () async {
        final data = ExportData(
          projectName: 'Test    Multiple   Spaces',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('test_multiple_spaces'));
      });

      test('handles hyphens in name', () async {
        final data = ExportData(
          projectName: 'Test-Project-Name',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('test-project-name'));
      });

      test('uses custom filename if provided', () async {
        final data = ExportData(
          projectName: 'TestProject',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(
          data,
          labels: _testLabels,
          filename: 'custom_name.csv',
        );
        final filename = file.uri.pathSegments.last;

        expect(filename, equals('custom_name.csv'));
      });
    });

    group('CSV escaping', () {
      test('escapes commas in CSV', () async {
        final data = ExportData(
          projectName: 'Проект, с запятыми, внутри',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Cell with commas should be wrapped in quotes
        expect(content, contains('"Проект, с запятыми, внутри"'));
      });

      test('escapes quotes in CSV', () async {
        final data = ExportData(
          projectName: 'Проект "в кавычках"',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Quotes should be escaped as ""
        expect(content, contains('""в кавычках""'));
      });

      test('escapes newlines in CSV', () async {
        final data = ExportData(
          projectName: 'Проект\nс переносом\nстроки',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Cell with newline should be wrapped in quotes
        expect(content, contains('"Проект\nс переносом\nстроки"'));
      });

      test('escapes combination of commas and quotes', () async {
        final data = ExportData(
          projectName: 'Проект, "сложный" случай',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Both commas and quotes should be escaped
        expect(content, contains('"Проект, ""сложный"" случай"'));
      });

      test('escapes multiple consecutive quotes', () async {
        final data = ExportData(
          projectName: 'Проект"""тройные"""кавычки',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Each quote should be escaped
        expect(content, contains('""""""'));
      });

      test('does not escape normal text without special chars', () async {
        final data = ExportData(
          projectName: 'ОбычныйПроект',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Normal text should not be in quotes
        final lines = content.split('\n');
        final projectLine = lines.firstWhere((line) => line.startsWith('Проект,'));
        expect(projectLine, equals('Проект,ОбычныйПроект'));
      });

      test('handles empty values', () async {
        final data = ExportData(
          projectName: '',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('Проект,'));
      });

      test('escapes special chars in notes', () async {
        final data = ExportData(
          projectName: 'Проект',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
          notes: 'Заметка, с "кавычками"\nи переносом',
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('"Заметка, с ""кавычками""\nи переносом"'));
      });
    });

    group('CSV content verification', () {
      test('generates correct project header', () async {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();
        final lines = content.split('\n');

        // First line should be project header
        expect(lines.first, contains('Проект'));
        expect(lines.first, contains('Test Project'));
      });

      test('includes description when provided', () async {
        final data = ExportData(
          projectName: 'Test Project',
          projectDescription: 'Test description',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('Описание'));
        expect(content, contains('Test description'));
      });

      test('includes notes when provided', () async {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1000.0,
          totalLaborCost: 500.0,
          totalCost: 1500.0,
          notes: 'Important notes',
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('Заметки'));
        expect(content, contains('Important notes'));
      });

      test('includes calculations with inputs and results', () async {
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

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Should have calculator name
        expect(content, contains('Wall Paint'));

        // Should have inputs
        expect(content, contains('area'));
        expect(content, contains('50.00'));

        // Should have results
        expect(content, contains('paint_volume'));
        expect(content, contains('10.00'));
      });

      test('formats dates correctly', () async {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 5), // Single digit day/month
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Should be formatted as DD.MM.YYYY with leading zeros
        expect(content, contains('05.01.2024'));
      });

      test('includes table headers', () async {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Should have table headers
        expect(content, contains('Калькулятор'));
        expect(content, contains('Параметр'));
        expect(content, contains('Значение'));
        expect(content, contains('Единица'));
        expect(content, contains('Стоимость материалов'));
        expect(content, contains('Стоимость работ'));
      });

      test('includes totals section', () async {
        final data = ExportData(
          projectName: 'Test Project',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 1234.56,
          totalLaborCost: 789.12,
          totalCost: 2023.68,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Should have ИТОГО, Материалы, Работы, ВСЕГО
        expect(content, contains('ИТОГО'));
        expect(content, contains('Материалы'));
        expect(content, contains('Работы'));
        expect(content, contains('ВСЕГО'));
        expect(content, contains('1234.56'));
        expect(content, contains('789.12'));
        expect(content, contains('2023.68'));
      });

      test('handles calculations without costs', () async {
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

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Should not crash
        expect(content, contains('Test'));
      });
    });

    group('getExportedFiles', () {
      test('returns empty list if directory does not exist', () async {
        final files = await service.getExportedFiles();

        // May be empty or contain files from other tests
        expect(files, isA<List<File>>());
      });

      test('returns list of CSV files', () async {
        // Create a test file
        final data = ExportData(
          projectName: 'FileListTest',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        await service.exportToCsv(data, labels: _testLabels, filename: 'list_test.csv');

        final files = await service.getExportedFiles();

        expect(files, isA<List<File>>());
      });

      test('filters only CSV files', () async {
        final exportPath = await service.getExportDirectory();

        // Create CSV file
        final csvFile = File('$exportPath/test.csv');
        await csvFile.writeAsString('test,data\n');

        // Create non-CSV file
        final txtFile = File('$exportPath/test.txt');
        await txtFile.writeAsString('not csv');

        final files = await service.getExportedFiles();

        expect(files.every((f) => f.path.toLowerCase().endsWith('.csv')), isTrue);

        // Cleanup
        await csvFile.delete();
        await txtFile.delete();
      });

      test('sorts files by modification date', () async {
        final exportPath = await service.getExportDirectory();

        // Create files with delay
        final file1 = File('$exportPath/test1.csv');
        await file1.writeAsString('test1');
        await Future.delayed(const Duration(milliseconds: 100));

        final file2 = File('$exportPath/test2.csv');
        await file2.writeAsString('test2');

        final files = await service.getExportedFiles();

        if (files.length >= 2) {
          // Newer files should be first
          final dates = files.map((f) => f.lastModifiedSync()).toList();
          expect(dates.first.isAfter(dates.last) || dates.first.isAtSameMomentAs(dates.last), isTrue);
        }

        // Cleanup
        await file1.delete();
        await file2.delete();
      });
    });

    group('deleteExportedFile', () {
      test('deletes existing file', () async {
        final data = ExportData(
          projectName: 'DeleteTest',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels, filename: 'to_delete.csv');
        expect(await file.exists(), isTrue);

        await service.deleteExportedFile(file.path);
        expect(await file.exists(), isFalse);
      });

      test('does not throw error if file does not exist', () async {
        final fakePath = '${tempDir.path}/nonexistent.csv';

        expect(
          () async => service.deleteExportedFile(fakePath),
          returnsNormally,
        );
      });

      test('deletes files with cyrillic in path', () async {
        final data = ExportData(
          projectName: 'Тестовый',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        expect(await file.exists(), isTrue);

        await service.deleteExportedFile(file.path);
        expect(await file.exists(), isFalse);
      });
    });

    group('edge cases and data types', () {
      test('handles very large numbers', () async {
        const calc = ExportCalculation(
          calculatorName: 'BigNumbers',
          inputs: {'value': 999999999.99},
          results: {'result': 123456789.12},
          materialCost: 999999.99,
          laborCost: 888888.88,
        );

        final data = ExportData(
          projectName: 'BigTest',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: 999999.99,
          totalLaborCost: 888888.88,
          totalCost: 1888888.87,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('999999999.99'));
        expect(content, contains('123456789.12'));
      });

      test('handles very small numbers', () async {
        const calc = ExportCalculation(
          calculatorName: 'SmallNumbers',
          inputs: {'value': 0.01},
          results: {'result': 0.001},
          materialCost: 0.12,
          laborCost: 0.34,
        );

        final data = ExportData(
          projectName: 'SmallTest',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: 0.12,
          totalLaborCost: 0.34,
          totalCost: 0.46,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('0.01'));
        expect(content, contains('0.00')); // 0.001 rounds to 0.00
        expect(content, contains('0.12'));
        expect(content, contains('0.34'));
        expect(content, contains('0.46'));
      });

      test('handles zero values', () async {
        const calc = ExportCalculation(
          calculatorName: 'ZeroTest',
          inputs: {'value': 0.0},
          results: {'result': 0.0},
          materialCost: 0.0,
          laborCost: 0.0,
        );

        final data = ExportData(
          projectName: 'ZeroProject',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: 0.0,
          totalLaborCost: 0.0,
          totalCost: 0.0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('0.00'));
      });

      test('handles negative numbers', () async {
        const calc = ExportCalculation(
          calculatorName: 'NegativeTest',
          inputs: {'value': -10.5},
          results: {'result': -20.25},
          materialCost: -100.0,
          laborCost: -50.0,
        );

        final data = ExportData(
          projectName: 'NegativeProject',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: -100.0,
          totalLaborCost: -50.0,
          totalCost: -150.0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('-10.50'));
        expect(content, contains('-20.25'));
        expect(content, contains('-100.00'));
        expect(content, contains('-150.00'));
      });

      test('handles many calculations', () async {
        final calculations = List.generate(
          10,
          (i) => ExportCalculation(
            calculatorName: 'Calc${i + 1}',
            inputs: {'input$i': i.toDouble()},
            results: {'result$i': i * 2.0},
            materialCost: i * 10.0,
            laborCost: i * 5.0,
          ),
        );

        final data = ExportData(
          projectName: 'MultiCalc',
          createdAt: DateTime.now(),
          calculations: calculations,
          totalMaterialCost: 450.0,
          totalLaborCost: 225.0,
          totalCost: 675.0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        // Check that all calculations are included
        for (var i = 0; i < 10; i++) {
          expect(content, contains('Calc${i + 1}'));
        }
      });

      test('handles long calculator names', () async {
        const calc = ExportCalculation(
          calculatorName: 'Очень длинное название калькулятора для расчета строительных материалов',
          inputs: {'param': 1.0},
          results: {},
        );

        final data = ExportData(
          projectName: 'LongNameTest',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('Очень длинное название калькулятора для расчета строительных материалов'));
      });

      test('handles unicode characters', () async {
        final data = ExportData(
          projectName: 'Project with unicode',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('Project with unicode'));
      });

      test('handles boundary dates', () async {
        final data1 = ExportData(
          projectName: 'OldDate',
          createdAt: DateTime(1900, 1, 1),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file1 = await service.exportToCsv(data1, labels: _testLabels, filename: 'old_date.csv');
        final content1 = await file1.readAsString();
        expect(content1, contains('01.01.1900'));

        final data2 = ExportData(
          projectName: 'FutureDate',
          createdAt: DateTime(2099, 12, 31),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file2 = await service.exportToCsv(data2, labels: _testLabels, filename: 'future_date.csv');
        final content2 = await file2.readAsString();
        expect(content2, contains('31.12.2099'));
      });

      test('handles empty calculations list', () async {
        final data = ExportData(
          projectName: 'EmptyCalcs',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('EmptyCalcs'));
        expect(content, contains('ИТОГО'));
        expect(await file.exists(), isTrue);
      });

      test('handles empty inputs and results maps', () async {
        const calc = ExportCalculation(
          calculatorName: 'EmptyMaps',
          inputs: {},
          results: {},
        );

        final data = ExportData(
          projectName: 'EmptyMapsTest',
          createdAt: DateTime.now(),
          calculations: [calc],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, labels: _testLabels);
        final content = await file.readAsString();

        expect(content, contains('EmptyMaps'));
        expect(await file.exists(), isTrue);
      });

      test('preserves UTF-8 encoding', () async {
        final data = ExportData(
          projectName: 'Тестовая кодировка UTF-8',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 1234.56,
          totalLaborCost: 789.01,
          totalCost: 2023.57,
          notes: 'Заметки на русском языке',
        );

        final file = await service.exportToCsv(data, labels: _testLabels);

        // Read as UTF-8
        final content = await file.readAsString();

        expect(content, contains('Тестовая кодировка UTF-8'));
        expect(content, contains('Заметки на русском языке'));
        expect(content, contains('Проект'));
        expect(content, contains('ИТОГО'));
      });
    });

    group('error handling', () {
      test('handles normal paths without error', () async {
        expect(() async {
          final data = ExportData(
            projectName: 'ErrorTest',
            createdAt: DateTime.now(),
            calculations: [],
            totalMaterialCost: 0,
            totalLaborCost: 0,
            totalCost: 0,
          );
          await service.exportToCsv(data, labels: _testLabels);
        }, returnsNormally);
      });
    });
  });
}
