import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/services/voice_input_service.dart';
import 'package:probrab_ai/presentation/providers/voice_input_provider.dart';

/// Mock VoiceInputService для тестирования
class MockVoiceInputService implements VoiceInputService {
  VoiceInputStatus _status = VoiceInputStatus.notInitialized;
  String? _lastError;
  bool _isAvailable = true;
  bool _isListening = false;
  bool _shouldInitialize = true;
  bool _shouldStartListening = true;
  bool _shouldFail = false;
  List<String> _availableLocales = ['ru_RU', 'en_US'];

  void setStatus(VoiceInputStatus status) {
    _status = status;
  }

  void setLastError(String? error) {
    _lastError = error;
  }

  void setIsAvailable(bool available) {
    _isAvailable = available;
  }

  void setShouldInitialize(bool shouldInit) {
    _shouldInitialize = shouldInit;
  }

  void setShouldStartListening(bool shouldStart) {
    _shouldStartListening = shouldStart;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  void setAvailableLocales(List<String> locales) {
    _availableLocales = locales;
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
    if (_shouldFail) {
      _status = VoiceInputStatus.error;
      _lastError = 'Initialization failed';
      return false;
    }

    if (_shouldInitialize) {
      _status = VoiceInputStatus.ready;
      return true;
    }
    _status = VoiceInputStatus.unavailable;
    _lastError = 'Not available';
    return false;
  }

  @override
  Future<bool> startListening({
    required void Function(VoiceRecognitionResult) onResult,
    void Function(String)? onError,
    bool parseNumbers = true,
  }) async {
    if (_status == VoiceInputStatus.notInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call(_lastError ?? 'Failed to initialize');
        return false;
      }
    }

    if (_shouldFail) {
      _status = VoiceInputStatus.error;
      _lastError = 'Failed to start listening';
      onError?.call(_lastError!);
      return false;
    }

    if (_shouldStartListening) {
      _isListening = true;
      _status = VoiceInputStatus.listening;

      // Симулируем распознавание
      Future.delayed(const Duration(milliseconds: 100), () {
        onResult(const VoiceRecognitionResult(
          text: 'три с половиной',
          number: 3.5,
          confidence: 0.95,
          isFinal: false,
        ));
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        onResult(const VoiceRecognitionResult(
          text: 'три с половиной метра',
          number: 3.5,
          confidence: 0.98,
          isFinal: true,
        ));
      });

      return true;
    }

    _status = VoiceInputStatus.error;
    _lastError = 'Failed to start';
    onError?.call(_lastError!);
    return false;
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
    return _availableLocales.any((locale) => locale.startsWith('ru'));
  }

  @override
  void dispose() {
    _status = VoiceInputStatus.notInitialized;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockVoiceInputService mockService;

  setUp(() {
    mockService = MockVoiceInputService();
  });

  group('VoiceInputState', () {
    test('initial состояние корректно', () {
      const state = VoiceInputState.initial();

      expect(state.status, VoiceInputStatus.notInitialized);
      expect(state.lastText, isNull);
      expect(state.lastNumber, isNull);
      expect(state.confidence, isNull);
      expect(state.error, isNull);
      expect(state.isListening, false);
      expect(state.isReady, false);
      expect(state.hasError, false);
    });

    test('copyWith обновляет только указанные поля', () {
      const state = VoiceInputState(
        status: VoiceInputStatus.ready,
        lastText: 'test',
        lastNumber: 5.0,
      );

      final updated = state.copyWith(
        status: VoiceInputStatus.listening,
        lastNumber: 10.0,
      );

      expect(updated.status, VoiceInputStatus.listening);
      expect(updated.lastText, 'test'); // Не изменилось
      expect(updated.lastNumber, 10.0);
    });

    test('isListening возвращает true при статусе listening', () {
      const state = VoiceInputState(status: VoiceInputStatus.listening);
      expect(state.isListening, true);
    });

    test('isReady возвращает true для ready и listening', () {
      const readyState = VoiceInputState(status: VoiceInputStatus.ready);
      const listeningState = VoiceInputState(status: VoiceInputStatus.listening);

      expect(readyState.isReady, true);
      expect(listeningState.isReady, true);
    });

    test('hasError возвращает true при статусе error', () {
      const state = VoiceInputState(status: VoiceInputStatus.error);
      expect(state.hasError, true);
    });
  });

  group('VoiceInputNotifier - инициализация', () {
    test('начальное состояние - notInitialized', () {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(voiceInputProvider);

      expect(state.status, VoiceInputStatus.notInitialized);
    });

    test('initialize успешная инициализация', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, true);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.ready);
    });

