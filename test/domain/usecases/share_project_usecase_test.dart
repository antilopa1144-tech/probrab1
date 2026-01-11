import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/share_project_usecase.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/domain/models/shareable_content.dart';
import 'package:probrab_ai/domain/models/export_data.dart';
import 'package:probrab_ai/domain/services/csv_export_service.dart';
import 'package:probrab_ai/core/services/deep_link_service.dart';
import 'package:probrab_ai/core/exceptions/export_exception.dart';

// Mock classes
class MockCsvExportService implements CsvExportService {
  ExportData? lastExportData;
  String? lastFilename;
  File? mockFile;
  Exception? throwOnExport;
  Exception? throwOnShare;

  @override
  Future<File> exportToCsv(ExportData data, {String? filename}) async {
    lastExportData = data;
    lastFilename = filename;
    if (throwOnExport != null) throw throwOnExport!;
    return mockFile ?? File('/test/file.csv');
  }

  @override
  Future<void> exportAndShare(ExportData data, {String? filename}) async {
    lastExportData = data;
    lastFilename = filename;
    if (throwOnShare != null) throw throwOnShare!;
  }

  @override
  Future<void> deleteExportedFile(String filePath) async {}

  @override
  Future<String> getExportDirectory() async => '/test';

  @override
  Future<List<File>> getExportedFiles() async => [];
}

class MockDeepLinkService implements DeepLinkService {
  String? lastCreatedLink;
  bool? lastCompactValue;
  ShareableContent? lastShareableContent;

  String mockLink = 'masterokapp://s/hash?d=data';

  @override
  String createProjectLink(ShareableProject project, {bool compact = false}) {
    lastShareableContent = project;
    lastCompactValue = compact;
    lastCreatedLink = mockLink;
    return mockLink;
  }

  @override
  String createCalculatorLink(ShareableCalculator calculator,
      {bool compact = false}) {
    lastShareableContent = calculator;
    lastCompactValue = compact;
    return mockLink;
  }

  @override
  Future<DeepLinkData?> handleDeepLink(Uri uri) async => null;

  @override
  Stream<DeepLinkData> get linkStream => const Stream.empty();

  @override
  Future<DeepLinkData?> parseLink(String link) async => null;

  @override
  Future<DeepLinkData?> parseQRCode(String qrData) async => null;

  @override
  void dispose() {}
}

