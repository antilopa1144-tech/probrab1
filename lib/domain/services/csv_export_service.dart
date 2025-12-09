import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/exceptions/export_exception.dart';
import '../models/export_data.dart';

/// Сервис экспорта данных в CSV.
class CsvExportService {
  /// Экспортировать данные в CSV файл
  Future<File> exportToCsv(
    ExportData data, {
    String? filename,
  }) async {
    try {
      // Генерируем имя файла
      final fileName = filename ?? _generateFileName(data.projectName);

      // Получаем директорию для сохранения
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Конвертируем данные в CSV
      final csvContent = _convertToCsv(data.toCsvRows());

      // Сохраняем файл
      final file = File(filePath);
      await file.writeAsString(csvContent);

      return file;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        throw ExportException.permissionDenied(e.path ?? '');
      }
      throw ExportException.generationError('CSV', e);
    } catch (e) {
      throw ExportException.generationError('CSV', e);
    }
  }

  /// Экспортировать и поделиться файлом
  Future<void> exportAndShare(
    ExportData data, {
    String? filename,
  }) async {
    try {
      final file = await exportToCsv(data, filename: filename);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Экспорт проекта: ${data.projectName}',
        text: 'Данные проекта "${data.projectName}"',
      );
    } catch (e) {
      if (e is ExportException) rethrow;
      throw ExportException.generationError('CSV', e);
    }
  }

  /// Конвертировать строки в CSV формат
  String _convertToCsv(List<List<String>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        // Экранируем запятые и кавычки
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

    // Очищаем название проекта от недопустимых символов
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

      // Сортируем по дате изменения (новые первыми)
      files.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      throw ExportException.generationError('CSV', e);
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
      throw ExportException.generationError('CSV', e);
    }
  }
}
// ignore_for_file: deprecated_member_use, avoid_slow_async_io
