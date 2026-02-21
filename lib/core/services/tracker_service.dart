import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Сервис аналитики на базе Firebase Analytics.
///
/// Все события соответствуют именованию Firebase (snake_case, max 40 chars).
class TrackerService {
  static bool _initialized = false;
  static FirebaseAnalytics? _analytics;

  static Future<void> initialize(String sdkKey) async {
    if (_initialized) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[TrackerService] Firebase Analytics initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TrackerService] Failed to initialize: $e');
      }
    }
  }

  static Future<void> trackEvent(
    String name, [
    Map<String, String>? params,
  ]) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: params?.map((k, v) => MapEntry(k, v)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackEvent error: $e');
    }
  }

  static Future<void> trackCalculatorUsed({
    required String calculatorId,
    required String category,
    String? subcategory,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'calculator_used',
        parameters: {
          'calculator_id': calculatorId,
          'category': category,
          if (subcategory != null) 'subcategory': subcategory,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackCalculatorUsed: $e');
    }
  }

  static Future<void> trackCalculatorOpened(String calculatorId) async {
    try {
      await _analytics?.logEvent(
        name: 'calculator_opened',
        parameters: {'calculator_id': calculatorId},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackCalculatorOpened: $e');
    }
  }

  static Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackScreenView: $e');
    }
  }

  static Future<void> trackExport({
    required String type,
    required String calculatorId,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'export',
        parameters: {
          'type': type,
          'calculator_id': calculatorId,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackExport: $e');
    }
  }

  static Future<void> trackFavorite({
    required String calculatorId,
    required bool added,
  }) async {
    try {
      await _analytics?.logEvent(
        name: added ? 'favorite_added' : 'favorite_removed',
        parameters: {'calculator_id': calculatorId},
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackFavorite: $e');
    }
  }

  static Future<void> trackSettingsChanged({
    required String setting,
    required String value,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'settings_changed',
        parameters: {
          'setting': setting,
          'value': value,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackSettingsChanged: $e');
    }
  }

  static Future<void> trackAiChat({String? calculatorId}) async {
    try {
      await _analytics?.logEvent(
        name: 'ai_chat',
        parameters: {
          if (calculatorId != null) 'calculator_id': calculatorId,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackAiChat: $e');
    }
  }

  static Future<void> trackReviewRequested() async {
    try {
      await _analytics?.logEvent(name: 'review_requested');
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackReviewRequested: $e');
    }
  }

  static Future<void> trackError({
    required String category,
    required String type,
    String? context,
    bool fatal = false,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'app_error',
        parameters: {
          'category': category,
          'type': type,
          if (context != null) 'context': context,
          'fatal': fatal.toString(),
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[TrackerService] trackError: $e');
    }
  }

  static Future<void> flush() async {
    // Firebase Analytics отправляет события автоматически — flush не требуется
  }

  @visibleForTesting
  static void resetState() {
    _initialized = false;
    _analytics = null;
  }
}
