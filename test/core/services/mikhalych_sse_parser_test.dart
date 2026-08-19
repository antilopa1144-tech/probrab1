import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/mikhalych_sse_parser.dart';

void main() {
  group('parseMikhalychSseText', () {
    test('читает delta нового agent SSE-контракта', () {
      expect(
        parseMikhalychSseText(
          'data: {"type":"delta","content":"Работает"}',
          hasBufferedText: false,
        ),
        'Работает',
      );
    });

    test('использует done как fallback, если delta не пришли', () {
      expect(
        parseMikhalychSseText(
          'data: {"type":"done","result":{"content":"Готово"}}',
          hasBufferedText: false,
        ),
        'Готово',
      );
    });

    test('не дублирует done после уже полученных delta', () {
      expect(
        parseMikhalychSseText(
          'data: {"type":"done","result":{"content":"Работает"}}',
          hasBufferedText: true,
        ),
        isNull,
      );
    });

    test('сохраняет поддержку legacy OpenAI SSE', () {
      expect(
        parseMikhalychSseText(
          'data: {"choices":[{"delta":{"content":"Старый формат"}}]}',
          hasBufferedText: false,
        ),
        'Старый формат',
      );
    });

    test('игнорирует status, DONE и повреждённый JSON', () {
      expect(
        parseMikhalychSseText(
          'data: {"type":"status","message":"Думаю…"}',
          hasBufferedText: false,
        ),
        isNull,
      );
      expect(
        parseMikhalychSseText(
          'data: [DONE]',
          hasBufferedText: false,
        ),
        isNull,
      );
      expect(
        parseMikhalychSseText(
          'data: {broken',
          hasBufferedText: false,
        ),
        isNull,
      );
    });
  });
}