void main() {
  late ShareProjectUseCase useCase;
  late MockCsvExportService mockCsvExportService;
  late MockDeepLinkService mockDeepLinkService;

  setUp(() {
    mockCsvExportService = MockCsvExportService();
    mockDeepLinkService = MockDeepLinkService();
    useCase = ShareProjectUseCase(
      csvExportService: mockCsvExportService,
      deepLinkService: mockDeepLinkService,
    );
  });

  group('ShareProjectUseCase -', () {
    group('getProjectLink', () {
      test('возвращает compact deep link по умолчанию', () {
        final project = _createTestProject();
        mockDeepLinkService.mockLink = 'masterokapp://s/12345678?d=encoded_data';

        final result = useCase.getProjectLink(project);

        expect(result, 'masterokapp://s/12345678?d=encoded_data');
        expect(mockDeepLinkService.lastCompactValue, true);
        expect(mockDeepLinkService.lastShareableContent, isA<ShareableProject>());
      });

      test('возвращает полный deep link когда compact=false', () {
        final project = _createTestProject();
        mockDeepLinkService.mockLink = 'masterokapp://share/project?data=encoded_data';

        final result = useCase.getProjectLink(project, compact: false);

        expect(result, 'masterokapp://share/project?data=encoded_data');
        expect(mockDeepLinkService.lastCompactValue, false);
      });

      test('корректно конвертирует проект в ShareableProject', () {
        final project = _createTestProject(
          name: 'Тестовый проект',
          description: 'Описание проекта',
        );

        useCase.getProjectLink(project);

        final shareableProject = mockDeepLinkService.lastShareableContent as ShareableProject;
        expect(shareableProject.name, 'Тестовый проект');
        expect(shareableProject.description, 'Описание проекта');
      });

      test('работает с проектом без description', () {
        final project = ProjectV2()
          ..name = 'Simple Project'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        final result = useCase.getProjectLink(project);

        expect(result, isNotEmpty);
        final shareableProject = mockDeepLinkService.lastShareableContent as ShareableProject;
        expect(shareableProject.name, 'Simple Project');
        expect(shareableProject.description, isNull);
      });
    });

    group('shareAsLink', () {
      test('успешно шарит проект как link', () async {
        final project = _createTestProject();
        mockDeepLinkService.mockLink = 'masterokapp://s/hash?d=data';

        final result = await useCase.shareAsLink(project);

        expect(result.success, true);
        expect(result.format, 'link');
        expect(result.error, isNull);
        expect(mockDeepLinkService.lastCompactValue, true);
      });

      test('использует compact формат по умолчанию', () async {
        final project = _createTestProject();

        await useCase.shareAsLink(project);

        expect(mockDeepLinkService.lastCompactValue, true);
      });

      test('использует полный формат когда compact=false', () async {
        final project = _createTestProject();

        await useCase.shareAsLink(project, compact: false);

        expect(mockDeepLinkService.lastCompactValue, false);
      });

      test('корректно форматирует сообщение для шаринга с кириллицей', () async {
        final project = _createTestProject(
          name: 'Проект на русском',
        );

        final result = await useCase.shareAsLink(project);

        expect(result.success, true);
        final shareableProject = mockDeepLinkService.lastShareableContent as ShareableProject;
        expect(shareableProject.name, 'Проект на русском');
      });
    });

    group('shareAsCsv', () {
      test('успешно экспортирует и шарит CSV', () async {
        final project = _createTestProject();

        final result = await useCase.shareAsCsv(project);

        expect(result.success, true);
        expect(result.format, 'csv');
        expect(result.error, isNull);
        expect(mockCsvExportService.lastExportData, isNotNull);
      });

      test('передает кастомное имя файла', () async {
        final project = _createTestProject();
        const customFilename = 'custom_export.csv';

        await useCase.shareAsCsv(project, filename: customFilename);

        expect(mockCsvExportService.lastFilename, customFilename);
      });

      test('корректно конвертирует проект в ExportData', () async {
        final project = _createTestProject(
          name: 'Test Project',
          description: 'Test Description',
        );

        await useCase.shareAsCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.projectName, 'Test Project');
        expect(exportData.projectDescription, 'Test Description');
        expect(exportData.createdAt, project.createdAt);
      });

      test('пробрасывает ExportException без изменений', () async {
        final project = _createTestProject();
        final exception = ExportException.permissionDenied('/path');
        mockCsvExportService.throwOnShare = exception;

        expect(
          () => useCase.shareAsCsv(project),
          throwsA(isA<ExportException>()),
        );
      });

      test('оборачивает другие исключения в ExportException', () async {
        final project = _createTestProject();
        mockCsvExportService.throwOnShare = Exception('Unknown error');

        expect(
          () => useCase.shareAsCsv(project),
          throwsA(isA<ExportException>()),
        );
      });
    });

    group('shareAsPdf', () {
      test('успешно создает и шарит PDF', () async {
        final project = _createTestProject();

        final result = await useCase.shareAsPdf(project);

        expect(result.success, true);
        expect(result.format, 'pdf');
        expect(result.error, isNull);
      });

      test('работает с проектом со спецсимволами в имени', () async {
        final project = _createTestProject(
          name: 'Test/Project:With*Special?Chars',
        );

        final result = await useCase.shareAsPdf(project);

        expect(result.success, true);
      });

      test('работает с очень длинным именем проекта', () async {
        final project = _createTestProject(
          name: 'A' * 200,
        );

        final result = await useCase.shareAsPdf(project);

        expect(result.success, true);
      });
    });

    group('exportToCsv', () {
      test('успешно экспортирует проект в CSV файл', () async {
        final project = _createTestProject();
        final expectedFile = File('/path/to/export.csv');
        mockCsvExportService.mockFile = expectedFile;

        final result = await useCase.exportToCsv(project);

        expect(result, same(expectedFile));
        expect(mockCsvExportService.lastExportData, isNotNull);
      });

      test('передает кастомное имя файла в сервис', () async {
        final project = _createTestProject();
        const customFilename = 'my_export.csv';

        await useCase.exportToCsv(project, filename: customFilename);

        expect(mockCsvExportService.lastFilename, customFilename);
      });

      test('конвертирует проект с расчетами в ExportData', () async {
        final project = _createComplexProject();

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.calculations.length, 2);
        expect(exportData.calculations[0].calculatorName, 'Brick Calc');
        expect(exportData.calculations[0].materialCost, 5000.0);
        expect(exportData.calculations[0].laborCost, 2500.0);
        expect(exportData.calculations[1].calculatorName, 'Tile Calc');
      });

      test('правильно суммирует стоимости', () async {
        final project = _createComplexProject();

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.totalMaterialCost, 8000.0);
        expect(exportData.totalLaborCost, 4000.0);
        expect(exportData.totalCost, 12000.0);
      });

      test('пробрасывает ExportException без изменений', () async {
        final project = _createTestProject();
        final exception = ExportException.permissionDenied('/path');
        mockCsvExportService.throwOnExport = exception;

        expect(
          () => useCase.exportToCsv(project),
          throwsA(isA<ExportException>()),
        );
      });

      test('оборачивает другие исключения в ExportException', () async {
        final project = _createTestProject();
        mockCsvExportService.throwOnExport = Exception('File system error');

        expect(
          () => useCase.exportToCsv(project),
          throwsA(isA<ExportException>()),
        );
      });

      test('работает с пустым проектом без расчетов', () async {
        final project = ProjectV2()
          ..name = 'Empty Project'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.calculations, isEmpty);
        expect(exportData.totalMaterialCost, 0.0);
        expect(exportData.totalLaborCost, 0.0);
      });
    });

    group('ShareResult', () {
      test('создает успешный результат', () {
        final result = ShareResult.success('csv');

        expect(result.success, true);
        expect(result.format, 'csv');
        expect(result.error, isNull);
      });

      test('создает результат с ошибкой', () {
        final result = ShareResult.failure('pdf', 'Test error');

        expect(result.success, false);
        expect(result.format, 'pdf');
        expect(result.error, 'Test error');
      });

      test('поддерживает различные форматы', () {
        final linkResult = ShareResult.success('link');
        final csvResult = ShareResult.success('csv');
        final pdfResult = ShareResult.success('pdf');

        expect(linkResult.format, 'link');
        expect(csvResult.format, 'csv');
        expect(pdfResult.format, 'pdf');
      });

      test('error присутствует только при failure', () {
        final success = ShareResult.success('link');
        final failure = ShareResult.failure('csv', 'Error message');

        expect(success.error, isNull);
        expect(failure.error, 'Error message');
      });
    });

    group('интеграционные тесты', () {
      test('shareAsCsv корректно обрабатывает сложный проект', () async {
        final project = _createComplexProject();

        final result = await useCase.shareAsCsv(project);

        expect(result.success, true);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.projectName, 'Complex Project');
        expect(exportData.totalMaterialCost, 8000.0);
        expect(exportData.totalLaborCost, 4000.0);
        expect(exportData.totalCost, 12000.0);
        expect(exportData.calculations.length, 2);
      });

      test('shareAsLink работает со всеми типами проектов', () async {
        final projects = [
          _createTestProject(name: 'Simple'),
          _createTestProject(name: 'With Description', description: 'Desc'),
          _createComplexProject(),
        ];

        for (final project in projects) {
          final result = await useCase.shareAsLink(project);
          expect(result.success, true);
          expect(mockDeepLinkService.lastShareableContent, isNotNull);
        }
      });

      test('все форматы экспорта работают последовательно', () async {
        final project = _createTestProject();

        final linkResult = await useCase.shareAsLink(project);
        final csvResult = await useCase.shareAsCsv(project);
        final pdfResult = await useCase.shareAsPdf(project);

        expect(linkResult.success, true);
        expect(csvResult.success, true);
        expect(pdfResult.success, true);
      });
    });

    group('обработка ошибок', () {
      test('shareAsCsv обрабатывает ошибку доступа к файлу', () async {
        final project = _createTestProject();
        mockCsvExportService.throwOnShare =
            ExportException.permissionDenied('/protected/path');

        expect(
          () => useCase.shareAsCsv(project),
          throwsA(isA<ExportException>()),
        );
      });

      test('exportToCsv обрабатывает ошибку записи файла', () async {
        final project = _createTestProject();
        mockCsvExportService.throwOnExport =
            const FileSystemException('Disk full');

        expect(
          () => useCase.exportToCsv(project),
          throwsA(isA<ExportException>()),
        );
      });

      test('shareAsPdf обрабатывает различные ошибки', () async {
        final project = _createTestProject();

        // PDF generation может упасть, но это не должно крешить приложение
        expect(
          () => useCase.shareAsPdf(project),
          returnsNormally,
        );
      });
    });

    group('граничные случаи', () {
      test('работает с проектом с кириллицей', () async {
        final project = ProjectV2()
          ..name = 'Тестовый проект на русском'
          ..description = 'Описание на русском языке'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        final linkResult = await useCase.shareAsLink(project);
        final csvResult = await useCase.shareAsCsv(project);

        expect(linkResult.success, true);
        expect(csvResult.success, true);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.projectName, 'Тестовый проект на русском');
        expect(exportData.projectDescription, 'Описание на русском языке');
      });

      test('обрабатывает проект с нулевыми стоимостями', () async {
        final calc = ProjectCalculation()
          ..calculatorId = 'test'
          ..name = 'Test Calc'
          ..materialCost = 0.0
          ..laborCost = 0.0;

        final project = ProjectV2()
          ..name = 'Zero Cost Project'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        project.calculations.add(calc);

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.totalMaterialCost, 0.0);
        expect(exportData.totalLaborCost, 0.0);
        expect(exportData.totalCost, 0.0);
      });

      test('обрабатывает расчеты с пустыми inputs/results', () async {
        final calc = ProjectCalculation()
          ..calculatorId = 'empty'
          ..name = 'Empty Calc';

        final project = ProjectV2()
          ..name = 'Project with Empty Calc'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        project.calculations.add(calc);

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.calculations.length, 1);
        expect(exportData.calculations[0].inputs, isEmpty);
        expect(exportData.calculations[0].results, isEmpty);
      });

      test('обрабатывает проект с notes', () async {
        final project = ProjectV2()
          ..name = 'Project with Notes'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now()
          ..notes = 'Important project notes';

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        expect(exportData.notes, 'Important project notes');
      });

      test('обрабатывает проект со всеми статусами', () async {
        for (final status in ProjectStatus.values) {
          final project = ProjectV2()
            ..name = 'Project ${status.name}'
            ..status = status
            ..createdAt = DateTime.now();

          final result = await useCase.shareAsLink(project);
          expect(result.success, true);
        }
      });
    });

    group('конвертация данных', () {
      test('правильно конвертирует inputs и results', () async {
        final calc = ProjectCalculation()
          ..calculatorId = 'brick'
          ..name = 'Brick Calculation';

        calc.setInputsFromMap({
          'length': 10.5,
          'width': 5.25,
          'height': 3.75,
        });

        calc.setResultsFromMap({
          'bricks': 1234.56,
          'mortar': 78.9,
        });

        final project = ProjectV2()
          ..name = 'Test'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        project.calculations.add(calc);

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        final exportCalc = exportData.calculations[0];

        expect(exportCalc.inputs['length'], 10.5);
        expect(exportCalc.inputs['width'], 5.25);
        expect(exportCalc.inputs['height'], 3.75);
        expect(exportCalc.results['bricks'], 1234.56);
        expect(exportCalc.results['mortar'], 78.9);
      });

      test('сохраняет все метаданные расчетов', () async {
        final calc = ProjectCalculation()
          ..calculatorId = 'test_calc'
          ..name = 'Test Calculation'
          ..materialCost = 1234.56
          ..laborCost = 789.01
          ..notes = 'Calculation notes';

        final project = ProjectV2()
          ..name = 'Test'
          ..status = ProjectStatus.planning
          ..createdAt = DateTime.now();

        project.calculations.add(calc);

        await useCase.exportToCsv(project);

        final exportData = mockCsvExportService.lastExportData!;
        final exportCalc = exportData.calculations[0];

        expect(exportCalc.calculatorName, 'Test Calculation');
        expect(exportCalc.materialCost, 1234.56);
        expect(exportCalc.laborCost, 789.01);
        expect(exportCalc.notes, 'Calculation notes');
      });
    });
  });
}

