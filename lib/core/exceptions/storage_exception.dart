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
  });

  factory StorageException.notFound(String entityType, String id) {
    return StorageException(
      'Не найден объект типа "$entityType" с ID: $id',
      code: 'NOT_FOUND',
      operation: 'read',
      entityType: entityType,
      details: id,
    );
  }

  factory StorageException.saveError(String entityType, Object error) {
    return StorageException(
      'Ошибка сохранения объекта типа "$entityType": ${error.toString()}',
      code: 'SAVE_ERROR',
      operation: 'save',
      entityType: entityType,
      details: error,
    );
  }

  factory StorageException.deleteError(String entityType, Object error) {
    return StorageException(
      'Ошибка удаления объекта типа "$entityType": ${error.toString()}',
      code: 'DELETE_ERROR',
      operation: 'delete',
      entityType: entityType,
      details: error,
    );
  }

  factory StorageException.readError(String entityType, Object error) {
    return StorageException(
      'Ошибка чтения объекта типа "$entityType": ${error.toString()}',
      code: 'READ_ERROR',
      operation: 'read',
      entityType: entityType,
      details: error,
    );
  }

  factory StorageException.databaseError(String message, Object error) {
    return StorageException(
      'Ошибка базы данных: $message',
      code: 'DATABASE_ERROR',
      details: error,
    );
  }

  @override
  String getUserMessage() {
    switch (code) {
      case 'NOT_FOUND':
        return 'Данные не найдены';
      case 'SAVE_ERROR':
        return 'Не удалось сохранить данные';
      case 'DELETE_ERROR':
        return 'Не удалось удалить данные';
      case 'READ_ERROR':
        return 'Не удалось прочитать данные';
      default:
        return 'Ошибка при работе с данными';
    }
  }
}
