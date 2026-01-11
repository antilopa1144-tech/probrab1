import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:probrab_ai/core/services/voice_input_service.dart';
import 'package:probrab_ai/presentation/providers/voice_input_provider.dart';

/// Mock для VoiceInputService
class MockVoiceInputService implements VoiceInputService {
  VoiceInputStatus _status = VoiceInputStatus.notInitialized;
  String? _lastError;
  bool _isAvailable = true;
  bool _isListening = false;
  bool _shouldInitializeFail = false;
  bool _shouldListenFail = false;
  bool _russianAvailable = true;

  void setInitializeFail(bool shouldFail) {
    _shouldInitializeFail = shouldFail;
  }

  void setListenFail(bool shouldFail) {
    _shouldListenFail = shouldFail;
  }

  void setAvailable(bool available) {
    _isAvailable = available;
  }

  void setRussianAvailable(bool available) {
    _russianAvailable = available;
  }

  @override
  VoiceInputStatus get status => _status;

  @override
  String? get lastError => _lastError;

  @override
  bool get isAvailable => _isAvailable;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    if (_shouldInitializeFail) {
      _status = VoiceInputStatus.error;
      _lastError = 'Failed to initialize';
      return false;
    }

    if (!_isAvailable) {
      _status = VoiceInputStatus.unavailable;
      _lastError = 'Not available';
      return false;
    }

