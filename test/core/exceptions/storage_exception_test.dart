import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/storage_exception.dart';

void main() {
  group('StorageException', () {
    test('creates instance with all fields', () {
      final exception = StorageException(
        'Test message',
        code: 'TEST_CODE',
        operation: 'test_op',
        entityType: 'TestEntity',
        details: {'key': 'value'},
      );

      expect(exception.message, equals('Test message'));
      expect(exception.code, equals('TEST_CODE'));
      expect(exception.operation, equals('test_op'));
      expect(exception.entityType, equals('TestEntity'));
      expect(exception.details, equals({'key': 'value'}));
    });

    group('factory constructors', () {
      test('notFound creates exception with correct fields', () {
        final exception = StorageException.notFound('Project', '123');

        expect(exception.message, equals('Не найден объект типа "Project" с ID: 123'));
        expect(exception.code, equals('NOT_FOUND'));
        expect(exception.operation, equals('read'));
        expect(exception.entityType, equals('Project'));
        expect(exception.details, equals('123'));
      });

      test('saveError creates exception with correct fields', () {
        final error = Exception('Database locked');
        final exception = StorageException.saveError('Calculation', error);

        expect(exception.message, contains('Ошибка сохранения объекта типа "Calculation"'));
        expect(exception.message, contains('Database locked'));
        expect(exception.code, equals('SAVE_ERROR'));
        expect(exception.operation, equals('save'));
        expect(exception.entityType, equals('Calculation'));
        expect(exception.details, equals(error));
      });

      test('deleteError creates exception with correct fields', () {
        final error = Exception('Permission denied');
        final exception = StorageException.deleteError('Project', error);

        expect(exception.message, contains('Ошибка удаления объекта типа "Project"'));
        expect(exception.message, contains('Permission denied'));
        expect(exception.code, equals('DELETE_ERROR'));
        expect(exception.operation, equals('delete'));
        expect(exception.entityType, equals('Project'));
        expect(exception.details, equals(error));
      });

      test('readError creates exception with correct fields', () {
        final error = Exception('Disk error');
        final exception = StorageException.readError('Price', error);

        expect(exception.message, contains('Ошибка чтения объекта типа "Price"'));
        expect(exception.message, contains('Disk error'));
        expect(exception.code, equals('READ_ERROR'));
        expect(exception.operation, equals('read'));
        expect(exception.entityType, equals('Price'));
        expect(exception.details, equals(error));
      });

      test('databaseError creates exception with correct fields', () {
        final error = Exception('Connection lost');
        final exception = StorageException.databaseError('Failed to connect', error);

        expect(exception.message, equals('Ошибка базы данных: Failed to connect'));
        expect(exception.code, equals('DATABASE_ERROR'));
        expect(exception.details, equals(error));
        expect(exception.operation, isNull);
        expect(exception.entityType, isNull);
      });
    });

    group('getUserMessage', () {
      test('returns user-friendly message for NOT_FOUND', () {
        final exception = StorageException.notFound('Project', '123');
        expect(exception.getUserMessage(), equals('Данные не найдены'));
      });

      test('returns user-friendly message for SAVE_ERROR', () {
        final exception = StorageException.saveError('Project', Exception('error'));
        expect(exception.getUserMessage(), equals('Не удалось сохранить данные'));
      });

      test('returns user-friendly message for DELETE_ERROR', () {
        final exception = StorageException.deleteError('Project', Exception('error'));
        expect(exception.getUserMessage(), equals('Не удалось удалить данные'));
      });

      test('returns user-friendly message for READ_ERROR', () {
        final exception = StorageException.readError('Project', Exception('error'));
        expect(exception.getUserMessage(), equals('Не удалось прочитать данные'));
      });

      test('returns generic message for unknown code', () {
        final exception = StorageException(
          'Test',
          code: 'UNKNOWN_CODE',
        );
        expect(exception.getUserMessage(), equals('Ошибка при работе с данными'));
      });

      test('returns generic message for null code', () {
        final exception = StorageException('Test');
        expect(exception.getUserMessage(), equals('Ошибка при работе с данными'));
      });
    });

    test('toString includes message', () {
      final exception = StorageException('Test error message');
      expect(exception.toString(), contains('Test error message'));
    });

    test('can be caught as AppException', () {
      expect(
        () => throw StorageException.notFound('Test', '1'),
        throwsA(isA<StorageException>()),
      );
    });
  });
}
