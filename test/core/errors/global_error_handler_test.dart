import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/errors/global_error_handler.dart';
import 'package:probrab_ai/core/errors/error_category.dart';
import 'package:probrab_ai/core/exceptions/validation_exception.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/core/exceptions/storage_exception.dart';
import 'package:probrab_ai/core/exceptions/network_exception.dart';
import 'package:probrab_ai/core/exceptions/export_exception.dart';

void main() {
  group('GlobalErrorHandler', () {
    group('getErrorCategory', () {
      test('returns validation for ValidationException', () {
        final error = ValidationException.invalidFormat('test', 'expected');
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.validation,
        );
      });

      test('returns calculation for CalculationException', () {
        final error = CalculationException.invalidInput('calc', 'reason');
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.calculation,
        );
      });

      test('returns storage for StorageException', () {
        final error = StorageException.readError('entity', Exception('err'));
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.storage,
        );
      });

      test('returns network for NetworkException', () {
        final error = NetworkException.noConnection();
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.network,
        );
      });

      test('returns export for ExportException', () {
        final error = ExportException.permissionDenied('/test');
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.export,
        );
      });

      test('returns ui for FlutterError', () {
        final error = FlutterError('Test flutter error');
        expect(
          GlobalErrorHandler.getErrorCategory(error),
          ErrorCategory.ui,
        );
      });

      test('detects network errors by message', () {
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Network error')),
          ErrorCategory.network,
        );
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Socket timeout')),
          ErrorCategory.network,
        );
      });

      test('detects storage errors by message', () {
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Database error')),
          ErrorCategory.storage,
        );
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Isar write failed')),
          ErrorCategory.storage,
        );
      });

      test('detects validation errors by message', () {
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Validation failed')),
          ErrorCategory.validation,
        );
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Invalid input')),
          ErrorCategory.validation,
        );
      });

      test('returns unknown for unrecognized errors', () {
        expect(
          GlobalErrorHandler.getErrorCategory(Exception('Some random error')),
          ErrorCategory.unknown,
        );
      });
    });

    group('getUserFriendlyMessage', () {
      test('returns validation message for ValidationException', () {
        final error = ValidationException.invalidFormat('test', 'expected');
        final message = GlobalErrorHandler.getUserFriendlyMessage(error);
        expect(message, contains('формат'));
      });

      test('returns network message for network errors', () {
        final error = NetworkException.noConnection();
        final message = GlobalErrorHandler.getUserFriendlyMessage(error);
        expect(message.toLowerCase(), contains('интернет'));
      });

      test('returns storage message for storage errors', () {
        final error = StorageException.readError('entity', Exception('err'));
        final message = GlobalErrorHandler.getUserFriendlyMessage(error);
        expect(message.toLowerCase(), anyOf(contains('данн'), contains('прочитать')));
      });

      test('returns export message for export errors', () {
        final error = ExportException.permissionDenied('/path');
        final message = GlobalErrorHandler.getUserFriendlyMessage(error);
        expect(message.toLowerCase(), anyOf(contains('экспорт'), contains('доступ')));
      });

      test('returns flutter error message', () {
        final error = FlutterError('Test');
        final message = GlobalErrorHandler.getUserFriendlyMessage(error);
        expect(message, contains('интерфейс'));
      });

      test('returns generic message for unknown errors', () {
        final message = GlobalErrorHandler.getUserFriendlyMessage(
          Exception('Unknown'),
        );
        expect(message, contains('ошибка'));
      });
    });

    group('logError', () {
      test('logs error without throwing', () {
        expect(
          () => GlobalErrorHandler.logError(
            Exception('Test error'),
            StackTrace.current,
            'Test context',
          ),
          returnsNormally,
        );
      });

      test('logs error without stack trace', () {
        expect(
          () => GlobalErrorHandler.logError(Exception('Test error')),
          returnsNormally,
        );
      });
    });

    group('logFatalError', () {
      test('logs fatal error without throwing', () {
        expect(
          () => GlobalErrorHandler.logFatalError(
            Exception('Fatal error'),
            StackTrace.current,
            'Fatal context',
          ),
          returnsNormally,
        );
      });
    });

    group('showErrorSnackBar', () {
      testWidgets('shows snackbar with error message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.showErrorSnackBar(
                      context,
                      Exception('Test error'),
                    );
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('shows snackbar with retry action', (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.showErrorSnackBar(
                      context,
                      Exception('Test'),
                      onRetry: () => retried = true,
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Повторить'));
        await tester.pumpAndSettle();

        expect(retried, isTrue);
      });
    });

    group('showErrorDialog', () {
      testWidgets('shows dialog with error message', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.showErrorDialog(
                      context,
                      NetworkException.noConnection(),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('ОК'), findsOneWidget);
      });

      testWidgets('dialog can be dismissed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.showErrorDialog(
                      context,
                      Exception('Test'),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('ОК'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('handle', () {
      testWidgets('shows snackbar by default', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.handle(
                      context,
                      Exception('Test'),
                    );
                  },
                  child: const Text('Handle'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Handle'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('shows dialog when useDialog is true', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    GlobalErrorHandler.handle(
                      context,
                      Exception('Test'),
                      useDialog: true,
                    );
                  },
                  child: const Text('Handle'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Handle'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });
  });
}
