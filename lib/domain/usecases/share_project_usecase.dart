import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import '../models/project_v2.dart';
import '../models/shareable_content.dart';
import '../models/export_data.dart';
import '../services/csv_export_service.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/exceptions/export_exception.dart';
// ignore: implementation_imports
import '../../presentation/services/pdf_export_service.dart';

/// Use case для шаринга проектов в различных форматах
class ShareProjectUseCase {
  final CsvExportService _csvExportService;
  final DeepLinkService _deepLinkService;

  ShareProjectUseCase({
    CsvExportService? csvExportService,
    DeepLinkService? deepLinkService,
  })  : _csvExportService = csvExportService ?? CsvExportService(),
        _deepLinkService = deepLinkService ?? DeepLinkService.instance;

  /// Поделиться проектом как Deep Link
  Future<ShareResult> shareAsLink(
    ProjectV2 project, {
    bool compact = true,
  }) async {
    try {
      final shareableProject = ShareableProject.fromProject(project);
      final link = _deepLinkService.createProjectLink(
        shareableProject,
        compact: compact,
      );

      await SharePlus.instance.share(
        ShareParams(
          text: 'Проект "${project.name}"\n\n'
              'Откройте ссылку в приложении Мастерок:\n'
              '$link',
          subject: 'Проект ${project.name}',
        ),
      );

      return ShareResult.success('link');
    } catch (e) {
      throw ExportException.generationError('Link', e);
    }
  }

  /// Поделиться проектом как CSV файл
  Future<ShareResult> shareAsCsv(
    ProjectV2 project, {
    String? filename,
  }) async {
    try {
      final exportData = _projectToExportData(project);
      await _csvExportService.exportAndShare(
        exportData,
        filename: filename,
      );

      return ShareResult.success('csv');
    } catch (e) {
      if (e is ExportException) rethrow;
      throw ExportException.generationError('CSV', e);
    }
  }

  /// Поделиться проектом как PDF файл
  Future<ShareResult> shareAsPdf(ProjectV2 project, [BuildContext? context]) async {
    try {
      if (context == null) throw ExportException.generationError('PDF', 'BuildContext required');
      // ignore: use_build_context_synchronously
      final filePath = await PdfExportService.exportProject(project, context);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Проект ${project.name}',
          text: 'PDF экспорт проекта "${project.name}"',
        ),
      );

      return ShareResult.success('pdf');
    } catch (e) {
      if (e is ExportException) rethrow;
      throw ExportException.generationError('PDF', e);
    }
  }

  /// Экспортировать проект в CSV файл (без шаринга)
  Future<File> exportToCsv(
    ProjectV2 project, {
    String? filename,
  }) async {
    try {
      final exportData = _projectToExportData(project);
      return await _csvExportService.exportToCsv(
        exportData,
        filename: filename,
      );
    } catch (e) {
      if (e is ExportException) rethrow;
      throw ExportException.generationError('CSV', e);
    }
  }

  /// Получить Deep Link для проекта
  String getProjectLink(
    ProjectV2 project, {
    bool compact = true,
  }) {
    final shareableProject = ShareableProject.fromProject(project);
    return _deepLinkService.createProjectLink(
      shareableProject,
      compact: compact,
    );
  }

  /// Конвертировать проект в ExportData
  ExportData _projectToExportData(ProjectV2 project) {
    return ExportData(
      projectName: project.name,
      projectDescription: project.description,
      createdAt: project.createdAt,
      calculations: project.calculations.map((calc) {
        return ExportCalculation(
          calculatorName: calc.name,
          inputs: calc.inputsMap,
          results: calc.resultsMap,
          materialCost: calc.materialCost,
          laborCost: calc.laborCost,
          notes: calc.notes,
        );
      }).toList(),
      totalMaterialCost: project.totalMaterialCost,
      totalLaborCost: project.totalLaborCost,
      totalCost: project.totalCost,
      notes: project.notes,
    );
  }

}

/// Результат операции шаринга
class ShareResult {
  final bool success;
  final String format;
  final String? error;

  ShareResult._({
    required this.success,
    required this.format,
    this.error,
  });

  factory ShareResult.success(String format) {
    return ShareResult._(
      success: true,
      format: format,
    );
  }

  factory ShareResult.failure(String format, String error) {
    return ShareResult._(
      success: false,
      format: format,
      error: error,
    );
  }
}