// Helper functions
ProjectV2 _createTestProject({
  String name = 'Test Project',
  String? description,
}) {
  return ProjectV2()
    ..name = name
    ..description = description
    ..status = ProjectStatus.planning
    ..createdAt = DateTime(2024, 1, 1);
}

ProjectV2 _createComplexProject() {
  final calc1 = ProjectCalculation()
    ..calculatorId = 'brick'
    ..name = 'Brick Calc'
    ..materialCost = 5000.0
    ..laborCost = 2500.0;

  calc1.setInputsFromMap({'length': 10.0, 'width': 5.0, 'height': 3.0});
  calc1.setResultsFromMap({'bricks': 1000.0, 'mortar': 50.0});

  final calc2 = ProjectCalculation()
    ..calculatorId = 'tile'
    ..name = 'Tile Calc'
    ..materialCost = 3000.0
    ..laborCost = 1500.0;

  calc2.setInputsFromMap({'area': 25.0, 'tileSize': 0.3});
  calc2.setResultsFromMap({'tiles': 280.0, 'adhesive': 15.0});

  final project = ProjectV2()
    ..name = 'Complex Project'
    ..description = 'A complex test project'
    ..status = ProjectStatus.inProgress
    ..createdAt = DateTime(2024, 1, 1)
    ..notes = 'Test notes';

  project.calculations.add(calc1);
  project.calculations.add(calc2);

  return project;
}
