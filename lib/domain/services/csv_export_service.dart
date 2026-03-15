import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/exceptions/export_exception.dart';
import '../models/export_data.dart';

class CsvExportLabels {
  final String project;
  final String description;
  final String createdAt;
  final String calculator;
  final String parameter;
  final String value;
  final String unit;
  final String materialCost;
  final String laborCost;
  final String total;
  final String materials;
  final String labor;
  final String grandTotal;
  final String notes;

  const CsvExportLabels({
    required this.project,
    required this.description,
    required this.createdAt,
    required this.calculator,
    required this.parameter,
    required this.value,
    required this.unit,
    required this.materialCost,
    required this.laborCost,
    required this.total,
    required this.materials,
    required this.labor,
    required this.grandTotal,
    required this.notes,
  });
}

class CsvShareCopy {
  final String subject;
  final String text;

  const CsvShareCopy({
    required this.subject,
    required this.text,
  });
}

/// Сервис экспорта данных в CSV.
class CsvExportService {
  /// Экспортировать данные в CSV файл
  Future<File> exportToCsv(
    ExportData data, {
    required CsvExportLabels labels,
    String? filename,
  }) async {
    try {
      final fileName = filename ?? _generateFileName(data.projectName);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final csvContent = _convertToCsv(_buildCsvRows(data, labels));
      final file = File(filePath);
      await file.writeAsString(csvContent);
      return file;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        throw ExportException.permissionDenied(e.path ?? '');
      }
      throw ExportException.generationError('csv', e);
    } catch (e) {
      throw ExportException.generationError('csv', e);
    }
  }

  /// Экспортировать и поделиться файлом
  Future<void> exportAndShare(
    ExportData data, {
    required CsvExportLabels labels,
    required CsvShareCopy shareCopy,
    String? filename,
  }) async {
    try {
      final file = await exportToCsv(
        data,
        labels: labels,
        filename: filename,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: shareCopy.subject,
        text: shareCopy.text,
      );
    } catch (e) {
      if (e is ExportException) rethrow;
      throw ExportException.generationError('csv', e);
    }
  }

  List<List<String>> _buildCsvRows(ExportData data, CsvExportLabels labels) {
    final rows = <List<String>>[];

    rows.add([labels.project, data.projectName]);
    if (data.projectDescription != null) {
      rows.add([labels.description, data.projectDescription!]);
    }
    rows.add([labels.createdAt, _formatDate(data.createdAt)]);
    rows.add([]);

    rows.add([
      labels.calculator,
      labels.parameter,
      labels.value,
      labels.unit,
      labels.materialCost,
      labels.laborCost,
    ]);

    for (final calc in data.calculations) {
      rows.add([
        calc.calculatorName,
        '',
        '',
        '',
        calc.materialCost?.toStringAsFixed(2) ?? '',
        calc.laborCost?.toStringAsFixed(2) ?? '',
      ]);

      calc.inputs.forEach((key, value) {
        rows.add(['', key, value.toStringAsFixed(2), '', '', '']);
      });

      calc.results.forEach((key, value) {
        rows.add(['', key, value.toStringAsFixed(2), '', '', '']);
      });

      rows.add([]);
    }

    rows.add([labels.total, '', '', '', '', '']);
    rows.add([
      labels.materials,
      '',
      '',
      '',
      data.totalMaterialCost.toStringAsFixed(2),
      '',
    ]);
    rows.add([
      labels.labor,
      '',
      '',
      '',
      '',
      data.totalLaborCost.toStringAsFixed(2),
    ]);
    rows.add([
      labels.grandTotal,
      '',
      '',
      '',
      data.totalCost.toStringAsFixed(2),
      '',
    ]);

    if (data.notes != null) {
      rows.add([]);
      rows.add([labels.notes, data.notes!]);
    }

    return rows;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Конвертировать строки в CSV формат
  String _convertToCsv(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        if (cell.contains(',') || cell.contains('"') || cell.contains('\n')) {
          return '"${cell.replaceAll('"', '""')}"';
        }
        return cell;
      }).join(',');
    }).join('\n');
  }

  /// Генерировать имя файла
  String _generateFileName(String projectName) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final cleanName = projectName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return 'probrab_${cleanName}_${dateStr}_$timeStr.csv';
  }

  /// Получить путь к директории экспортов
  Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir.path;
  }

  /// Получить список всех экспортированных файлов
  Future<List<File>> getExportedFiles() async {
    try {
      final exportPath = await getExportDirectory();
      final directory = Directory(exportPath);

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.csv'))
          .cast<File>()
          .toList();

      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      throw ExportException.generationError('csv', e);
    }
  }

  /// Удалить экспортированный файл
  Future<void> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ExportException.generationError('csv', e);
    }
  }
}
// ignore_for_file: deprecated_member_use, avoid_slow_async_io
