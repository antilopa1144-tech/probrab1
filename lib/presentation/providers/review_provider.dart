import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/review_service_web.dart'
    if (dart.library.io) '../../core/services/review_service.dart';

/// Состояние отзыва.
class ReviewState {
  final bool isReviewCompleted;
  final bool isLoading;

  const ReviewState({
    this.isReviewCompleted = false,
    this.isLoading = false,
  });

  ReviewState copyWith({
    bool? isReviewCompleted,
    bool? isLoading,
  }) {
    return ReviewState(
      isReviewCompleted: isReviewCompleted ?? this.isReviewCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier() : super(const ReviewState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await ReviewService.initialize();
    } catch (_) {
      // SDK может быть недоступен (тесты, эмулятор без RuStore)
    }
    try {
      final completed = await ReviewService.isReviewCompleted();
      if (!mounted) return;
      state = state.copyWith(isReviewCompleted: completed);
    } catch (_) {
      // SharedPreferences может быть недоступен
    }
  }

  /// Записать открытие калькулятора и проверить, пора ли показать диалог.
  Future<bool> onCalculatorOpened() async {
    return ReviewService.incrementAndCheck();
  }

  /// Запросить отзыв (через SDK или вручную из настроек).
  Future<bool> requestReview() async {
    state = state.copyWith(isLoading: true);
    final success = await ReviewService.requestReview();
    if (success) {
      state = state.copyWith(isReviewCompleted: true, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
    }
    return success;
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>(
  (ref) => ReviewNotifier(),
);
