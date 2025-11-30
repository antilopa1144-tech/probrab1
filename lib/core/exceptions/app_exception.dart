/// Базовый класс для всех исключений приложения.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    final codeStr = code != null ? '[$code] ' : '';
    final detailsStr = details != null ? ' Details: $details' : '';
    return '$runtimeType: $codeStr$message$detailsStr';
  }

  /// Получить удобное для пользователя сообщение
  String getUserMessage() => message;
}
