import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/app_exception.dart';

/// Concrete implementation for testing the abstract class
class TestException extends AppException {
  const TestException(
    super.message, {
    super.code,
    super.details,
  });
}

void main() {
  group('AppException', () {
    test('creates with message only', () {
      const exception = TestException('Test error message');

      expect(exception.message, 'Test error message');
      expect(exception.code, isNull);
      expect(exception.details, isNull);
    });

    test('creates with message and code', () {
      const exception = TestException(
        'Test error',
        code: 'TEST_CODE',
      );

      expect(exception.message, 'Test error');
      expect(exception.code, 'TEST_CODE');
      expect(exception.details, isNull);
    });

    test('creates with all parameters', () {
      const exception = TestException(
        'Test error',
        code: 'ERROR_001',
        details: {'key': 'value'},
      );

      expect(exception.message, 'Test error');
      expect(exception.code, 'ERROR_001');
      expect(exception.details, {'key': 'value'});
    });

    group('toString', () {
      test('returns formatted string with message only', () {
        const exception = TestException('Simple message');

        final result = exception.toString();

        expect(result, contains('TestException:'));
        expect(result, contains('Simple message'));
        expect(result, isNot(contains('[')));
      });

      test('returns formatted string with code', () {
        const exception = TestException(
          'Error message',
          code: 'ERR_01',
        );

        final result = exception.toString();

        expect(result, contains('[ERR_01]'));
        expect(result, contains('Error message'));
      });

      test('returns formatted string with details', () {
        const exception = TestException(
          'Error',
          details: 'Additional info',
        );

        final result = exception.toString();

        expect(result, contains('Error'));
        expect(result, contains('Details: Additional info'));
      });

      test('returns formatted string with all fields', () {
        const exception = TestException(
          'Full error',
          code: 'FULL_ERR',
          details: {'stack': 'trace'},
        );

        final result = exception.toString();

        expect(result, contains('TestException:'));
        expect(result, contains('[FULL_ERR]'));
        expect(result, contains('Full error'));
        expect(result, contains('Details:'));
        expect(result, contains('stack'));
      });
    });

    group('getUserMessage', () {
      test('returns message by default', () {
        const exception = TestException('User-friendly message');

        expect(exception.getUserMessage(), 'User-friendly message');
      });

      test('returns message regardless of code', () {
        const exception = TestException(
          'This is shown to user',
          code: 'INTERNAL_CODE',
        );

        expect(exception.getUserMessage(), 'This is shown to user');
      });
    });

    test('implements Exception interface', () {
      const exception = TestException('Test');

      expect(exception, isA<Exception>());
    });

    test('can be thrown and caught', () {
      expect(
        () => throw const TestException('Thrown exception'),
        throwsA(isA<AppException>()),
      );
    });

    test('can catch specific exception type', () {
      try {
        throw const TestException('Specific error', code: 'SPEC_ERR');
      } on AppException catch (e) {
        expect(e.message, 'Specific error');
        expect(e.code, 'SPEC_ERR');
      }
    });
  });
}
