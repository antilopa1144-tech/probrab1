import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../utils/russian_number_parser.dart';

/// Результат распознавания голоса
class VoiceRecognitionResult {
  /// Распознанный текст
  final String text;

  /// Распознанное число (если удалось распарсить)
  final double? number;

  /// Уровень уверенности (0.0 - 1.0)
  final double confidence;

  /// Является ли результат финальным
  final bool isFinal;

  const VoiceRecognitionResult({
    required this.text,
    this.number,
    required this.confidence,
    required this.isFinal,
  });

  @override
  String toString() =>
      'VoiceRecognitionResult(text: $text, number: $number, confidence: $confidence, isFinal: $isFinal)';
}

/// Статус распознавания голоса
enum VoiceInputStatus {
  /// Не инициализирован
  notInitialized,

  /// Готов к использованию
  ready,

  /// Слушает
  listening,

  /// Ошибка
  error,

  /// Разрешения не предоставлены
  permissionDenied,

  /// Недоступно на устройстве
  unavailable,
}

/// Сервис для распознавания голосового ввода чисел на русском языке
class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  VoiceInputStatus _status = VoiceInputStatus.notInitialized;
  String? _lastError;

  /// Текущий статус сервиса
  VoiceInputStatus get status => _status;

  /// Последняя ошибка (если есть)
  String? get lastError => _lastError;

  /// Доступно ли распознавание речи на устройстве
  bool get isAvailable => _speech.isAvailable;

  /// Слушает ли сейчас микрофон
  bool get isListening => _speech.isListening;

  /// Проверить разрешение на использование микрофона
  Future<PermissionStatus> checkPermission() async {
    return Permission.microphone.status;
  }

  /// Запросить разрешение на использование микрофона
  Future<PermissionStatus> requestPermission() async {
    return Permission.microphone.request();
  }

  /// Инициализировать сервис распознавания
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _status = VoiceInputStatus.ready;
          } else if (status == 'listening') {
            _status = VoiceInputStatus.listening;
          }
        },
        onError: (error) {
          _lastError = error.errorMsg;
          if (error.errorMsg.contains('permission')) {
            _status = VoiceInputStatus.permissionDenied;
          } else {
            _status = VoiceInputStatus.error;
          }
        },
      );

      if (available) {
        _status = VoiceInputStatus.ready;
        return true;
      } else {
        _status = VoiceInputStatus.unavailable;
        _lastError = 'Speech recognition is not available on this device';
        return false;
      }
    } catch (e) {
      _status = VoiceInputStatus.error;
      _lastError = e.toString();
      return false;
    }
  }

  /// Начать слушать голосовой ввод
  ///
  /// [onResult] - callback для получения результатов распознавания
  /// [onError] - callback для обработки ошибок
  /// [parseNumbers] - автоматически парсить русские числительные в числа
  Future<bool> startListening({
    required void Function(VoiceRecognitionResult result) onResult,
    void Function(String error)? onError,
    bool parseNumbers = true,
  }) async {
    if (_status == VoiceInputStatus.notInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call(_lastError ?? 'Failed to initialize speech recognition');
        return false;
      }
    }

    if (_status != VoiceInputStatus.ready && _status != VoiceInputStatus.listening) {
      onError?.call(_lastError ?? 'Speech recognition is not available');
      return false;
    }

    try {
      final success = await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          double? number;

          // Парсим числа из текста, если включено
          if (parseNumbers && text.isNotEmpty) {
            number = RussianNumberParser.parseAny(text);
          }

          onResult(
            VoiceRecognitionResult(
              text: text,
              number: number,
              confidence: result.confidence,
              isFinal: result.finalResult,
            ),
          );
        },
        localeId: 'ru_RU', // Русский язык
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation, // Ждём паузы для финализации
          partialResults: true, // Показываем промежуточные результаты
          cancelOnError: false, // Не отменяем при ошибке, позволяем пользователю повторить
        ),
        listenFor: const Duration(seconds: 30), // Макс. время слушания (увеличено)
        pauseFor: const Duration(seconds: 5), // Пауза для финализации (увеличено)
      );

      if (success) {
        _status = VoiceInputStatus.listening;
        return true;
      } else {
        _status = VoiceInputStatus.error;
        _lastError = 'Failed to start listening';
        onError?.call(_lastError!);
        return false;
      }
    } catch (e) {
      _status = VoiceInputStatus.error;
      _lastError = e.toString();
      onError?.call(_lastError!);
      return false;
    }
  }

  /// Остановить слушание
  Future<void> stopListening() async {
    if (isListening) {
      await _speech.stop();
      _status = VoiceInputStatus.ready;
    }
  }

  /// Отменить слушание (без финализации результата)
  Future<void> cancelListening() async {
    if (isListening) {
      await _speech.cancel();
      _status = VoiceInputStatus.ready;
    }
  }

  /// Получить список доступных языков
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (_status == VoiceInputStatus.notInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Проверить, доступен ли русский язык
  Future<bool> isRussianAvailable() async {
    final locales = await getAvailableLocales();
    return locales.any((locale) => locale.localeId.startsWith('ru'));
  }

  /// Освободить ресурсы
  void dispose() {
    _speech.stop();
    _status = VoiceInputStatus.notInitialized;
  }
}
