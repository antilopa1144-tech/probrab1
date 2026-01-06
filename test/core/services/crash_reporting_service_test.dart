import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/crash_reporting_service.dart';

void main() {
  group('ErrorRecord', () {
    test('creates with all fields', () {
      final timestamp = DateTime.now();
      final stackTrace = StackTrace.current;

      final record = ErrorRecord(
        error: 'Test error',
        stackTrace: stackTrace,
        reason: 'Test reason',
        fatal: true,
        timestamp: timestamp,
      );

      expect(record.error, 'Test error');
      expect(record.stackTrace, stackTrace);
      expect(record.reason, 'Test reason');
      expect(record.fatal, true);
      expect(record.timestamp, timestamp);
    });

    test('creates with minimal fields', () {
      final timestamp = DateTime.now();

      final record = ErrorRecord(
        error: Exception('Test'),
        fatal: false,
        timestamp: timestamp,
      );

      expect(record.error, isA<Exception>());
      expect(record.stackTrace, isNull);
      expect(record.reason, isNull);
      expect(record.fatal, false);
    });

    test('toString returns formatted string', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final record = ErrorRecord(
        error: 'Error message',
        reason: 'Some reason',
        fatal: true,
        timestamp: timestamp,
      );

      final result = record.toString();
      expect(result, contains('ErrorRecord'));
      expect(result, contains('Error message'));
      expect(result, contains('Some reason'));
      expect(result, contains('fatal: true'));
    });
  });

  group('DebugCrashReportingService', () {
    late DebugCrashReportingService service;

    setUp(() {
      service = DebugCrashReportingService();
      service.clearHistory();
    });

    test('is a singleton', () {
      final service1 = DebugCrashReportingService();
      final service2 = DebugCrashReportingService();
      expect(identical(service1, service2), true);
    });

    test('implements CrashReportingService', () {
      expect(service, isA<CrashReportingService>());
    });

    test('initialize completes', () async {
      await expectLater(service.initialize(), completes);
    });

    test('log does not throw', () {
      expect(() => service.log('Test message'), returnsNormally);
    });

    test('setUserId completes', () async {
      await expectLater(service.setUserId('user123'), completes);
    });

    test('setCustomKey completes', () async {
      await expectLater(service.setCustomKey('key', 'value'), completes);
    });

    test('crash does not throw', () {
      expect(() => service.crash(), returnsNormally);
    });

    group('recordError', () {
      test('records error to history', () async {
        await service.recordError(
          'Test error',
          null,
          reason: 'Test reason',
          fatal: false,
        );

        expect(service.errorHistory.length, 1);
        expect(service.errorHistory.first.error, 'Test error');
        expect(service.errorHistory.first.reason, 'Test reason');
        expect(service.errorHistory.first.fatal, false);
      });

      test('records fatal error', () async {
        await service.recordError(
          Exception('Fatal error'),
          StackTrace.current,
          reason: 'Critical failure',
          fatal: true,
        );

        expect(service.errorHistory.length, 1);
        expect(service.errorHistory.first.fatal, true);
      });

      test('records with stack trace', () async {
        final stackTrace = StackTrace.current;
        await service.recordError('Error', stackTrace);

        expect(service.errorHistory.first.stackTrace, stackTrace);
      });

      test('limits history size', () async {
        // Record more than max history size
        for (int i = 0; i < 110; i++) {
          await service.recordError('Error $i', null);
        }

        // Should be limited to 100
        expect(service.errorHistory.length, lessThanOrEqualTo(100));
      });

      test('removes oldest on overflow', () async {
        // Record 105 errors
        for (int i = 0; i < 105; i++) {
          await service.recordError('Error $i', null);
        }

        // First 5 should be removed
        expect(service.errorHistory.first.error, isNot('Error 0'));
        expect(service.errorHistory.last.error, 'Error 104');
      });
    });

    group('errorHistory', () {
      test('returns unmodifiable list', () {
        final history = service.errorHistory;
        expect(() => history.add(
          ErrorRecord(
            error: 'Test',
            fatal: false,
            timestamp: DateTime.now(),
          ),
        ), throwsUnsupportedError);
      });

      test('is empty initially', () {
        expect(service.errorHistory, isEmpty);
      });
    });

    test('clearHistory clears all records', () async {
      await service.recordError('Error 1', null);
      await service.recordError('Error 2', null);
      expect(service.errorHistory.length, 2);

      service.clearHistory();
      expect(service.errorHistory, isEmpty);
    });
  });

  group('FirebaseCrashReportingService', () {
    late FirebaseCrashReportingService service;

    setUp(() {
      service = FirebaseCrashReportingService();
      // Clear debug service history for clean tests
      DebugCrashReportingService().clearHistory();
    });

    test('implements CrashReportingService', () {
      expect(service, isA<CrashReportingService>());
    });

    test('initialize completes', () async {
      await expectLater(service.initialize(), completes);
    });

    test('recordError delegates to debug service', () async {
      await service.recordError(
        'Test error',
        null,
        reason: 'Test reason',
        fatal: false,
      );

      // Check that debug service received the error
      final debugService = DebugCrashReportingService();
      expect(debugService.errorHistory, isNotEmpty);
    });

    test('log delegates to debug service', () {
      expect(() => service.log('Test message'), returnsNormally);
    });

    test('setUserId delegates to debug service', () async {
      await expectLater(service.setUserId('user123'), completes);
    });

    test('setCustomKey delegates to debug service', () async {
      await expectLater(service.setCustomKey('key', 'value'), completes);
    });

    test('crash delegates to debug service', () {
      expect(() => service.crash(), returnsNormally);
    });
  });

  group('crashReporting global instance', () {
    test('is DebugCrashReportingService by default', () {
      expect(crashReporting, isA<DebugCrashReportingService>());
    });

    test('can be replaced', () {
      final originalService = crashReporting;
      final newService = FirebaseCrashReportingService();

      crashReporting = newService;
      expect(crashReporting, newService);

      // Restore original
      crashReporting = originalService;
    });
  });

  group('runSafe', () {
    setUp(() {
      DebugCrashReportingService().clearHistory();
    });

    test('returns result on success', () async {
      final result = await runSafe<int>(() async => 42);
      expect(result, 42);
    });

    test('returns fallback on error', () async {
      final result = await runSafe<int>(
        () async => throw Exception('Test error'),
        fallback: -1,
      );
      expect(result, -1);
    });

    test('returns null when no fallback on error', () async {
      final result = await runSafe<int>(
        () async => throw Exception('Test error'),
      );
      expect(result, isNull);
    });

    test('records error on failure', () async {
      await runSafe<int>(
        () async => throw Exception('Test error'),
        context: 'Test context',
      );

      final debugService = DebugCrashReportingService();
      expect(debugService.errorHistory, isNotEmpty);
      expect(debugService.errorHistory.first.reason, 'Test context');
    });

    test('records default reason when context is null', () async {
      await runSafe<int>(
        () async => throw Exception('Test error'),
      );

      final debugService = DebugCrashReportingService();
      expect(debugService.errorHistory, isNotEmpty);
      expect(debugService.errorHistory.first.reason, 'runSafe error');
    });

    test('works with async operations', () async {
      final result = await runSafe<String>(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'success';
      });
      expect(result, 'success');
    });

    test('handles different exception types', () async {
      // ArgumentError
      var result = await runSafe<int>(
        () async => throw ArgumentError('Invalid'),
        fallback: 0,
      );
      expect(result, 0);

      // StateError
      result = await runSafe<int>(
        () async => throw StateError('Bad state'),
        fallback: 1,
      );
      expect(result, 1);

      // FormatException
      result = await runSafe<int>(
        () async => throw const FormatException('Bad format'),
        fallback: 2,
      );
      expect(result, 2);
    });
  });
}
