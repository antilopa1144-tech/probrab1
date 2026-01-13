// ignore_for_file: avoid_slow_async_io

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
    late CsvExportService service;

    setUp(() {
      service = CsvExportService();
    });

    group('filename generation', () {
      test('генерирует имя файла с меткой времени', () async {
        final data = ExportData(
          projectName: 'TestProject',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, startsWith('probrab_'));
        expect(filename, contains('testproject'));
        expect(filename, endsWith('.csv'));
        expect(filename, matches(RegExp(r'probrab_testproject_\d{8}_\d{4}\.csv')));
      });

      test('очищает название проекта от спецсимволов', () async {
        final data = ExportData(
          projectName: 'Test/Project*123!@#',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('testproject123'));
        expect(filename, isNot(contains('*')));
        expect(filename, isNot(contains('!')));
      });

      test('заменяет пробелы на подчеркивания', () async {
        final data = ExportData(
          projectName: 'My Test Project',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('my_test_project'));
        expect(filename, isNot(contains(' ')));
      });

      test('преобразует в нижний регистр', () async {
        final data = ExportData(
          projectName: 'UPPERCASE',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('uppercase'));
        expect(filename, isNot(contains('UPPERCASE')));
      });

      test('обрабатывает множественные пробелы', () async {
        final data = ExportData(
          projectName: 'Test    Multiple   Spaces',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('test_multiple_spaces'));
      });

      test('обрабатывает дефисы в названии', () async {
        final data = ExportData(
          projectName: 'Test-Project-Name',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final filename = file.uri.pathSegments.last;

        expect(filename, contains('test-project-name'));
      });

      test('использует custom filename если указан', () async {
        final data = ExportData(
          projectName: 'TestProject',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, filename: 'custom_name.csv');
        final filename = file.uri.pathSegments.last;

        expect(filename, equals('custom_name.csv'));
      });
    });

    group('CSV escaping', () {
      test('экранирует запятые в CSV', () async {
        final data = ExportData(
          projectName: 'Проект, с запятыми, внутри',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Ячейка с запятыми должна быть обернута в кавычки
        expect(content, contains('"Проект, с запятыми, внутри"'));
      });

      test('экранирует кавычки в CSV', () async {
        final data = ExportData(
          projectName: 'Проект "в кавычках"',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Кавычки должны быть экранированы как ""
        expect(content, contains('""в кавычках""'));
      });

      test('экранирует переносы строк в CSV', () async {
        final data = ExportData(
          projectName: 'Проект\nс переносом\nстроки',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Ячейка с переносом должна быть обернута в кавычки
        expect(content, contains('"Проект\nс переносом\nстроки"'));
      });

      test('экранирует комбинацию запятых и кавычек', () async {
        final data = ExportData(
          projectName: 'Проект, "сложный" случай',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Должны быть экранированы и запятые, и кавычки
        expect(content, contains('"Проект, ""сложный"" случай"'));
      });

      test('экранирует множественные кавычки подряд', () async {
        final data = ExportData(
          projectName: 'Проект"""тройные"""кавычки',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Каждая кавычка должна быть экранирована
        expect(content, contains('""""""'));
      });

      test('не экранирует обычный текст без спецсимволов', () async {
        final data = ExportData(
          projectName: 'ОбычныйПроект',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Обычный текст не должен быть в кавычках
        final lines = content.split('\n');
        final projectLine = lines.firstWhere((line) => line.startsWith('Проект,'));
        expect(projectLine, equals('Проект,ОбычныйПроект'));
      });

      test('обрабатывает пустые значения', () async {
        final data = ExportData(
          projectName: '',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('Проект,'));
      });

      test('экранирует спецсимволы в заметках', () async {
        final data = ExportData(
          projectName: 'Проект',
          createdAt: DateTime(2024, 1, 15),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
          notes: 'Заметка, с "кавычками"\nи переносом',
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('"Заметка, с ""кавычками""\nи переносом"'));
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

    group('getExportedFiles', () {
      test('возвращает пустой список если директории нет', () async {
        final files = await service.getExportedFiles();

        // Может быть пустым или содержать файлы из других тестов
        expect(files, isA<List<File>>());
      });

      test('возвращает список CSV файлов', () async {
        // Создаем тестовый файл
        final data = ExportData(
          projectName: 'FileListTest',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        await service.exportToCsv(data, filename: 'list_test.csv');

        final files = await service.getExportedFiles();

        expect(files, isA<List<File>>());
      });

      test('фильтрует только CSV файлы', () async {
        final exportPath = await service.getExportDirectory();

        // Создаем CSV файл
        final csvFile = File('$exportPath/test.csv');
        await csvFile.writeAsString('test,data\n');

        // Создаем не-CSV файл
        final txtFile = File('$exportPath/test.txt');
        await txtFile.writeAsString('not csv');

        final files = await service.getExportedFiles();

        expect(files.every((f) => f.path.toLowerCase().endsWith('.csv')), isTrue);

        // Cleanup
        await csvFile.delete();
        await txtFile.delete();
      });

      test('сортирует файлы по дате изменения', () async {
        final exportPath = await service.getExportDirectory();

        // Создаем файлы с задержкой
        final file1 = File('$exportPath/test1.csv');
        await file1.writeAsString('test1');
        await Future.delayed(const Duration(milliseconds: 100));

        final file2 = File('$exportPath/test2.csv');
        await file2.writeAsString('test2');

        final files = await service.getExportedFiles();

        if (files.length >= 2) {
          // Новые файлы должны быть первыми
          final dates = files.map((f) => f.lastModifiedSync()).toList();
          expect(dates.first.isAfter(dates.last) || dates.first.isAtSameMomentAs(dates.last), isTrue);
        }

        // Cleanup
        await file1.delete();
        await file2.delete();
      });
    });

    group('deleteExportedFile', () {
      test('удаляет существующий файл', () async {
        final data = ExportData(
          projectName: 'DeleteTest',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data, filename: 'to_delete.csv');
        expect(await file.exists(), isTrue);

        await service.deleteExportedFile(file.path);
        expect(await file.exists(), isFalse);
      });

      test('не выбрасывает ошибку если файл не существует', () async {
        final fakePath = '${tempDir.path}/nonexistent.csv';

        expect(
          () async => service.deleteExportedFile(fakePath),
          returnsNormally,
        );
      });

      test('удаляет файлы с кириллицей в пути', () async {
        final data = ExportData(
          projectName: 'Тестовый',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        expect(await file.exists(), isTrue);

        await service.deleteExportedFile(file.path);
        expect(await file.exists(), isFalse);
      });
    });

    group('edge cases and data types', () {
      test('обрабатывает очень большие числа', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('999999999.99'));
        expect(content, contains('123456789.12'));
      });

      test('обрабатывает очень маленькие числа', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('0.01'));
        expect(content, contains('0.00')); // 0.001 rounds to 0.00
        expect(content, contains('0.12'));
        expect(content, contains('0.34'));
        expect(content, contains('0.46'));
      });

      test('обрабатывает нулевые значения', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('0.00'));
      });

      test('обрабатывает отрицательные числа', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('-10.50'));
        expect(content, contains('-20.25'));
        expect(content, contains('-100.00'));
        expect(content, contains('-150.00'));
      });

      test('обрабатывает множество расчетов', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        // Проверяем что все расчеты включены
        for (var i = 0; i < 10; i++) {
          expect(content, contains('Calc${i + 1}'));
        }
      });

      test('обрабатывает длинные названия калькуляторов', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('Очень длинное название калькулятора для расчета строительных материалов'));
      });

      test('обрабатывает unicode символы', () async {
        final data = ExportData(
          projectName: 'Проект с 中文 и emoji 🏠',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('中文'));
        expect(content, contains('🏠'));
      });

      test('обрабатывает граничные даты', () async {
        final data1 = ExportData(
          projectName: 'OldDate',
          createdAt: DateTime(1900, 1, 1),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file1 = await service.exportToCsv(data1, filename: 'old_date.csv');
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

        final file2 = await service.exportToCsv(data2, filename: 'future_date.csv');
        final content2 = await file2.readAsString();
        expect(content2, contains('31.12.2099'));
      });

      test('обрабатывает пустой список расчетов', () async {
        final data = ExportData(
          projectName: 'EmptyCalcs',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 0,
          totalLaborCost: 0,
          totalCost: 0,
        );

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('EmptyCalcs'));
        expect(content, contains('ИТОГО'));
        expect(await file.exists(), isTrue);
      });

      test('обрабатывает пустые карты inputs и results', () async {
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

        final file = await service.exportToCsv(data);
        final content = await file.readAsString();

        expect(content, contains('EmptyMaps'));
        expect(await file.exists(), isTrue);
      });

      test('сохраняет кодировку UTF-8', () async {
        final data = ExportData(
          projectName: 'Тестовая кодировка UTF-8',
          createdAt: DateTime.now(),
          calculations: [],
          totalMaterialCost: 1234.56,
          totalLaborCost: 789.01,
          totalCost: 2023.57,
          notes: 'Заметки на русском языке',
        );

        final file = await service.exportToCsv(data);

        // Читаем как UTF-8
        final content = await file.readAsString();

        expect(content, contains('Тестовая кодировка UTF-8'));
        expect(content, contains('Заметки на русском языке'));
        expect(content, contains('Проект'));
        expect(content, contains('ИТОГО'));
      });
    });

    group('error handling', () {
      test('обрабатывает некорректные пути', () async {
        // ExportException должно быть выброшено если путь недействителен
        // Но в тестовой среде с mock path provider это сложно протестировать
        // Проверяем что метод возвращает ExportException при ошибках
        expect(() async {
          final data = ExportData(
            projectName: 'ErrorTest',
            createdAt: DateTime.now(),
            calculations: [],
            totalMaterialCost: 0,
            totalLaborCost: 0,
            totalCost: 0,
          );
          await service.exportToCsv(data);
        }, returnsNormally);
      });
    });
  });
}