    test('initialize неудачная инициализация', () async {
      mockService.setShouldInitialize(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, false);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.unavailable);
    });

    test('initialize с ошибкой', () async {
      mockService.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final success = await notifier.initialize();

      expect(success, false);
      final state = container.read(voiceInputProvider);
      expect(state.status, VoiceInputStatus.error);
      expect(state.error, isNotNull);
    });
  });

  group('VoiceInputNotifier - прослушивание', () {
    test('startListening успешный запуск', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final results = <VoiceRecognitionResult>[];
      final success = await notifier.startListening(
        onResult: (result) => results.add(result),
      );

      expect(success, true);
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.listening);

      // Ждём результаты
      await Future.delayed(const Duration(milliseconds: 300));

      expect(results, isNotEmpty);
      expect(results.any((r) => r.number == 3.5), true);
    });

    test('startListening автоинициализация если не инициализирован', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      // Не инициализируем вручную
      final success = await notifier.startListening(
        onResult: (result) {},
      );

      expect(success, true);
      // Должен автоматически инициализироваться
      expect(container.read(voiceInputProvider).status, VoiceInputStatus.listening);
    });

    test('startListening неудача при инициализации', () async {
      mockService.setShouldInitialize(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final errors = <String>[];
      final success = await notifier.startListening(
        onResult: (result) {},
        onError: (error) => errors.add(error),
      );

      expect(success, false);
      expect(errors, isNotEmpty);
    });

    test('startListening обновляет state с результатами', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.startListening(onResult: (result) {});

      await Future.delayed(const Duration(milliseconds: 150));

      final state = container.read(voiceInputProvider);
      expect(state.lastText, isNotNull);
      expect(state.lastNumber, 3.5);
      expect(state.confidence, greaterThan(0.9));
    });

    test('startListening вызывает onError при ошибке', () async {
      mockService.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      // Сначала инициализируем, чтобы не упасть на инициализации
      mockService.setShouldFail(false);
      await notifier.initialize();
      mockService.setShouldFail(true);

      final errors = <String>[];
      final success = await notifier.startListening(
        onResult: (result) {},
        onError: (error) => errors.add(error),
      );

      expect(success, false);
      expect(errors, isNotEmpty);
      final state = container.read(voiceInputProvider);
      expect(state.status, VoiceInputStatus.error);
    });
  });

  group('VoiceInputNotifier - остановка', () {
    test('stopListening останавливает прослушивание', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.startListening(onResult: (result) {});

      await notifier.stopListening();

      final state = container.read(voiceInputProvider);
      expect(state.status, VoiceInputStatus.ready);
      expect(state.isListening, false);
    });

    test('cancelListening отменяет и очищает результаты', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.startListening(onResult: (result) {});
      await Future.delayed(const Duration(milliseconds: 150));

      await notifier.cancelListening();

      final state = container.read(voiceInputProvider);
      expect(state.status, VoiceInputStatus.ready);
      expect(state.lastText, isNull);
      expect(state.lastNumber, isNull);
      expect(state.confidence, isNull);
    });
  });

  group('VoiceInputNotifier - очистка ошибки', () {
    test('clearError очищает ошибку', () async {
      mockService.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      await notifier.initialize();

      expect(container.read(voiceInputProvider).error, isNotNull);

      notifier.clearError();

      expect(container.read(voiceInputProvider).error, isNull);
    });
  });

  group('voiceInputAvailabilityProvider', () {
    test('возвращает true когда доступен', () async {
      mockService.setIsAvailable(true);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(voiceInputAvailabilityProvider.future);

      expect(available, true);
    });

    test('возвращает false когда недоступен', () async {
      mockService.setIsAvailable(false);
      mockService.setShouldInitialize(false);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(voiceInputAvailabilityProvider.future);

      expect(available, false);
    });
  });

  group('russianLanguageAvailabilityProvider', () {
    test('возвращает true когда русский доступен', () async {
      mockService.setAvailableLocales(['ru_RU', 'en_US']);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(russianLanguageAvailabilityProvider.future);

      expect(available, true);
    });

    test('возвращает false когда русский недоступен', () async {
      mockService.setAvailableLocales(['en_US', 'de_DE']);

      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final available = await container.read(russianLanguageAvailabilityProvider.future);

      expect(available, false);
    });
  });

  group('VoiceRecognitionResult', () {
    test('toString возвращает корректное представление', () {
      const result = VoiceRecognitionResult(
        text: 'пять метров',
        number: 5.0,
        confidence: 0.95,
        isFinal: true,
      );

      final str = result.toString();

      expect(str, contains('пять метров'));
      expect(str, contains('5.0'));
      expect(str, contains('0.95'));
      expect(str, contains('true'));
    });
  });

  group('VoiceInputStatus - все статусы', () {
    test('проверка всех статусов', () {
      expect(VoiceInputStatus.notInitialized, isNotNull);
      expect(VoiceInputStatus.ready, isNotNull);
      expect(VoiceInputStatus.listening, isNotNull);
      expect(VoiceInputStatus.error, isNotNull);
      expect(VoiceInputStatus.permissionDenied, isNotNull);
      expect(VoiceInputStatus.unavailable, isNotNull);
    });
  });

  group('VoiceInputNotifier - разные сценарии', () {
    test('промежуточные и финальные результаты', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final results = <VoiceRecognitionResult>[];
      await notifier.startListening(
        onResult: (result) => results.add(result),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      expect(results.any((r) => r.isFinal == false), true);
      expect(results.any((r) => r.isFinal == true), true);
    });

    test('высокий уровень уверенности', () async {
      final container = ProviderContainer(
        overrides: [
          voiceInputServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(voiceInputProvider.notifier);

      final results = <VoiceRecognitionResult>[];
      await notifier.startListening(
        onResult: (result) => results.add(result),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      expect(results.any((r) => r.confidence > 0.9), true);
    });
  });
}