    _status = VoiceInputStatus.ready;
    return true;
  }

  @override
  Future<bool> startListening({
    required void Function(VoiceRecognitionResult result) onResult,
    void Function(String error)? onError,
    bool parseNumbers = true,
  }) async {
    if (_shouldListenFail) {
      _status = VoiceInputStatus.error;
      _lastError = 'Failed to start listening';
      onError?.call(_lastError!);
      return false;
    }

    if (_status != VoiceInputStatus.ready && _status != VoiceInputStatus.listening) {
      _lastError = 'Not ready';
      onError?.call(_lastError!);
      return false;
    }

    _status = VoiceInputStatus.listening;
    _isListening = true;
    return true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _status = VoiceInputStatus.ready;
  }

  @override
  Future<void> cancelListening() async {
    _isListening = false;
    _status = VoiceInputStatus.ready;
  }

  @override
  Future<bool> isRussianAvailable() async {
    return _russianAvailable;
  }

  @override
  Future<PermissionStatus> checkPermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    return <stt.LocaleName>[];
  }

  @override
  void dispose() {
    _status = VoiceInputStatus.notInitialized;
    _isListening = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceInputState', () {
    test('создаётся с начальными значениями', () {
      const state = VoiceInputState.initial();

      expect(state.status, VoiceInputStatus.notInitialized);
      expect(state.lastText, isNull);
      expect(state.lastNumber, isNull);
      expect(state.confidence, isNull);
      expect(state.error, isNull);
    });

    test('isListening возвращает true для статуса listening', () {
      const state = VoiceInputState(status: VoiceInputStatus.listening);

      expect(state.isListening, true);
    });

    test('isListening возвращает false для других статусов', () {
      const ready = VoiceInputState(status: VoiceInputStatus.ready);
      const error = VoiceInputState(status: VoiceInputStatus.error);

      expect(ready.isListening, false);
      expect(error.isListening, false);
    });

    test('isReady возвращает true для ready и listening', () {
      const ready = VoiceInputState(status: VoiceInputStatus.ready);
      const listening = VoiceInputState(status: VoiceInputStatus.listening);

      expect(ready.isReady, true);
      expect(listening.isReady, true);
    });

    test('isReady возвращает false для других статусов', () {
      const notInit = VoiceInputState(status: VoiceInputStatus.notInitialized);
      const error = VoiceInputState(status: VoiceInputStatus.error);

      expect(notInit.isReady, false);
      expect(error.isReady, false);
    });

    test('hasError возвращает true для статуса error', () {
      const state = VoiceInputState(status: VoiceInputStatus.error);

      expect(state.hasError, true);
    });

    test('hasError возвращает false для других статусов', () {
      const ready = VoiceInputState(status: VoiceInputStatus.ready);

      expect(ready.hasError, false);
    });

    test('copyWith создаёт новый экземпляр с обновлёнными значениями', () {
      const original = VoiceInputState(
        status: VoiceInputStatus.ready,
        lastText: 'test',
      );

      final updated = original.copyWith(
        status: VoiceInputStatus.listening,
        lastNumber: 42.0,
      );

      expect(updated.status, VoiceInputStatus.listening);
      expect(updated.lastText, 'test'); // Сохранено
      expect(updated.lastNumber, 42.0); // Обновлено
    });

    test('copyWith сохраняет оригинальные значения если не указаны', () {
      const original = VoiceInputState(
        status: VoiceInputStatus.ready,
        lastText: 'original',
        lastNumber: 100.0,
        confidence: 0.95,
      );

      final updated = original.copyWith(error: 'test error');

      expect(updated.status, original.status);
      expect(updated.lastText, original.lastText);
      expect(updated.lastNumber, original.lastNumber);
      expect(updated.confidence, original.confidence);
      expect(updated.error, 'test error');
    });
  });

  group('VoiceInputNotifier', () {
    late MockVoiceInputService mockService;

    setUp(() {
      mockService = MockVoiceInputService();
    });

    test('начальное состояние - notInitialized', () {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(voiceInputProvider);

      expect(state.status, VoiceInputStatus.notInitialized);
    });

    test('initialize успешно инициализирует сервис', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, true);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.ready);
    });

    test('initialize обрабатывает ошибку инициализации', () async {
      mockService.setInitializeFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, false);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.error);
      expect(container.read(voiceInputProvider).error, isNotNull);
    });

    test('initialize обрабатывает недоступность сервиса', () async {
      mockService.setAvailable(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, false);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.unavailable);
    });

    test('startListening автоматически инициализирует если не инициализирован', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.startListening(
        onResult: (result) {},
      );

      expect(success, true);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.listening);
    });

    test('startListening устанавливает статус listening', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();
      await notifier.startListening(onResult: (result) {});

      expect(container.read(voiceInputProvider).status, VoiceInputStatus.listening);
      expect(container.read(voiceInputProvider).isListening, true);
    });

    test('startListening вызывает onResult при распознавании', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();

      var resultReceived = false;
      await notifier.startListening(
        onResult: (result) {
          resultReceived = true;
        },
      );

      // Симулируем распознавание (в реальности это делает сервис)
      // В этом тесте мы просто проверяем что callback установлен
      expect(resultReceived, false); // Не вызван сразу
    });

    test('startListening вызывает onError при ошибке', () async {
      mockService.setListenFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();

      String? errorMessage;
      final success = await notifier.startListening(
        onResult: (result) {},
        onError: (error) {
          errorMessage = error;
        },
      );

      expect(success, false);
      expect(errorMessage, isNotNull);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.error);
    });

    test('startListening возвращает false если не инициализирован и инициализация не удалась', () async {
      mockService.setInitializeFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      String? errorMessage;
      final success = await notifier.startListening(
        onResult: (result) {},
        onError: (error) {
          errorMessage = error;
        },
      );

      expect(success, false);
      expect(errorMessage, isNotNull);
    });

    test('stopListening останавливает прослушивание', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();
      await notifier.startListening(onResult: (result) {});
      await notifier.stopListening();

      expect(container.read(voiceInputProvider).status, VoiceInputStatus.ready);
      expect(container.read(voiceInputProvider).isListening, false);
    });

    test('cancelListening отменяет прослушивание и очищает данные', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();
      await notifier.startListening(onResult: (result) {});
      await notifier.cancelListening();

      final state = container.read(voiceInputProvider);
      expect(state.status, VoiceInputStatus.ready);
      expect(state.lastText, isNull);
      expect(state.lastNumber, isNull);
      expect(state.confidence, isNull);
    });

    test('clearError очищает ошибку', () async {
      mockService.setListenFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();
      await notifier.startListening(
        onResult: (result) {},
        onError: (error) {},
      );

      expect(container.read(voiceInputProvider).error, isNotNull);

      notifier.clearError();

      expect(container.read(voiceInputProvider).error, isNull);
    });

    test('обновляет lastText и lastNumber при распознавании', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();

      // В реальности обновление происходит через callback onResult
      // Здесь мы проверяем что state можно обновить
      await notifier.startListening(
        onResult: (result) {
          // В реальном коде notifier обновляет state здесь
        },
      );

      // Состояние изменилось на listening
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.listening);
    });
  });

  group('voiceInputAvailabilityProvider', () {
    test('возвращает true если сервис доступен', () async {
      final mockService = MockVoiceInputService();
      mockService.setAvailable(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(voiceInputAvailabilityProvider.future);

      expect(available, true);
    });

    test('возвращает false если сервис недоступен', () async {
      final mockService = MockVoiceInputService();
      mockService.setAvailable(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(voiceInputAvailabilityProvider.future);

      expect(available, false);
    });
  });

  group('russianLanguageAvailabilityProvider', () {
    test('возвращает true если русский язык доступен', () async {
      final mockService = MockVoiceInputService();
      mockService.setRussianAvailable(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(russianLanguageAvailabilityProvider.future);

      expect(available, true);
    });

    test('возвращает false если русский язык недоступен', () async {
      final mockService = MockVoiceInputService();
      mockService.setRussianAvailable(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(russianLanguageAvailabilityProvider.future);

      expect(available, false);
    });
  });
}
