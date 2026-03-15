import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/core/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService', () {
    setUp(() {
      AiService.resetInstance();
    });

    // =========================================================================
    // Дневной лимит
    // =========================================================================

    // _maxDailyRequests = 20 (лимит 20 запросов в день).
    // checkDailyLimit() бросает AiDailyLimitException при превышении.
    group('Daily Limit (20 requests/day)', () {
      test('allows requests when count is below limit', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 5,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });

      test('allows requests when count is 0', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 0,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });

      test('allows requests at count 19 (below limit)', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 19,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });

      test('throws AiDailyLimitException at count 20 (limit reached)', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 20,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(
          () => service.checkDailyLimit(),
          throwsA(isA<AiDailyLimitException>()),
        );
      });

      test('throws AiDailyLimitException at very high count', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 50,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(
          () => service.checkDailyLimit(),
          throwsA(isA<AiDailyLimitException>()),
        );
      });

      test('AiDailyLimitException stores message correctly', () {
        const e = AiDailyLimitException(
          'ai.daily_limit',
          fallbackMessage: 'Всё, начальник, смена окончена. Голова пухнет, приходи завтра!',
        );
        expect(e.message, contains('смена окончена'));
        expect(e.message, contains('приходи завтра'));
      });

      test('allows requests on new day (counter resets)', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 20,
          'ai_last_request_date': '2020-01-01',
        });

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });

      test('allows requests when last date is yesterday', () async {
        final yesterday =
            DateTime.now().subtract(const Duration(days: 1));
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 20,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(yesterday),
        });

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });

      test('works when no previous data exists', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        await service.checkDailyLimit();
      });
    });

    // =========================================================================
    // Оставшиеся запросы
    // =========================================================================

    // _maxDailyRequests = 20:
    // getRemainingRequests() возвращает (20 - count).clamp(0, 20)
    group('getRemainingRequests (20/day limit)', () {
      test('returns 13 when count is 7', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 7,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(13));
      });

      test('returns 20 on new day (counter resets)', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 15,
          'ai_last_request_date': '2020-01-01',
        });

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(20));
      });

      test('returns 0 at count 20 (limit exhausted)', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 20,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(0));
      });

      test('never goes below 0', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 999,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(0));
      });

      test('returns 20 when no data exists (fresh start)', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(20));
      });

      test('returns 1 at count 19', () async {
        SharedPreferences.setMockInitialValues({
          'ai_request_count': 19,
          'ai_last_request_date':
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });

        final service = await AiService.instance;
        expect(service.getRemainingRequests(), equals(1));
      });
    });

    // =========================================================================
    // maxDailyRequests
    // =========================================================================

    group('maxDailyRequests', () {
      test('returns 20', () async {
        SharedPreferences.setMockInitialValues({});
        final service = await AiService.instance;
        expect(service.maxDailyRequests, equals(20));
      });
    });

    // =========================================================================
    // Контекст проекта
    // =========================================================================

    group('Project Context', () {
      test('returns default "Ремонт квартиры" when not set', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        expect(service.getProjectContext(), equals('Ремонт квартиры'));
      });

      test('returns saved project type', () async {
        SharedPreferences.setMockInitialValues({
          'user_project_type': 'Строительство дома',
        });

        final service = await AiService.instance;
        expect(service.getProjectContext(), equals('Строительство дома'));
      });

      test('saves and retrieves project type', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        await service.setProjectContext('Баня');
        expect(service.getProjectContext(), equals('Баня'));
      });

      test('overwrites previously saved project type', () async {
        SharedPreferences.setMockInitialValues({
          'user_project_type': 'Гараж',
        });

        final service = await AiService.instance;
        expect(service.getProjectContext(), equals('Гараж'));

        await service.setProjectContext('Дача');
        expect(service.getProjectContext(), equals('Дача'));
      });

      test('handles empty string project type', () async {
        SharedPreferences.setMockInitialValues({
          'user_project_type': '',
        });

        final service = await AiService.instance;
        // Empty string is returned as-is (not default)
        expect(service.getProjectContext(), equals(''));
      });

      test('handles unicode project type', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        await service.setProjectContext('Коттедж 🏠 200м²');
        expect(service.getProjectContext(), equals('Коттедж 🏠 200м²'));
      });
    });

    // =========================================================================
    // Быстрые советы (getQuickTip)
    // =========================================================================

    group('Quick Tips', () {
      late AiService service;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        service = await AiService.instance;
      });

      group('zero/negative values', () {
        test('returns tip for zero value', () {
          final tip = service.getQuickTip('foundation', {'length': 0});
          expect(tip, isNotNull);
          expect(tip, contains('реальные цифры'));
        });

        test('returns tip for negative value', () {
          final tip = service.getQuickTip('foundation', {'width': -5});
          expect(tip, isNotNull);
          expect(tip, contains('реальные цифры'));
        });

        test('includes field name in tip', () {
          final tip = service.getQuickTip('tile', {'length': 0});
          expect(tip, contains('length'));
        });

        test('detects first zero field in multiple inputs', () {
          final tip = service.getQuickTip('laminate', {
            'area': 20.0,
            'height': 0,
            'width': 5.0,
          });
          expect(tip, isNotNull);
          expect(tip, contains('height'));
        });

        test('returns tip for exactly 0.0', () {
          final tip = service.getQuickTip('paint', {'area': 0.0});
          expect(tip, isNotNull);
          expect(tip, contains('реальные цифры'));
        });
      });

      group('excessive area', () {
        test('returns tip for area > 500', () {
          final tip = service.getQuickTip('laminate', {'area': 600});
          expect(tip, isNotNull);
          expect(tip, contains('космодром'));
        });

        test('returns tip for area exactly 501', () {
          final tip = service.getQuickTip('tile', {'area': 501});
          expect(tip, isNotNull);
          expect(tip, contains('космодром'));
        });

        test('returns null for area exactly 500', () {
          final tip = service.getQuickTip('tile', {'area': 500});
          expect(tip, isNull);
        });

        test('uses length when area not present', () {
          final tip = service.getQuickTip('tile', {'length': 600});
          expect(tip, isNotNull);
          expect(tip, contains('космодром'));
        });
      });

      group('excessive height', () {
        test('returns tip for height > 5', () {
          final tip = service.getQuickTip('wallpaper', {'height': 7.0});
          expect(tip, isNotNull);
          expect(tip, contains('Потолки'));
          expect(tip, contains('7.0'));
        });

        test('returns tip for wallHeight > 5', () {
          final tip = service.getQuickTip('drywall', {'wallHeight': 6.0});
          expect(tip, isNotNull);
          expect(tip, contains('Потолки'));
        });

        test('returns null for height exactly 5', () {
          final tip = service.getQuickTip('paint', {'height': 5.0});
          expect(tip, isNull);
        });

        test('returns tip for height 5.1', () {
          final tip = service.getQuickTip('paint', {'height': 5.1});
          expect(tip, isNotNull);
          expect(tip, contains('5.1'));
        });

        test('includes standard range in tip', () {
          final tip = service.getQuickTip('wallpaper', {'height': 8.0});
          expect(tip, contains('2.5-3.0'));
        });
      });

      group('normal values', () {
        test('returns null for typical room', () {
          final tip = service.getQuickTip('laminate', {
            'area': 20.0,
            'height': 2.7,
          });
          expect(tip, isNull);
        });

        test('returns null for empty inputs', () {
          final tip = service.getQuickTip('foundation', {});
          expect(tip, isNull);
        });

        test('returns null for all positive values', () {
          final tip = service.getQuickTip('concrete', {
            'length': 10.0,
            'width': 5.0,
            'height': 3.0,
          });
          expect(tip, isNull);
        });

        test('returns null for small positive value', () {
          final tip = service.getQuickTip('tile', {'area': 0.5});
          expect(tip, isNull);
        });
      });

      group('priority of checks', () {
        test('zero check takes priority over area check', () {
          final tip = service.getQuickTip('tile', {
            'width': 0,
            'area': 600,
          });
          // Zero check runs first in the loop
          expect(tip, contains('реальные цифры'));
        });
      });
    });

    // =========================================================================
    // Исключения
    // =========================================================================

    group('Exceptions', () {
      test('AiDailyLimitException toString returns message', () {
        const exception = AiDailyLimitException('ai.daily_limit', fallbackMessage: 'test message');
        expect(exception.toString(), equals('test message'));
        expect(exception.message, equals('test message'));
      });

      test('AiApiException toString returns message', () {
        const exception = AiApiException('ai.api_error', fallbackMessage: 'api error');
        expect(exception.toString(), equals('api error'));
        expect(exception.message, equals('api error'));
      });

      test('AiDailyLimitException is an Exception', () {
        const exception = AiDailyLimitException('ai.daily_limit', fallbackMessage: 'msg');
        expect(exception, isA<Exception>());
      });

      test('AiApiException is an Exception', () {
        const exception = AiApiException('ai.api_error', fallbackMessage: 'msg');
        expect(exception, isA<Exception>());
      });

      test('AiDailyLimitException supports const', () {
        const a = AiDailyLimitException('ai.daily_limit', fallbackMessage: 'same');
        const b = AiDailyLimitException('ai.daily_limit', fallbackMessage: 'same');
        expect(a.message, equals(b.message));
      });
    });

    // =========================================================================
    // AiAdviceResult
    // =========================================================================

    group('AiAdviceResult', () {
      test('stores text and remaining requests', () {
        const result = AiAdviceResult(
          text: 'Совет от Михалыча',
          remainingRequests: 15,
        );

        expect(result.text, equals('Совет от Михалыча'));
        expect(result.remainingRequests, equals(15));
      });

      test('handles empty text', () {
        const result = AiAdviceResult(
          text: '',
          remainingRequests: 0,
        );

        expect(result.text, isEmpty);
        expect(result.remainingRequests, equals(0));
      });

      test('handles multiline text', () {
        const result = AiAdviceResult(
          text: 'Строка 1\nСтрока 2\nСтрока 3',
          remainingRequests: 10,
        );

        expect(result.text, contains('\n'));
        expect(result.remainingRequests, equals(10));
      });

      test('supports const constructor', () {
        const result = AiAdviceResult(
          text: 'const',
          remainingRequests: 5,
        );
        expect(result.text, equals('const'));
      });
    });

    // =========================================================================
    // Singleton и инициализация
    // =========================================================================

    group('Singleton', () {
      test('returns same instance on multiple calls', () async {
        SharedPreferences.setMockInitialValues({});

        final instance1 = await AiService.instance;
        final instance2 = await AiService.instance;
        expect(identical(instance1, instance2), isTrue);
      });

      test('resetInstance creates new instance', () async {
        SharedPreferences.setMockInitialValues({});

        final instance1 = await AiService.instance;
        AiService.resetInstance();

        SharedPreferences.setMockInitialValues({});
        final instance2 = await AiService.instance;

        expect(identical(instance1, instance2), isFalse);
      });

      test('forTesting constructor creates instance', () {
        final service = AiService.forTesting();
        expect(service, isNotNull);
      });
    });

    // =========================================================================
    // Управление чатом
    // =========================================================================

    group('Chat management', () {
      test('resetChat does not throw', () async {
        SharedPreferences.setMockInitialValues({});
        final service = await AiService.instance;
        expect(() => service.resetChat(), returnsNormally);
      });

      test('resetChat can be called multiple times', () async {
        SharedPreferences.setMockInitialValues({});
        final service = await AiService.instance;
        service.resetChat();
        service.resetChat();
        service.resetChat();
      });
    });

    // =========================================================================
    // getAdvice — проверка лимита (без реального API)
    // =========================================================================

    group('getAdvice API key check', () {
      test('throws AiApiException when API key is missing', () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        expect(
          () => service.getAdvice(
            calculatorName: 'Обои',
            data: {'area': 20.0},
          ),
          throwsA(isA<AiApiException>()),
        );
      });

      test('getAdviceStream throws AiApiException when API key is missing',
          () async {
        SharedPreferences.setMockInitialValues({});

        final service = await AiService.instance;
        expect(
          () => service
              .getAdviceStream(
                calculatorName: 'Плитка',
                data: {'area': 10.0},
              )
              .first,
          throwsA(isA<AiApiException>()),
        );
      });
    });
  });
}
