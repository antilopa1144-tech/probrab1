import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/providers/review_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReviewState', () {
    test('has correct defaults', () {
      const state = ReviewState();
      expect(state.isReviewCompleted, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('copyWith preserves unspecified fields', () {
      const state = ReviewState();
      final updated = state.copyWith(isReviewCompleted: true);
      expect(updated.isReviewCompleted, isTrue);
      expect(updated.isLoading, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = ReviewState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isReviewCompleted, isFalse);
    });

    test('copyWith updates all fields', () {
      const state = ReviewState();
      final updated = state.copyWith(
        isReviewCompleted: true,
        isLoading: true,
      );
      expect(updated.isReviewCompleted, isTrue);
      expect(updated.isLoading, isTrue);
    });
  });

  group('ReviewNotifier', () {
    test('initializes with default state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(reviewProvider);
      expect(state.isReviewCompleted, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('onCalculatorOpened returns false initially', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reviewProvider.notifier);
      final result = await notifier.onCalculatorOpened();
      expect(result, isFalse);
    });

    test('onCalculatorOpened returns true after threshold', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reviewProvider.notifier);

      // 4 вызова — ещё не порог
      for (int i = 0; i < 4; i++) {
        await notifier.onCalculatorOpened();
      }
      // 5-й вызов — порог
      final result = await notifier.onCalculatorOpened();
      expect(result, isTrue);
    });
  });
}
