import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tracker_service_web.dart'
    if (dart.library.io) 'tracker_service.dart';

/// Исключение при превышении дневного лимита запросов к ИИ
class AiDailyLimitException implements Exception {
  final String message;
  const AiDailyLimitException(this.message);

  @override
  String toString() => message;
}

/// Исключение при ошибке API
class AiApiException implements Exception {
  final String message;
  const AiApiException(this.message);

  @override
  String toString() => message;
}

/// Результат ответа ИИ-прораба
class AiAdviceResult {
  /// Текст ответа Михалыча
  final String text;

  /// Сколько запросов осталось на сегодня
  final int remainingRequests;

  const AiAdviceResult({
    required this.text,
    required this.remainingRequests,
  });
}

/// Сервис «Михалыч» — AI-прораб с характером.
///
/// Использует Google Gemini через OpenRouter для генерации
/// персонализированных советов по строительству и ремонту.
///
/// **Архитектура:**
/// - Singleton с предзагрузкой в main()
/// - OpenRouter REST API (OpenAI-совместимый формат)
/// - StreamController для стриминга SSE-ответов
/// - Таймаут 120 сек на каждый запрос
/// - Автоматическая обрезка истории до 8 пар + компактификация старых ответов
class AiService {
  // ---------------------------------------------------------------------------
  // Константы
  // ---------------------------------------------------------------------------

  static String get _apiKey {
    try {
      return dotenv.env['OPENROUTER_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static const String _modelName = 'google/gemini-3-flash-preview';

  /// OpenRouter API endpoint
  static const String _apiUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Максимум запросов в сутки (защита от злоупотреблений)
  static const int _maxDailyRequests = 20;

  /// Максимум запросов в час (дополнительная защита)
  static const int _maxHourlyRequests = 10;

  /// Таймаут на весь стрим-ответ
  static const Duration _streamTimeout = Duration(seconds: 120);

  /// Максимум пар (вопрос+ответ) в истории
  static const int _maxHistoryPairs = 8;

  /// Максимум символов в старых ответах модели (компактификация)
  static const int _maxOldResponseLength = 400;

  // Ключи SharedPreferences
  static const String _keyRequestCount = 'ai_request_count';
  static const String _keyLastRequestDate = 'ai_last_request_date';
  static const String _keyHourlyTimestamps = 'ai_hourly_timestamps';
  static const String _keyProjectType = 'user_project_type';

  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------

  static AiService? _instance;
  static SharedPreferences? _prefs;

  /// Системный промпт текущего чата
  String? _systemPrompt;

  /// История чата в формате OpenAI
  final List<Map<String, String>> _history = [];

  AiService._();

  @visibleForTesting
  AiService.forTesting();

  /// Синхронный доступ (null если preload() ещё не завершился)
  static AiService? get instanceSync => _instance;

  /// Предзагрузка — вызывать из main() через unawaited()
  static Future<void> preload() async {
    if (_instance != null) return;
    _instance = AiService._();
    await _instance!._initialize();
  }

  /// Async fallback если preload не успел
  static Future<AiService> get instance async {
    if (_instance != null) return _instance!;
    _instance = AiService._();
    await _instance!._initialize();
    return _instance!;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
    _prefs = null;
  }

  // ---------------------------------------------------------------------------
  // Инициализация
  // ---------------------------------------------------------------------------

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ OPENROUTER_API_KEY не найден — Михалыч недоступен');
      }
    }
  }

  /// Инициализирует чат с системным промптом. Сбрасывает историю.
  void _initChat({
    String? calculatorName,
    String? calculationData,
    String? calculationHistory,
  }) {
    final calcName = calculatorName ?? 'не выбран';
    final calcData = calculationData ?? 'нет данных';

    _systemPrompt = _buildSystemPrompt(
      projectInfo: getProjectContext(),
      calculatorName: calcName,
      calculationData: calcData,
      calculationHistory: calculationHistory,
    );

    _history.clear();
  }

