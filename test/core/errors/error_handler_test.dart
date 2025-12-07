import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('categorizes network errors correctly', () {
      final error = Exception('Network error: socket exception');
      final category = ErrorHandler.getErrorCategory(error);
      
      expect(category, equals(ErrorCategory.network));
    });

    test('categorizes database errors correctly', () {
      final error = Exception('Isar database error');
      final category = ErrorHandler.getErrorCategory(error);
      
      expect(category, equals(ErrorCategory.database));
    });

    test('categorizes parsing errors correctly', () {
      const error = FormatException('JSON parse error');
      final category = ErrorHandler.getErrorCategory(error);
      
      expect(category, equals(ErrorCategory.parsing));
    });

    test('categorizes file system errors correctly', () {
      final error = Exception('File not found: permission denied');
      final category = ErrorHandler.getErrorCategory(error);
      
      expect(category, equals(ErrorCategory.fileSystem));
    });

    test('categorizes validation errors correctly', () {
      final error = Exception('invalid data');
      final category = ErrorHandler.getErrorCategory(error);

      expect(category, equals(ErrorCategory.validation));
    });

    test('categorizes unknown errors as unknown', () {
      final error = Exception('xyz abc qwerty');
      final category = ErrorHandler.getErrorCategory(error);

      expect(category, equals(ErrorCategory.unknown));
    });

    test('returns user-friendly message for network errors', () {
      final error = Exception('Network timeout');
      final message = ErrorHandler.getUserFriendlyMessage(error);

      expect(message, contains('Проблема с сетью'));
    });

    test('returns user-friendly message for database errors', () {
      final error = Exception('Isar error');
      final message = ErrorHandler.getUserFriendlyMessage(error);
      
      expect(message, contains('базы данных'));
    });

    test('returns user-friendly message for parsing errors', () {
      const error = FormatException('JSON decode error');
      final message = ErrorHandler.getUserFriendlyMessage(error);
      
      expect(message, contains('чтения данных'));
    });

    test('returns user-friendly message for file system errors', () {
      final error = Exception('File permission error');
      final message = ErrorHandler.getUserFriendlyMessage(error);
      
      expect(message, contains('файлам'));
    });

    test('returns user-friendly message for validation errors', () {
      final error = Exception('invalid data');
      final message = ErrorHandler.getUserFriendlyMessage(error);

      expect(message, contains('Неверные данные'));
    });

    test('returns generic message for unknown errors', () {
      final error = Exception('xyz abc qwerty');
      final message = ErrorHandler.getUserFriendlyMessage(error);

      expect(message, contains('Произошла ошибка'));
    });

    test('logError does not throw', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      expect(() => ErrorHandler.logError(error, stackTrace, 'TestContext'), 
             returnsNormally);
    });

    test('logFatalError does not throw', () {
      final error = Exception('Fatal error');
      final stackTrace = StackTrace.current;
      
      expect(() => ErrorHandler.logFatalError(error, stackTrace, 'TestContext'), 
             returnsNormally);
    });
  });
}
