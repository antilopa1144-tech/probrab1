// Веб-заглушка для TrackerService
// MyTracker SDK не поддерживается на вебе

import 'package:flutter/foundation.dart';

/// Веб-заглушка для TrackerService.
class TrackerService {
  static Future<void> initialize(String sdkKey) async {}

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
  static void resetState() {}
}
