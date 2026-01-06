import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/export_exception.dart';
import 'package:probrab_ai/core/exceptions/app_exception.dart';

void main() {
  group('ExportException', () {
    test('creates with message only', () {
      const exception = ExportException('Export failed');

      expect(exception.message, 'Export failed');
      expect(exception.code, isNull);
      expect(exception.exportFormat, isNull);
      expect(exception.filePath, isNull);
      expect(exception.details, isNull);
    });

    test('creates with all parameters', () {
      const exception = ExportException(
        'Failed to export',
        code: 'EXPORT_ERR',
        exportFormat: 'PDF',
        filePath: '/path/to/file.pdf',
        details: 'IO error',
      );

      expect(exception.message, 'Failed to export');
      expect(exception.code, 'EXPORT_ERR');
      expect(exception.exportFormat, 'PDF');
      expect(exception.filePath, '/path/to/file.pdf');
      expect(exception.details, 'IO error');
    });

    test('extends AppException', () {
      const exception = ExportException('Test');

      expect(exception, isA<AppException>());
    });

    group('factory constructors', () {
      group('generationError', () {
        test('creates with correct message', () {
          final exception = ExportException.generationError(
            'PDF',
            Exception('Generation failed'),
          );

          expect(exception.message, contains('PDF'));
          expect(exception.message, contains('Generation failed'));
          expect(exception.code, 'GENERATION_ERROR');
          expect(exception.exportFormat, 'PDF');
          expect(exception.details, isA<Exception>());
        });

        test('works with different formats', () {
          final excelException = ExportException.generationError(
            'Excel',
            'Memory overflow',
          );

          expect(excelException.message, contains('Excel'));
          expect(excelException.message, contains('Memory overflow'));
          expect(excelException.exportFormat, 'Excel');
        });
      });

      group('permissionDenied', () {
        test('creates with file path', () {
          final exception = ExportException.permissionDenied(
            '/storage/documents/report.pdf',
          );

          expect(exception.message, contains('/storage/documents/report.pdf'));
          expect(exception.code, 'PERMISSION_DENIED');
          expect(exception.filePath, '/storage/documents/report.pdf');
        });
      });

      group('insufficientSpace', () {
        test('creates constant exception', () {
          final exception = ExportException.insufficientSpace();

          expect(exception.message, contains('места'));
          expect(exception.code, 'INSUFFICIENT_SPACE');
        });
      });

      group('invalidData', () {
        test('creates with reason', () {
          final exception = ExportException.invalidData(
            'Missing required fields',
          );

          expect(exception.message, contains('Missing required fields'));
          expect(exception.code, 'INVALID_DATA');
          expect(exception.details, 'Missing required fields');
        });
      });
    });

    group('getUserMessage', () {
      test('returns user-friendly message for GENERATION_ERROR', () {
        final exception = ExportException.generationError('PDF', 'error');

        expect(
          exception.getUserMessage(),
          'Не удалось создать файл. Попробуйте ещё раз',
        );
      });

      test('returns user-friendly message for PERMISSION_DENIED', () {
        final exception = ExportException.permissionDenied('/path');

        expect(
          exception.getUserMessage(),
          contains('Нет прав доступа'),
        );
      });

      test('returns user-friendly message for INSUFFICIENT_SPACE', () {
        final exception = ExportException.insufficientSpace();

        expect(
          exception.getUserMessage(),
          contains('места'),
        );
      });

      test('returns user-friendly message for INVALID_DATA', () {
        final exception = ExportException.invalidData('reason');

        expect(
          exception.getUserMessage(),
          contains('Некорректные данные'),
        );
      });

      test('returns default message for unknown code', () {
        const exception = ExportException(
          'Unknown error',
          code: 'UNKNOWN_CODE',
        );

        expect(exception.getUserMessage(), 'Ошибка экспорта');
      });

      test('returns default message for null code', () {
        const exception = ExportException('Some error');

        expect(exception.getUserMessage(), 'Ошибка экспорта');
      });
    });

    test('can be thrown and caught', () {
      expect(
        () => throw ExportException.insufficientSpace(),
        throwsA(isA<ExportException>()),
      );
    });

    test('can be caught as AppException', () {
      try {
        throw ExportException.permissionDenied('/test');
      } on AppException catch (e) {
        expect(e, isA<ExportException>());
        expect(e.code, 'PERMISSION_DENIED');
      }
    });
  });
}
