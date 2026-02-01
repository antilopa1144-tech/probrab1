// Веб-реализация Crashlytics (заглушка)
// На вебе Crashlytics не используется, ошибки логируются в консоль

import 'package:flutter/foundation.dart';

/// На вебе просто логируем ошибку в консоль.
void recordFlutterFatalError(FlutterErrorDetails details) {
  debugPrint('Flutter Error (web): ${details.exception}');
  if (details.stack != null) {
    debugPrint('Stack trace: ${details.stack}');
  }
}

/// На вебе просто логируем ошибку в консоль.
void recordError(dynamic exception, StackTrace? stack, {String? reason}) {
  debugPrint('Error (web): $exception');
  if (reason != null) {
    debugPrint('Reason: $reason');
  }
  if (stack != null) {
    debugPrint('Stack trace: $stack');
  }
}

/// На вебе просто логируем сообщение в консоль.
void log(String message) {
  debugPrint('Log (web): $message');
}