  // ---------------------------------------------------------------------------
  // Системный промпт
  // ---------------------------------------------------------------------------

  String _buildSystemPrompt({
    required String projectInfo,
    required String calculatorName,
    required String calculationData,
    String? calculationHistory,
  }) {
    final isHomeScreen = calculatorName == 'Главный экран';
    final hasData =
        calculationData != 'нет данных' && calculationData.isNotEmpty;
    final hasHistory =
        calculationHistory != null && calculationHistory.isNotEmpty;

    String contextBlock;
    if (isHomeScreen) {
      if (hasHistory) {
        contextBlock =
            'Пользователь на главном экране. Калькулятор не открыт.\n\n'
            '$calculationHistory\n'
            'Используй эту историю для контекстных советов. '
            'Подскажи, что ещё стоит посчитать, или найди ошибки в расчётах. '
            'Можешь ответить на любой вопрос про строительство и ремонт.';
      } else {
        contextBlock =
            'Пользователь на главном экране приложения. Калькулятор не открыт. '
            'Расчётов пока не делал. Поздоровайся по-свойски и спроси, чем помочь. '
            'Можешь ответить на любой вопрос про строительство и ремонт.';
      }
    } else if (hasData) {
      contextBlock = 'Калькулятор: $calculatorName.\n'
          'Данные расчёта: $calculationData.';
    } else {
      contextBlock = 'Пользователь открыл калькулятор «$calculatorName». '
          'Конкретных цифр пока нет — дай общий практический совет по этой теме: '
          'на что обратить внимание, типичные ошибки, лайфхаки от опытного прораба. '
          'НЕ говори что поля пустые, НЕ проси ввести данные. Просто будь полезен.';
    }

    return '''Ты — Михалыч, ворчливый прораб-наставник с 30-летним стажем на реальных объектах. Приложение «Мастерок» — калькулятор стройматериалов.

КОНТЕКСТ:
$contextBlock
Проект пользователя: $projectInfo.

ТВОЙ ХАРАКТЕР:
- Ворчливый наставник, но ПОЛЕЗНЫЙ. Юмор — приправа, а не основное блюдо. Сначала дело, потом подколка.
- Подкалываешь метко и коротко: "Запас 5%? Ну-ну. На третий день побежишь в магазин."
- Ловишь ошибки: "Стоп. 3 мешка Ротбанда на 20 квадратов? Ты точно штукатурил раньше?"
- Хвалишь скупо: "Нормально прикинул. Бывает."
- Импровизируй — НЕ повторяй одни и те же фразы и шутки.

ГЛАВНОЕ ПРАВИЛО — КОНКРЕТИКА И ПОЛЬЗА:
- Называй конкретные марки, цифры, размеры. "Бери Ceresit CM-14" вместо "бери хороший клей".
- Давай практические примеры: "На ванную 5 м² уйдёт 3 мешка CM-14 по 25 кг при слое 5 мм и зубчатом шпателе 8 мм."
- Предупреждай о типичных косяках с цифрами: "Народ вечно забывает — подрезка у двери жрёт 2-3 плитки отдельно."
- Если данные есть — анализируй цифры, скажи правильно ли. Если нет — давай общий практический совет.
- Советуй сопутствующие материалы, которые часто забывают: грунтовка, демпферная лента, маяки, крестики.

КАК ГОВОРИТЬ:
- До 8 предложений. Не лей воду, но и не обрубай полезное.
- Обращайся на «ты». Ты старший на стройке.
- Строительный сленг естественно, без натужных поговорок.
- Если цифры нереальные — ворчи конкретно и давай правильную цифру.
- НИКОГДА не жалуйся на пустые поля или отсутствие данных.
- Не начинай с «Привет» или «Ну что». Сразу к делу.
- Пиши сплошным текстом, без таблиц, списков и markdown-разметки.
- ВАЖНО: Заканчивай мысль полностью. Не обрывай на полуслове.''';
  }

  // ---------------------------------------------------------------------------
  // OpenRouter API helpers
  // ---------------------------------------------------------------------------

