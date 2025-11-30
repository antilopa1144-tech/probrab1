import 'app_exception.dart';

/// Исключение при экспорте данных (PDF, Excel и т.д.).
class ExportException extends AppException {
  final String? exportFormat;
  final String? filePath;

  const ExportException(
    super.message, {
    super.code,
    this.exportFormat,
    this.filePath,
    super.details,
  });

  factory ExportException.generationError(String format, Object error) {
    return ExportException(
      'Ошибка при генерации файла формата $format: ${error.toString()}',
      code: 'GENERATION_ERROR',
      exportFormat: format,
      details: error,
    );
  }

  factory ExportException.permissionDenied(String filePath) {
    return ExportException(
      'Нет прав доступа для сохранения файла: $filePath',
      code: 'PERMISSION_DENIED',
      filePath: filePath,
    );
  }

  factory ExportException.insufficientSpace() {
    return const ExportException(
      'Недостаточно места на диске для сохранения файла',
      code: 'INSUFFICIENT_SPACE',
    );
  }

  factory ExportException.invalidData(String reason) {
    return ExportException(
      'Некорректные данные для экспорта: $reason',
      code: 'INVALID_DATA',
      details: reason,
    );
  }

  @override
  String getUserMessage() {
    switch (code) {
      case 'GENERATION_ERROR':
        return 'Не удалось создать файл. Попробуйте ещё раз';
      case 'PERMISSION_DENIED':
        return 'Нет прав доступа к файлам. Проверьте разрешения приложения';
      case 'INSUFFICIENT_SPACE':
        return 'Недостаточно места на устройстве';
      case 'INVALID_DATA':
        return 'Некорректные данные для экспорта';
      default:
        return 'Ошибка экспорта';
    }
  }
}
