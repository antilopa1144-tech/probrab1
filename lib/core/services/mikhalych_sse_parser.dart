import 'dart:convert';

/// Извлекает текстовый фрагмент из SSE-строки Михалыча.
///
/// Сервер поддерживает два контракта:
/// - agent events: `{type: delta, content: ...}`;
/// - legacy OpenAI events: `{choices: [{delta: {content: ...}}]}`.
///
/// Событие `done` используется только как fallback, когда отдельные `delta`
/// не пришли. Это защищает от дублирования полного ответа в конце стрима.
String? parseMikhalychSseText(
  String line, {
  required bool hasBufferedText,
}) {
  final trimmed = line.trim();
  if (!trimmed.startsWith('data:')) return null;

  final payload = trimmed.substring('data:'.length).trimLeft();
  if (payload.isEmpty || payload == '[DONE]') return null;

  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return null;

    final eventType = decoded['type'];
    if (eventType == 'delta') {
      return _nonEmptyString(decoded['content']);
    }

    if (eventType == 'done' && !hasBufferedText) {
      final result = decoded['result'];
      if (result is Map<String, dynamic>) {
        return _nonEmptyString(result['content']);
      }
      return null;
    }

    final choices = decoded['choices'];
    if (choices is! List<dynamic> || choices.isEmpty) return null;
    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) return null;
    final delta = firstChoice['delta'];
    if (delta is! Map<String, dynamic>) return null;
    return _nonEmptyString(delta['content']);
  } on FormatException {
    return null;
  }
}

String? _nonEmptyString(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return value;
}
