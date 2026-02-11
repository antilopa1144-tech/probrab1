import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ai_service.dart';

/// Состояние ИИ-чата с Михалычем
class AiChatState {
  /// Список сообщений в чате
  final List<AiChatMessage> messages;

  /// Загружается ли ответ
  final bool isLoading;

  /// Текст ошибки (если есть)
  final String? error;

  /// Сколько запросов осталось на сегодня
  final int remainingRequests;

  /// Тип проекта пользователя
  final String projectType;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.remainingRequests = 20,
    this.projectType = 'Ремонт квартиры',
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isLoading,
    String? error,
    int? remainingRequests,
    String? projectType,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      remainingRequests: remainingRequests ?? this.remainingRequests,
      projectType: projectType ?? this.projectType,
    );
  }
}

/// Сообщение в чате
class AiChatMessage {
  /// Текст сообщения
  final String text;

  /// true — сообщение от пользователя, false — от Михалыча
  final bool isUser;

  /// Время отправки
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// StateNotifier для управления чатом с Михалычем
class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier() : super(const AiChatState()) {
    _init();
  }

  AiService? _service;

  Future<void> _init() async {
    try {
      _service = await AiService.instance;
      state = state.copyWith(
        remainingRequests: _service!.getRemainingRequests(),
        projectType: _service!.getProjectContext(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Не удалось инициализировать Михалыча');
    }
  }

  /// Отправить данные калькулятора Михалычу и получить совет.
  ///
  /// [calculatorName] — название калькулятора.
  /// [data] — данные расчёта (входные параметры, результаты).
  /// [userQuestion] — вопрос пользователя.
  Future<void> sendMessage({
    required String calculatorName,
    required Map<String, dynamic> data,
    String userQuestion = 'Проверь расчет и дай совет',
  }) async {
    final service = _service;
    if (service == null) {
      state = state.copyWith(error: 'Михалыч ещё не готов. Подожди секунду.');
      return;
    }

    // Добавляем сообщение пользователя
    final userMessage = AiChatMessage(
      text: userQuestion,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final result = await service.getAdvice(
        calculatorName: calculatorName,
        data: data,
        userQuestion: userQuestion,
      );

      final aiMessage = AiChatMessage(
        text: result.text,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        remainingRequests: result.remainingRequests,
      );
    } on AiDailyLimitException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        remainingRequests: 0,
      );
    } on AiApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Что-то пошло не так. Попробуй позже.',
      );
    }
  }

  /// Обновить тип проекта
  Future<void> updateProjectType(String projectType) async {
    await _service?.setProjectContext(projectType);
    state = state.copyWith(projectType: projectType);
  }

  /// Очистить историю чата
  void clearChat() {
    _service?.resetChat();
    state = state.copyWith(
      messages: [],
      error: null,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Провайдер чата с Михалычем
final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier();
});
