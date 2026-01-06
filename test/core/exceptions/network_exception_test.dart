import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/network_exception.dart';
import 'package:probrab_ai/core/exceptions/app_exception.dart';

void main() {
  group('NetworkException', () {
    test('extends AppException', () {
      const exception = NetworkException('test');
      expect(exception, isA<AppException>());
    });

    test('stores message correctly', () {
      const exception = NetworkException('Network error');
      expect(exception.message, 'Network error');
    });

    test('stores optional parameters', () {
      const exception = NetworkException(
        'Test error',
        code: 'TEST_CODE',
        statusCode: 500,
        url: 'https://api.example.com/test',
        details: 'Additional info',
      );

      expect(exception.code, 'TEST_CODE');
      expect(exception.statusCode, 500);
      expect(exception.url, 'https://api.example.com/test');
      expect(exception.details, 'Additional info');
    });

    group('factory constructors', () {
      test('noConnection creates correct exception', () {
        final exception = NetworkException.noConnection();

        expect(exception.code, 'NO_CONNECTION');
        expect(exception.message, contains('подключение к интернету'));
        expect(exception.statusCode, isNull);
        expect(exception.url, isNull);
      });

      test('timeout creates correct exception', () {
        final exception = NetworkException.timeout('https://api.example.com');

        expect(exception.code, 'TIMEOUT');
        expect(exception.message, contains('Превышено время'));
        expect(exception.url, 'https://api.example.com');
      });

      test('timeout works with null url', () {
        final exception = NetworkException.timeout(null);

        expect(exception.code, 'TIMEOUT');
        expect(exception.url, isNull);
      });

      test('serverError creates correct exception', () {
        final exception = NetworkException.serverError(503, 'https://api.example.com');

        expect(exception.code, 'SERVER_ERROR');
        expect(exception.statusCode, 503);
        expect(exception.url, 'https://api.example.com');
        expect(exception.message, contains('503'));
      });

      test('badRequest creates correct exception', () {
        final exception = NetworkException.badRequest(400, 'https://api.example.com');

        expect(exception.code, 'BAD_REQUEST');
        expect(exception.statusCode, 400);
        expect(exception.url, 'https://api.example.com');
        expect(exception.message, contains('400'));
      });

      test('notFound creates correct exception', () {
        final exception = NetworkException.notFound('https://api.example.com/missing');

        expect(exception.code, 'NOT_FOUND');
        expect(exception.statusCode, 404);
        expect(exception.url, 'https://api.example.com/missing');
        expect(exception.message, contains('не найден'));
      });
    });

    group('getUserMessage', () {
      test('returns connection message for NO_CONNECTION', () {
        final exception = NetworkException.noConnection();
        expect(exception.getUserMessage(), 'Проверьте подключение к интернету');
      });

      test('returns timeout message for TIMEOUT', () {
        final exception = NetworkException.timeout(null);
        expect(exception.getUserMessage(), 'Сервер не отвечает. Попробуйте позже');
      });

      test('returns server error message for SERVER_ERROR', () {
        final exception = NetworkException.serverError(500, null);
        expect(exception.getUserMessage(), 'Ошибка на сервере. Попробуйте позже');
      });

      test('returns bad request message for BAD_REQUEST', () {
        final exception = NetworkException.badRequest(400, null);
        expect(exception.getUserMessage(), 'Неверный запрос. Обратитесь в поддержку');
      });

      test('returns not found message for NOT_FOUND', () {
        final exception = NetworkException.notFound(null);
        expect(exception.getUserMessage(), 'Запрошенные данные не найдены');
      });

      test('returns default message for unknown code', () {
        const exception = NetworkException('Unknown error', code: 'UNKNOWN');
        expect(exception.getUserMessage(), 'Ошибка сети. Проверьте подключение');
      });
    });
  });
}
