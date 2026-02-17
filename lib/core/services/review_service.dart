import 'package:flutter/foundation.dart';
import 'package:flutter_rustore_review/flutter_rustore_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tracker_service_web.dart'
    if (dart.library.io) 'tracker_service.dart';

/// Сервис для управления оценками и отзывами через RuStore Review SDK.
///
/// Умный триггер: показывает диалог после [_minCalculationsBeforePrompt] расчётов,
/// но не чаще раза в [_cooldownDays] дней. Если отзыв уже оставлен — больше не спрашивает.
class ReviewService {
  static const String _calculationCountKey = 'review_calculation_count';
  static const String _lastPromptDateKey = 'review_last_prompt_date';
  static const String _reviewCompletedKey = 'review_completed';

  static const int _minCalculationsBeforePrompt = 5;
  static const int _cooldownDays = 30;

  static bool _initialized = false;

  /// Инициализация RuStore Review SDK.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await RustoreReviewClient.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[ReviewService] Init error: $e');
    }
  }

  /// Запросить отзыв через RuStore SDK.
  /// Возвращает true если диалог был показан успешно.
  static Future<bool> requestReview() async {
    await initialize();
    try {
      await RustoreReviewClient.request();
      await RustoreReviewClient.review();
      await _markReviewPrompted();
      TrackerService.trackReviewRequested();
      return true;
    } catch (e) {
      debugPrint('[ReviewService] Review error: $e');
      return false;
    }
  }

  /// Увеличить счётчик расчётов и проверить, пора ли показать диалог.
  /// Возвращает true если нужно показать диалог.
  static Future<bool> incrementAndCheck() async {
    final prefs = await SharedPreferences.getInstance();

    // Если отзыв уже оставлен — больше не спрашиваем
    if (prefs.getBool(_reviewCompletedKey) ?? false) return false;

    // Увеличиваем счётчик
    final count = (prefs.getInt(_calculationCountKey) ?? 0) + 1;
    await prefs.setInt(_calculationCountKey, count);

    // Проверяем порог
    if (count < _minCalculationsBeforePrompt) return false;

    // Проверяем cooldown (не чаще раза в 30 дней)
    final lastPromptMs = prefs.getInt(_lastPromptDateKey) ?? 0;
    if (lastPromptMs > 0) {
      final lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptMs);
      final daysSince = DateTime.now().difference(lastPrompt).inDays;
      if (daysSince < _cooldownDays) return false;
    }

    // Сбрасываем счётчик и записываем дату для cooldown
    await prefs.setInt(_calculationCountKey, 0);
    await prefs.setInt(
      _lastPromptDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return true;
  }

  /// Отметить, что диалог был показан.
  static Future<void> _markReviewPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastPromptDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Отметить, что отзыв оставлен (больше не спрашиваем).
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewCompletedKey, true);
  }

  /// Проверить, оставлен ли отзыв.
  static Future<bool> isReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewCompletedKey) ?? false;
  }

  /// Сбросить состояние (для тестирования).
  @visibleForTesting
  static Future<void> resetState() async {
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calculationCountKey);
    await prefs.remove(_lastPromptDateKey);
    await prefs.remove(_reviewCompletedKey);
  }
}
