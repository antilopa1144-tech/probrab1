import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/ai_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // AiChatState
  // ===========================================================================

  group('AiChatState', () {
    test('has correct default values', () {
      const state = AiChatState();

      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.remainingRequests, equals(20));
      expect(state.projectType, equals('Ремонт квартиры'));
    });

    test('copyWith updates messages', () {
      const state = AiChatState();
      final messages = [
        AiChatMessage(
          text: 'test',
          isUser: true,
          timestamp: DateTime(2026),
        ),
      ];
      final updated = state.copyWith(messages: messages);

      expect(updated.messages.length, equals(1));
      expect(updated.messages.first.text, equals('test'));
      // Other fields unchanged
      expect(updated.isLoading, isFalse);
      expect(updated.remainingRequests, equals(20));
    });

    test('copyWith updates isLoading', () {
      const state = AiChatState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.messages, isEmpty);
    });

    test('copyWith updates error', () {
      const state = AiChatState();
      final updated = state.copyWith(error: 'Ошибка');

      expect(updated.error, equals('Ошибка'));
    });

    test('copyWith clears error when passing null', () {
      final state = const AiChatState().copyWith(error: 'Ошибка');
      expect(state.error, equals('Ошибка'));

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith updates remainingRequests', () {
      const state = AiChatState();
      final updated = state.copyWith(remainingRequests: 5);

      expect(updated.remainingRequests, equals(5));
    });

    test('copyWith updates projectType', () {
      const state = AiChatState();
      final updated = state.copyWith(projectType: 'Дом');

      expect(updated.projectType, equals('Дом'));
    });

    test('copyWith preserves values not specified', () {
      final state = const AiChatState().copyWith(
        isLoading: true,
        remainingRequests: 10,
        projectType: 'Баня',
      );

      final updated = state.copyWith(isLoading: false);

      expect(updated.isLoading, isFalse);
      expect(updated.remainingRequests, equals(10));
      expect(updated.projectType, equals('Баня'));
    });

    test('copyWith with all parameters', () {
      final messages = [
        AiChatMessage(
          text: 'msg',
          isUser: false,
          timestamp: DateTime(2026),
        ),
      ];

      final state = const AiChatState().copyWith(
        messages: messages,
        isLoading: true,
        error: 'err',
        remainingRequests: 3,
        projectType: 'Гараж',
      );

      expect(state.messages.length, equals(1));
      expect(state.isLoading, isTrue);
      expect(state.error, equals('err'));
      expect(state.remainingRequests, equals(3));
      expect(state.projectType, equals('Гараж'));
    });
  });

  // ===========================================================================
  // AiChatMessage
  // ===========================================================================

  group('AiChatMessage', () {
    test('stores text, isUser, and timestamp', () {
      final now = DateTime.now();
      final message = AiChatMessage(
        text: 'Привет',
        isUser: true,
        timestamp: now,
      );

      expect(message.text, equals('Привет'));
      expect(message.isUser, isTrue);
      expect(message.timestamp, equals(now));
    });

    test('creates AI message (isUser false)', () {
      final message = AiChatMessage(
        text: 'Совет Михалыча',
        isUser: false,
        timestamp: DateTime(2026, 2, 10),
      );

      expect(message.isUser, isFalse);
      expect(message.text, equals('Совет Михалыча'));
    });

    test('handles empty text', () {
      final message = AiChatMessage(
        text: '',
        isUser: true,
        timestamp: DateTime(2026),
      );

      expect(message.text, isEmpty);
    });

    test('handles multiline text', () {
      final message = AiChatMessage(
        text: 'Строка 1\nСтрока 2',
        isUser: false,
        timestamp: DateTime(2026),
      );

      expect(message.text, contains('\n'));
    });

    test('handles long text', () {
      final longText = 'А' * 5000;
      final message = AiChatMessage(
        text: longText,
        isUser: false,
        timestamp: DateTime(2026),
      );

      expect(message.text.length, equals(5000));
    });
  });

  // ===========================================================================
  // AiChatNotifier
  // ===========================================================================

  group('AiChatNotifier', () {
    test('initial state has correct defaults', () {
      final notifier = AiChatNotifier();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.remainingRequests, equals(20));
      expect(notifier.state.projectType, equals('Ремонт квартиры'));
    });

    test('clearChat resets messages and error', () {
      final notifier = AiChatNotifier();

      // Simulate having messages
      notifier.state = notifier.state.copyWith(
        messages: [
          AiChatMessage(
            text: 'test',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
        error: 'some error',
      );

      expect(notifier.state.messages, isNotEmpty);
      expect(notifier.state.error, isNotNull);

      notifier.clearChat();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.error, isNull);
    });

    test('clearError clears only error', () {
      final notifier = AiChatNotifier();

      notifier.state = notifier.state.copyWith(
        error: 'some error',
        remainingRequests: 5,
      );

      notifier.clearError();

      expect(notifier.state.error, isNull);
      expect(notifier.state.remainingRequests, equals(5));
    });

    test('clearError is safe when no error exists', () {
      final notifier = AiChatNotifier();

      expect(notifier.state.error, isNull);
      notifier.clearError();
      expect(notifier.state.error, isNull);
    });

    test('clearChat preserves remainingRequests', () {
      final notifier = AiChatNotifier();

      notifier.state = notifier.state.copyWith(
        remainingRequests: 7,
        messages: [
          AiChatMessage(
            text: 'msg',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      notifier.clearChat();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.remainingRequests, equals(7));
    });

    test('clearChat preserves projectType', () {
      final notifier = AiChatNotifier();

      notifier.state = notifier.state.copyWith(
        projectType: 'Дача',
        messages: [
          AiChatMessage(
            text: 'msg',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
      );

      notifier.clearChat();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.projectType, equals('Дача'));
    });
  });
}
