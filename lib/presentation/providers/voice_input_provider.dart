import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/voice_input_service.dart';

/// Состояние голосового ввода
class VoiceInputState {
  /// Статус сервиса
  final VoiceInputStatus status;

  /// Последний распознанный текст
  final String? lastText;

  /// Последнее распознанное число
  final double? lastNumber;

  /// Уровень уверенности (0.0 - 1.0)
  final double? confidence;

  /// Последняя ошибка
  final String? error;

  const VoiceInputState({
    required this.status,
    this.lastText,
    this.lastNumber,
    this.confidence,
    this.error,
  });

  const VoiceInputState.initial()
      : status = VoiceInputStatus.notInitialized,
        lastText = null,
        lastNumber = null,
        confidence = null,
        error = null;

  /// Слушает ли сейчас
  bool get isListening => status == VoiceInputStatus.listening;

  /// Готов к использованию
  bool get isReady => status == VoiceInputStatus.ready || isListening;

  /// Есть ошибка
  bool get hasError => status == VoiceInputStatus.error;

  VoiceInputState copyWith({
    VoiceInputStatus? status,
    String? lastText,
    double? lastNumber,
    double? confidence,
    String? error,
  }) {
    return VoiceInputState(
      status: status ?? this.status,
      lastText: lastText ?? this.lastText,
      lastNumber: lastNumber ?? this.lastNumber,
      confidence: confidence ?? this.confidence,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier для управления голосовым вводом
class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final VoiceInputService _service;

  VoiceInputNotifier(this._service) : super(const VoiceInputState.initial());

  /// Инициализировать сервис
  Future<bool> initialize() async {
    final success = await _service.initialize();

    if (success) {
      state = state.copyWith(status: VoiceInputStatus.ready);
    } else {
      state = state.copyWith(
        status: _service.status,
        error: _service.lastError,
      );
    }

    return success;
  }

  /// Начать прослушивание
  Future<bool> startListening({
    required void Function(VoiceRecognitionResult result) onResult,
    void Function(String error)? onError,
  }) async {
    // Инициализируем, если ещё не инициализирован
    if (state.status == VoiceInputStatus.notInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call(state.error ?? 'Failed to initialize');
        return false;
      }
    }

    state = state.copyWith(status: VoiceInputStatus.listening);

    final success = await _service.startListening(
      onResult: (result) {
        state = state.copyWith(
          lastText: result.text,
          lastNumber: result.number,
          confidence: result.confidence,
        );
        onResult(result);
      },
      onError: (error) {
        state = state.copyWith(
          status: VoiceInputStatus.error,
          error: error,
        );
        onError?.call(error);
      },
      parseNumbers: true,
    );

    if (!success) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        error: _service.lastError,
      );
      onError?.call(_service.lastError ?? 'Failed to start listening');
    }

    return success;
  }

  /// Остановить прослушивание
  Future<void> stopListening() async {
    await _service.stopListening();
    state = state.copyWith(status: VoiceInputStatus.ready);
  }

  /// Отменить прослушивание
  Future<void> cancelListening() async {
    await _service.cancelListening();
    state = state.copyWith(
      status: VoiceInputStatus.ready,
      lastText: null,
      lastNumber: null,
      confidence: null,
    );
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider для VoiceInputService (singleton)
final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});

/// Provider для VoiceInputNotifier
final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  final service = ref.watch(voiceInputServiceProvider);
  return VoiceInputNotifier(service);
});

/// Provider для проверки доступности голосового ввода
final voiceInputAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(voiceInputServiceProvider);
  await service.initialize();
  return service.isAvailable;
});

/// Provider для проверки доступности русского языка
final russianLanguageAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(voiceInputServiceProvider);
  return service.isRussianAvailable();
});
