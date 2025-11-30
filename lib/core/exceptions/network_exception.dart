import 'app_exception.dart';

/// Исключение при работе с сетью.
class NetworkException extends AppException {
  final int? statusCode;
  final String? url;

  const NetworkException(
    super.message, {
    super.code,
    this.statusCode,
    this.url,
    super.details,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      'Отсутствует подключение к интернету',
      code: 'NO_CONNECTION',
    );
  }

  factory NetworkException.timeout(String? url) {
    return NetworkException(
      'Превышено время ожидания ответа от сервера',
      code: 'TIMEOUT',
      url: url,
    );
  }

  factory NetworkException.serverError(int statusCode, String? url) {
    return NetworkException(
      'Ошибка сервера (код: $statusCode)',
      code: 'SERVER_ERROR',
      statusCode: statusCode,
      url: url,
    );
  }

  factory NetworkException.badRequest(int statusCode, String? url) {
    return NetworkException(
      'Неверный запрос (код: $statusCode)',
      code: 'BAD_REQUEST',
      statusCode: statusCode,
      url: url,
    );
  }

  factory NetworkException.notFound(String? url) {
    return NetworkException(
      'Ресурс не найден',
      code: 'NOT_FOUND',
      statusCode: 404,
      url: url,
    );
  }

  @override
  String getUserMessage() {
    switch (code) {
      case 'NO_CONNECTION':
        return 'Проверьте подключение к интернету';
      case 'TIMEOUT':
        return 'Сервер не отвечает. Попробуйте позже';
      case 'SERVER_ERROR':
        return 'Ошибка на сервере. Попробуйте позже';
      case 'BAD_REQUEST':
        return 'Неверный запрос. Обратитесь в поддержку';
      case 'NOT_FOUND':
        return 'Запрошенные данные не найдены';
      default:
        return 'Ошибка сети. Проверьте подключение';
    }
  }
}
