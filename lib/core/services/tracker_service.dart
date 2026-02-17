// Заглушка TrackerService
// TODO: вернуть реальную реализацию после фикса mytracker_sdk namespace для AGP 8+
// Реальная реализация сохранена в tracker_service.dart.bak

import 'package:flutter/foundation.dart';

/// Заглушка TrackerService (mytracker_sdk несовместим с AGP 8+).
class TrackerService {
  static bool _initialized = false;

  static Future<void> initialize(String sdkKey) async {
    if (_initialized || sdkKey.isEmpty) return;
    _initialized = true;
    debugPrint('[TrackerService] Stub initialized (mytracker_sdk disabled)');
  }

  static Future<void> trackEvent(
    String name, [
    Map<String, String>? params,
  ]) async {}

  static Future<void> trackCalculatorUsed({
    required String calculatorId,
    required String category,
    String? subcategory,
  }) async {}

  static Future<void> trackCalculatorOpened(String calculatorId) async {}

  static Future<void> trackScreenView(String screenName) async {}

  static Future<void> trackExport({
    required String type,
    required String calculatorId,
  }) async {}

  static Future<void> trackFavorite({
    required String calculatorId,
    required bool added,
  }) async {}

  static Future<void> trackSettingsChanged({
    required String setting,
    required String value,
  }) async {}

  static Future<void> trackAiChat({String? calculatorId}) async {}

  static Future<void> trackReviewRequested() async {}

  static Future<void> trackError({
    required String category,
    required String type,
    String? context,
    bool fatal = false,
  }) async {}

  static Future<void> flush() async {}

  @visibleForTesting
  static void resetState() {
    _initialized = false;
  }
}
