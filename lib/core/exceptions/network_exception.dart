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
    super.userMessageKey,
    super.userMessageParams,
    super.fallbackUserMessage,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      'Отсутствует подключение к интернету',
      code: 'NO_CONNECTION',
      userMessageKey: 'error.message.network_no_connection',
      fallbackUserMessage: 'Проверьте подключение к интернету',
    );
  }

  factory NetworkException.timeout(String? url) {
    return NetworkException(
      'Превышено время ожидания ответа от сервера',
      code: 'TIMEOUT',
      url: url,
      userMessageKey: 'error.message.network_timeout',
      fallbackUserMessage: 'Сервер не отвечает. Попробуйте позже',
    );
  }

  factory NetworkException.serverError(int statusCode, String? url) {
    return NetworkException(
      'Ошибка сервера (код: $statusCode)',
      code: 'SERVER_ERROR',
      statusCode: statusCode,
      url: url,
      userMessageKey: 'error.message.network_server_error',
      userMessageParams: {'statusCode': statusCode.toString()},
      fallbackUserMessage: 'Ошибка на сервере. Попробуйте позже',
    );
  }

  factory NetworkException.badRequest(int statusCode, String? url) {
    return NetworkException(
      'Неверный запрос (код: $statusCode)',
      code: 'BAD_REQUEST',
      statusCode: statusCode,
      url: url,
      userMessageKey: 'error.message.network_bad_request',
      userMessageParams: {'statusCode': statusCode.toString()},
      fallbackUserMessage: 'Неверный запрос. Обратитесь в поддержку',
    );
  }

  factory NetworkException.notFound(String? url) {
    return NetworkException(
      'Ресурс не найден',
      code: 'NOT_FOUND',
      statusCode: 404,
      url: url,
      userMessageKey: 'error.message.network_not_found',
      fallbackUserMessage: 'Запрошенные данные не найдены',
    );
  }
}
