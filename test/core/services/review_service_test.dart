import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/core/services/review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ReviewService.resetState();
  });

  group('ReviewService', () {
    group('incrementAndCheck', () {
      test('returns false when count < 5', () async {
        for (int i = 0; i < 4; i++) {
          final result = await ReviewService.incrementAndCheck();
          expect(result, isFalse);
        }
      });

      test('returns true when count reaches 5', () async {
        for (int i = 0; i < 4; i++) {
          await ReviewService.incrementAndCheck();
        }
        final result = await ReviewService.incrementAndCheck();
        expect(result, isTrue);
      });

      test('resets counter after trigger — next call returns false', () async {
        for (int i = 0; i < 5; i++) {
          await ReviewService.incrementAndCheck();
        }
        // Счётчик сброшен, а cooldown активен — false
        final result = await ReviewService.incrementAndCheck();
        expect(result, isFalse);
      });

      test('returns false when review already completed', () async {
        await ReviewService.markCompleted();
        for (int i = 0; i < 10; i++) {
          final result = await ReviewService.incrementAndCheck();
          expect(result, isFalse);
        }
      });

      test('respects cooldown period after trigger', () async {
        // Первый триггер
        for (int i = 0; i < 5; i++) {
          await ReviewService.incrementAndCheck();
        }
        // Даже если набрать порог снова — cooldown блокирует
        for (int i = 0; i < 5; i++) {
          final result = await ReviewService.incrementAndCheck();
          expect(result, isFalse);
        }
      });
    });

    group('state management', () {
      test('isReviewCompleted returns false by default', () async {
        expect(await ReviewService.isReviewCompleted(), isFalse);
      });

      test('markCompleted sets completed flag', () async {
        await ReviewService.markCompleted();
        expect(await ReviewService.isReviewCompleted(), isTrue);
      });

      test('resetState clears all state', () async {
        await ReviewService.markCompleted();
        await ReviewService.resetState();
        expect(await ReviewService.isReviewCompleted(), isFalse);
      });
    });

    group('initialize', () {
      test('does not throw on repeated calls', () {
        // initialize использует RuStore SDK — на тестовой платформе
        // может выбросить ошибку, но не должен падать
        expect(() => ReviewService.initialize(), returnsNormally);
        expect(() => ReviewService.initialize(), returnsNormally);
      });
    });
  });
}
