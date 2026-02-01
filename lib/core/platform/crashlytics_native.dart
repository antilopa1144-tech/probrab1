// Нативная реализация Crashlytics (Android, iOS)
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Записывает критическую ошибку Flutter в Crashlytics.
void recordFlutterFatalError(FlutterErrorDetails details) {
  try {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  } catch (e) {
    // Игнорируем ошибки Firebase, если сервис недоступен
    debugPrint('Crashlytics error: $e');
  }
}

/// Записывает ошибку в Crashlytics.
void recordError(dynamic exception, StackTrace? stack, {String? reason}) {
  try {
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
    );
  } catch (e) {
    debugPrint('Crashlytics error: $e');
  }
}

/// Логирует сообщение в Crashlytics.
void log(String message) {
  try {
    FirebaseCrashlytics.instance.log(message);
  } catch (e) {
    debugPrint('Crashlytics log error: $e');
  }
}