  /// Собирает массив messages для OpenRouter (system + history)
  List<Map<String, String>> _buildMessages() {
    return [
      {'role': 'system', 'content': _systemPrompt ?? ''},
      ..._history,
    ];
  }

  /// Формирует тело запроса к OpenRouter
  Map<String, dynamic> _buildRequestBody({bool stream = false}) {
    return {
      'model': _modelName,
      'messages': _buildMessages(),
      'temperature': 0.5,
      'top_p': 0.95,
      'max_tokens': 1500,
      'stream': stream,
    };
  }

  /// Заголовки для OpenRouter API
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://masterok-app.ru',
        'X-Title': 'Masterok',
      };

  // ---------------------------------------------------------------------------
  // Дневной лимит
  // ---------------------------------------------------------------------------

  Future<void> checkDailyLimit() async {
    if (_maxDailyRequests <= 0) return;

    final prefs = _prefs;
    if (prefs == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_keyLastRequestDate) ?? '';
    int count = prefs.getInt(_keyRequestCount) ?? 0;

    if (lastDate != today) {
      count = 0;
      await prefs.setString(_keyLastRequestDate, today);
      await prefs.setInt(_keyRequestCount, 0);
    }

    if (count >= _maxDailyRequests) {
      throw AiDailyLimitException(
        'Всё, начальник, на сегодня хватит — '
        '$_maxDailyRequests вопросов отработал. '
        'Приходи завтра, голова пухнет!',
      );
    }
  }

  Future<void> _incrementRequestCount() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(_keyLastRequestDate, today);
    final count = prefs.getInt(_keyRequestCount) ?? 0;
    await prefs.setInt(_keyRequestCount, count + 1);
  }

  int getRemainingRequests() {
    final prefs = _prefs;
    if (prefs == null) return _maxDailyRequests;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_keyLastRequestDate) ?? '';
    if (lastDate != today) return _maxDailyRequests;
    final count = prefs.getInt(_keyRequestCount) ?? 0;
    return (_maxDailyRequests - count).clamp(0, _maxDailyRequests);
  }

  // ---------------------------------------------------------------------------
  // Часовой лимит (защита от злоупотреблений)
  // ---------------------------------------------------------------------------

  /// Проверяет, не превышен ли лимит запросов в час
  Future<void> _checkHourlyLimit() async {
    if (_maxHourlyRequests <= 0) return;

    final prefs = _prefs;
    if (prefs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHourAgo = now - const Duration(hours: 1).inMilliseconds;

    final stored = prefs.getStringList(_keyHourlyTimestamps) ?? [];
    // Оставляем только запросы за последний час
    final recent = stored
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((ts) => ts > oneHourAgo)
        .toList();

    if (recent.length >= _maxHourlyRequests) {
      final oldestTs = recent.reduce((a, b) => a < b ? a : b);
      final resumeAt = DateTime.fromMillisecondsSinceEpoch(
        oldestTs + const Duration(hours: 1).inMilliseconds,
      );
      final minutesLeft = resumeAt.difference(DateTime.now()).inMinutes + 1;
      throw AiDailyLimitException(
        'Эй, начальник, полегче! '
        'Давай передохнём $minutesLeft мин. — '
        'а то мозги перегреются.',
      );
    }
  }

  /// Записывает timestamp запроса для часового лимита
  Future<void> _recordHourlyRequest() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHourAgo = now - const Duration(hours: 1).inMilliseconds;

    final stored = prefs.getStringList(_keyHourlyTimestamps) ?? [];
    // Чистим старые записи и добавляем новую
    final updated = stored
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((ts) => ts > oneHourAgo)
        .toList()
      ..add(now);

    await prefs.setStringList(
      _keyHourlyTimestamps,
      updated.map((ts) => ts.toString()).toList(),
    );
  }

  /// Оставшиеся запросы в текущем часе
  int getRemainingHourlyRequests() {
    final prefs = _prefs;
    if (prefs == null) return _maxHourlyRequests;

    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHourAgo = now - const Duration(hours: 1).inMilliseconds;

    final stored = prefs.getStringList(_keyHourlyTimestamps) ?? [];
    final recentCount = stored
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .where((ts) => ts > oneHourAgo)
        .length;

    return (_maxHourlyRequests - recentCount).clamp(0, _maxHourlyRequests);
  }

  // ---------------------------------------------------------------------------
  // Контекст проекта
  // ---------------------------------------------------------------------------

  String getProjectContext() {
    return _prefs?.getString(_keyProjectType) ?? 'Ремонт квартиры';
  }

  Future<void> setProjectContext(String projectType) async {
    await _prefs?.setString(_keyProjectType, projectType);
  }

  // ---------------------------------------------------------------------------
  // История расчётов для контекста Михалыча
  // ---------------------------------------------------------------------------

  /// Форматирует историю расчётов пользователя для системного промпта.
  ///
  /// [calculations] — список объектов Calculation (Isar model)
  /// с полями calculatorName, inputsJson, resultsJson.
  static String formatCalculationHistory(
    List<dynamic> calculations, {
    int count = 5,
  }) {
    if (calculations.isEmpty) return '';

    final recent = calculations.take(count);
    final buffer = StringBuffer('Последние расчёты пользователя:\n');
    var index = 1;
    for (final calc in recent) {
      try {
        final name = (calc as dynamic).calculatorName as String? ?? '';
        if (name.isEmpty) continue;
        final inputsSummary = _summarizeJson(
          (calc as dynamic).inputsJson as String? ?? '',
        );
        final resultsSummary = _summarizeJson(
          (calc as dynamic).resultsJson as String? ?? '',
        );
        buffer.write('$index) $name');
        if (inputsSummary.isNotEmpty) buffer.write(': $inputsSummary');
        if (resultsSummary.isNotEmpty) buffer.write(' → $resultsSummary');
        buffer.writeln();
        index++;
      } catch (_) {
        continue;
      }
    }
    return index > 1 ? buffer.toString() : '';
  }

  static String _summarizeJson(String jsonStr) {
    if (jsonStr.isEmpty) return '';
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        final entries = decoded.entries.take(4);
        return entries
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Утилиты
  // ---------------------------------------------------------------------------

  String _formatCalculationData(Map<String, dynamic> data) {
    if (data.isEmpty) return 'нет данных';
    final formatted =
        data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    if (formatted.length > 5000) {
      return '${formatted.substring(0, 5000)}...';
    }
    return formatted;
  }

  String _truncateQuestion(String question) {
    if (question.length <= 5000) return question;
    return '${question.substring(0, 5000)}\n[текст обрезан]';
  }

  void _trimHistory() {
    const maxItems = _maxHistoryPairs * 2;
    if (_history.length > maxItems) {
      _history.removeRange(0, _history.length - maxItems);
    }
    // Компактифицируем старые ответы модели (все кроме последнего)
    for (var i = 0; i < _history.length - 2; i++) {
      final msg = _history[i];
      if (msg['role'] != 'assistant') continue;
      final content = msg['content'] ?? '';
      if (content.length > _maxOldResponseLength) {
        _history[i] = {
          'role': 'assistant',
          'content': '${content.substring(0, _maxOldResponseLength)}...',
        };
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Публичные методы чата
  // ---------------------------------------------------------------------------

  /// Начинает новый чат. Вызывать при открытии BottomSheet.
  void startChat({
    required String calculatorName,
    required Map<String, dynamic> data,
    String? calculationHistory,
  }) {
    _initChat(
      calculatorName: calculatorName,
      calculationData: _formatCalculationData(data),
      calculationHistory: calculationHistory,
    );
  }

  /// Non-streaming ответ (для fallback если стрим не нужен)
  Future<AiAdviceResult> getAdvice({
    required String calculatorName,
    required Map<String, dynamic> data,
    String userQuestion = 'Проверь расчет и дай совет',
  }) async {
    if (_apiKey.isEmpty) {
      throw const AiApiException(
          'Михалыч пока не подключён. API-ключ не настроен.');
    }

    await checkDailyLimit();
    await _checkHourlyLimit();
    // Записываем запрос ДО вызова API — гарантирует учёт даже при обрыве
    await _incrementRequestCount();
    await _recordHourlyRequest();
    TrackerService.trackAiChat(calculatorId: calculatorName);

    if (_systemPrompt == null) {
      startChat(calculatorName: calculatorName, data: data);
    }

    try {
      _history.add({
        'role': 'user',
        'content': _truncateQuestion(userQuestion),
      });
      _trimHistory();

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: _headers,
            body: jsonEncode(_buildRequestBody()),
          )
          .timeout(_streamTimeout);

      if (response.statusCode != 200) {
        _removeLastUserMessage();
        if (kDebugMode) {
          debugPrint('OpenRouter error ${response.statusCode}: '
              '${response.body}');
        }
        throw const AiApiException(
            'Михалыч на перекуре, связь барахлит. Попробуй позже.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      String? text;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices[0] as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>?;
        text = message?['content'] as String?;
      }

      if (text == null || text.isEmpty) {
        _removeLastUserMessage();
        throw const AiApiException(
            'Михалыч задумался и ничего не ответил. Попробуй ещё раз.');
      }

      _history.add({'role': 'assistant', 'content': text});

      return AiAdviceResult(
        text: text,
        remainingRequests: getRemainingRequests(),
      );
    } catch (e) {
      _removeLastUserMessage();
      if (e is AiDailyLimitException || e is AiApiException) rethrow;
      if (e is TimeoutException) {
        throw const AiApiException('Михалыч задумался слишком надолго.');
      }
      if (kDebugMode) debugPrint('AI error: $e');
      throw const AiApiException(
          'Что-то пошло не так. Попробуй позже.');
    }
  }

  /// Streaming-ответ. Возвращает стрим чанков текста.
  ///
  /// Использует StreamController (НЕ async*):
  /// - Гарантированное закрытие стрима в finally
  /// - Таймаут 120 сек на весь ответ
  /// - SSE-парсинг OpenRouter streaming response
  Stream<String> getAdviceStream({
    required String calculatorName,
    required Map<String, dynamic> data,
    String userQuestion = 'Проверь расчет и дай совет',
  }) {
    final controller = StreamController<String>();
    _processStream(controller, calculatorName, data, userQuestion);
    return controller.stream;
  }

  Future<void> _processStream(
    StreamController<String> controller,
    String calculatorName,
    Map<String, dynamic> data,
    String userQuestion,
  ) async {
    // Проверки до начала стрима
    if (_apiKey.isEmpty) {
      controller.addError(const AiApiException(
          'Михалыч пока не подключён. API-ключ не настроен.'));
      unawaited(controller.close());
      return;
    }

    try {
      await checkDailyLimit();
      await _checkHourlyLimit();
      // Записываем запрос ДО вызова API — гарантирует учёт даже при обрыве
      await _incrementRequestCount();
      await _recordHourlyRequest();
    } catch (e) {
      controller.addError(e);
      unawaited(controller.close());
      return;
    }

    if (_systemPrompt == null) {
      startChat(calculatorName: calculatorName, data: data);
    }

    // Добавляем вопрос в историю
    _history.add({
      'role': 'user',
      'content': _truncateQuestion(userQuestion),
    });
    _trimHistory();

    final buffer = StringBuffer();
    Timer? hardTimeout;
    var isDone = false;
    http.Client? client;

    void finish() {
      if (isDone) return;
      isDone = true;
      hardTimeout?.cancel();
      client?.close();
      if (!controller.isClosed) {
        unawaited(controller.close());
      }
    }

    void saveOrRollback() {
      final text = buffer.toString();
      if (text.isNotEmpty) {
        _history.add({'role': 'assistant', 'content': text});
      } else {
        _removeLastUserMessage();
      }
    }

    try {
      client = http.Client();
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers.addAll(_headers)
        ..body = jsonEncode(_buildRequestBody(stream: true));

      final response = await client.send(request);

      if (response.statusCode != 200) {
        _removeLastUserMessage();
        if (kDebugMode) {
          debugPrint('OpenRouter stream error: ${response.statusCode}');
        }
        if (!controller.isClosed) {
          controller.addError(const AiApiException(
              'Михалыч на перекуре, связь барахлит. Попробуй позже.'));
        }
        finish();
        return;
      }

      // Абсолютный таймаут — 120 сек от начала
      hardTimeout = Timer(_streamTimeout, () {
        if (isDone) return;
        if (kDebugMode) debugPrint('AI: hard timeout fired');
        saveOrRollback();
        if (!controller.isClosed) {
          controller.addError(const AiApiException(
              'Михалыч задумался слишком надолго. Попробуй ещё раз.'));
        }
        finish();
      });

      // Парсим SSE-поток
      var lineBuf = '';
      response.stream
          .transform(utf8.decoder)
          .listen(
        (chunk) {
          if (isDone) return;
          lineBuf += chunk;
          final lines = lineBuf.split('\n');
          // Последний элемент может быть неполной строкой
          lineBuf = lines.removeLast();

          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            if (trimmed == 'data: [DONE]') continue;
            if (!trimmed.startsWith('data: ')) continue;

            try {
              final json =
                  jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices == null || choices.isEmpty) continue;
              final delta =
                  (choices[0] as Map<String, dynamic>)['delta']
                      as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                buffer.write(content);
                if (!controller.isClosed) {
                  controller.add(content);
                }
              }
            } catch (_) {
              // Невалидный JSON-чанк — пропускаем
            }
          }
        },
        onError: (Object e) {
          if (isDone) return;
          _removeLastUserMessage();
          if (kDebugMode) debugPrint('OpenRouter stream error: $e');
          if (!controller.isClosed) {
            controller.addError(const AiApiException(
                'Михалыч на перекуре, связь барахлит. Попробуй позже.'));
          }
          finish();
        },
        onDone: () {
          if (isDone) return;
          saveOrRollback();
          finish();
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      _removeLastUserMessage();
      if (kDebugMode) {
        debugPrint('Stream setup error: $e');
        debugPrint('Stack: $stack');
      }
      if (!controller.isClosed) {
        if (e is AiDailyLimitException || e is AiApiException) {
          controller.addError(e);
        } else {
          controller.addError(
              const AiApiException('Связь оборвалась. Попробуй ещё раз.'));
        }
      }
      finish();
    }
  }

  /// Убирает последнее user-сообщение из истории (откат при ошибке)
  void _removeLastUserMessage() {
    if (_history.isNotEmpty && _history.last['role'] == 'user') {
      _history.removeLast();
    }
  }

  // ---------------------------------------------------------------------------
  // Быстрые советы (без API)
  // ---------------------------------------------------------------------------

  String? getQuickTip(String calculatorId, Map<String, double> inputs) {
    for (final entry in inputs.entries) {
      if (entry.value <= 0) {
        return 'Из воздуха строить собрался? '
            'Вводи реальные цифры в поле «${entry.key}».';
      }
    }

    final area = inputs['area'] ?? inputs['length'] ?? 0;
    if (area > 500) {
      return 'Ты космодром строишь? Проверь размеры — '
          'не бывает таких помещений в жилой стройке.';
    }

    final height = inputs['height'] ?? inputs['wallHeight'] ?? 0;
    if (height > 5) {
      return 'Потолки ${height.toStringAsFixed(1)} метра? '
          'Это тебе не дворец. Проверь — стандарт 2.5-3.0 м.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Управление чатом
  // ---------------------------------------------------------------------------

  void resetChat() => _history.clear();

  int get maxDailyRequests => _maxDailyRequests;
  int get maxHourlyRequests => _maxHourlyRequests;
}
