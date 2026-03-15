/// Базовый класс для всех исключений приложения.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final String? userMessageKey;
  final Map<String, String> userMessageParams;
  final String? fallbackUserMessage;

  const AppException(
    this.message, {
    this.code,
    this.details,
    this.userMessageKey,
    Map<String, String>? userMessageParams,
    this.fallbackUserMessage,
  }) : userMessageParams = userMessageParams ?? const {};

  @override
  String toString() {
    final codeStr = code != null ? '[$code] ' : '';
    final detailsStr = details != null ? ' Details: $details' : '';
    return '$runtimeType: $codeStr$message$detailsStr';
  }

  /// Получить удобное для пользователя сообщение.
  String getUserMessage([String Function(String key)? translate]) {
    final template = userMessageKey != null && translate != null
        ? translate(userMessageKey!)
        : (fallbackUserMessage ?? message);
    return _applyParams(template);
  }

  String _applyParams(String template) {
    var resolved = template;
    for (final entry in userMessageParams.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', entry.value);
    }
    return resolved;
  }
}
