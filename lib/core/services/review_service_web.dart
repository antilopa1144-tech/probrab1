// Веб-заглушка для ReviewService
// Оценки через RuStore не поддерживаются на вебе

import 'package:flutter/foundation.dart';

/// Веб-заглушка для ReviewService.
/// RuStore Review SDK не поддерживается на вебе.
class ReviewService {
  static Future<void> initialize() async {
    // На вебе ничего не делаем
  }

  static Future<bool> requestReview() async {
    return false;
  }

  static Future<bool> incrementAndCheck() async {
    return false;
  }

  static Future<void> markCompleted() async {}

  static Future<bool> isReviewCompleted() async => false;

  @visibleForTesting
  static Future<void> resetState() async {}
}
