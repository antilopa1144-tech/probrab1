import 'app_exception.dart';

/// Исключение при работе с хранилищем данных (база данных, файлы).
class StorageException extends AppException {
  final String? operation;
  final String? entityType;

  const StorageException(
    super.message, {
    super.code,
    this.operation,
    this.entityType,
    super.details,
    super.userMessageKey,
    super.userMessageParams,
    super.fallbackUserMessage,
  });

  factory StorageException.notFound(String entityType, String id) {
    return StorageException(
      'Не найден объект типа "$entityType" с ID: $id',
      code: 'NOT_FOUND',
      operation: 'read',
      entityType: entityType,
      details: id,
      userMessageKey: 'error.message.storage_not_found',
      userMessageParams: {'entityType': entityType},
      fallbackUserMessage: 'Данные не найдены',
    );
  }

  factory StorageException.saveError(String entityType, Object error) {
    return StorageException(
      'Ошибка сохранения объекта типа "$entityType": ${error.toString()}',
      code: 'SAVE_ERROR',
      operation: 'save',
      entityType: entityType,
      details: error,
      userMessageKey: 'error.message.storage_save_error',
      userMessageParams: {'entityType': entityType},
      fallbackUserMessage: 'Не удалось сохранить данные',
    );
  }

  factory StorageException.deleteError(String entityType, Object error) {
    return StorageException(
      'Ошибка удаления объекта типа "$entityType": ${error.toString()}',
      code: 'DELETE_ERROR',
      operation: 'delete',
      entityType: entityType,
      details: error,
      userMessageKey: 'error.message.storage_delete_error',
      userMessageParams: {'entityType': entityType},
      fallbackUserMessage: 'Не удалось удалить данные',
    );
  }

  factory StorageException.readError(String entityType, Object error) {
    return StorageException(
      'Ошибка чтения объекта типа "$entityType": ${error.toString()}',
      code: 'READ_ERROR',
      operation: 'read',
      entityType: entityType,
      details: error,
      userMessageKey: 'error.message.storage_read_error',
      userMessageParams: {'entityType': entityType},
      fallbackUserMessage: 'Не удалось прочитать данные',
    );
  }

  factory StorageException.databaseError(String message, Object error) {
    return StorageException(
      'Ошибка базы данных: $message',
      code: 'DATABASE_ERROR',
      details: error,
      userMessageKey: 'error.message.storage_database_error',
      fallbackUserMessage: 'Ошибка при работе с данными',
    );
  }
}
