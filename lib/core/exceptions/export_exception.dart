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
    super.userMessageKey,
    super.userMessageParams,
    super.fallbackUserMessage,
  });

  factory ExportException.generationError(String format, Object error) {
    return ExportException(
      'Ошибка при генерации файла формата $format: ${error.toString()}',
      code: 'GENERATION_ERROR',
      exportFormat: format,
      details: error,
      userMessageKey: 'error.message.export_generation_error',
      userMessageParams: {'format': format},
      fallbackUserMessage: 'Не удалось создать файл формата $format. Попробуйте ещё раз',
    );
  }

  factory ExportException.permissionDenied(String filePath) {
    return ExportException(
      'Нет прав доступа для сохранения файла: $filePath',
      code: 'PERMISSION_DENIED',
      filePath: filePath,
      userMessageKey: 'error.message.export_permission_denied',
      fallbackUserMessage:
          'Нет прав доступа к файлам. Проверьте разрешения приложения',
    );
  }

  factory ExportException.insufficientSpace() {
    return const ExportException(
      'Недостаточно места на диске для сохранения файла',
      code: 'INSUFFICIENT_SPACE',
      userMessageKey: 'error.message.export_insufficient_space',
      fallbackUserMessage: 'Недостаточно места на устройстве',
    );
  }

  factory ExportException.invalidData(String reason) {
    return ExportException(
      'Некорректные данные для экспорта: $reason',
      code: 'INVALID_DATA',
      details: reason,
      userMessageKey: 'error.message.export_invalid_data',
      userMessageParams: {'reason': reason},
      fallbackUserMessage: 'Некорректные данные для экспорта: $reason',
    );
  }
}
