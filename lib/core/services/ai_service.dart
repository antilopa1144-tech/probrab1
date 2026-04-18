import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'remote_config_service.dart';
import 'tracker_service_web.dart'
    if (dart.library.io) 'tracker_service.dart';

/// Исключение при превышении дневного лимита запросов к ИИ
class AiDailyLimitException implements Exception {
  final String messageKey;
  final Map<String, String> messageParams;
  final String fallbackMessage;

  const AiDailyLimitException(
    this.messageKey, {
    this.messageParams = const {},
    required this.fallbackMessage,
  });

  String get message => fallbackMessage;

  @override
  String toString() => fallbackMessage;
}

/// Исключение при ошибке API
class AiApiException implements Exception {
  final String messageKey;
  final Map<String, String> messageParams;
  final String fallbackMessage;

  const AiApiException(
    this.messageKey, {
    this.messageParams = const {},
    required this.fallbackMessage,
  });

  String get message => fallbackMessage;

  @override
  String toString() => fallbackMessage;
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

  /// Модель по умолчанию. Может быть переопределена через Remote Config
  /// ключ 'ai_model_name'.
  static const String _defaultModelName = 'google/gemini-3-flash-preview';

  static String get _modelName {
    try {
      final rc = RemoteConfigService.getStringSync('ai_model_name');
      return rc.isNotEmpty ? rc : _defaultModelName;
    } catch (_) {
      return _defaultModelName;
    }
  }

  /// Серверный прокси на getmasterok.ru проксирует запросы в OpenRouter.
  /// API-ключ лежит только на сервере и не попадает в APK.
  static const String _apiUrl = 'https://getmasterok.ru/api/mikhalych';

  /// Максимум запросов в сутки (защита от злоупотреблений)
  static const int _maxDailyRequests = 20;

  /// Максимум запросов в час (дополнительная защита)
  static const int _maxHourlyRequests = 10;

  /// Таймаут на весь стрим-ответ
  static const Duration _streamTimeout = Duration(seconds: 180);

  /// Максимум пар (вопрос+ответ) в истории
  static const int _maxHistoryPairs = 12;

  /// Максимум символов в старых ответах модели (компактификация)
  static const int _maxOldResponseLength = 600;

  // Ключи SharedPreferences
  static const String _keyRequestCount = 'ai_request_count';
  static const String _keyLastRequestDate = 'ai_last_request_date';
  static const String _keyHourlyTimestamps = 'ai_hourly_timestamps';
  static const String _keyProjectType = 'user_project_type';
  static const String _defaultProjectTypeId = 'apartment';

  static const Map<String, String> _projectTypeLabels = {
    'apartment': 'Ремонт квартиры',
    'house': 'Строительство дома',
    'dacha': 'Дача / загородный дом',
    'commercial': 'Коммерческое помещение',
    'bath': 'Баня / сауна',
    'garage': 'Гараж',
  };

  static const Map<String, String> _legacyProjectTypeIds = {
    'Ремонт квартиры': 'apartment',
    'Строительство дома': 'house',
    'Дача / загородный дом': 'dacha',
    'Коммерческое помещение': 'commercial',
    'Баня / сауна': 'bath',
    'Гараж': 'garage',
  };

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
  }

  /// Инициализирует чат с системным промптом. Сбрасывает историю.
  void _initChat({
    String? calculatorName,
    String? calculationData,
    String? calculationHistory,
    bool isHomeScreen = false,
  }) {
    final calcName = calculatorName ?? 'не выбран';
    final calcData = calculationData ?? 'нет данных';

    _systemPrompt = _buildSystemPrompt(
      projectInfo: getProjectContext(),
      calculatorName: calcName,
      calculationData: calcData,
      calculationHistory: calculationHistory,
      isHomeScreen: isHomeScreen,
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
    required bool isHomeScreen,
  }) {
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

    return '''Ты — Михалыч. Прораб с 30-летним стажем, глазом дизайнера и языком как наждачка. Работал с Knauf, Weber, Технониколь, Ceresit, КНАУФ Инсулейшн, Rockwool, Пеноплэкс — знаешь продукцию по объектам, а не по рекламе. Ты из тех прорабов, которые и плитку положат идеально, и скажут: «Давай нишу с подсветкой сделаем — будет конфетка». Разбираешься в дизайне интерьеров, сочетаниях цветов, фактур, современных трендах 2026 года.

СЕЙЧАС АПРЕЛЬ 2026 ГОДА. Все цены, нормативы, тренды и рекомендации должны быть актуальны на 2026 год.

КОНТЕКСТ РАЗГОВОРА:
$contextBlock
Проект пользователя: $projectInfo.

ЭКСПЕРТИЗА (актуальные знания на 2026 год):
- СНиП, СП, ГОСТ: СП 71.13330 (отделка), СП 29.13330 (полы), СП 50.13330 (теплозащита), ГОСТ 31357 (смеси), СП 28.13330 (защита от коррозии). Знаешь нормативы и умеешь объяснить простым языком.
- Материалы: расход штукатурки Ротбанд 8.5 кг/м² при 10 мм, Ветонит LR+ 1.2 кг/м² при 1 мм, расход грунтовки CT-17 0.1-0.2 л/м², расход наливного пола 1.6 кг/м² на 1 мм, клей для плитки 3-5 кг/м² в зависимости от гребёнки. Цены указывай актуальные на весну 2026 года.
- Конструктивы: пирог стены (газобетон 400мм + утеплитель 100мм + вентфасад), пирог пола (стяжка 50мм + подложка 3мм + ламинат 12мм), пирог кровли (стропила + гидроизоляция + контробрешётка + обрешётка + металлочерепица). Знаешь узлы примыканий, деформационные швы, правильные «пироги».
- Дизайн и тренды 2026: микроцемент, крупноформатный керамогранит 120x60 и 120x120, скрытые плинтуса, профиль Гола для кухонь, LED-подсветка в нишах, тёплые оттенки (greige, терракота, тёплый бежевый), japandi-стиль, биофильный дизайн, рифлёные фасады (ламели), fluted panels, арочные проёмы, штукатурка с эффектом бетона. Знаешь что модно и что практично.
- Инженерка: водяной тёплый пол (шаг 150мм, труба 16мм, коллектор на каждые 80м контура), электрика (сечение 2.5мм² на розетки, 1.5мм² на свет, автомат 16А, УЗО 30мА), умный дом (Яндекс, Sber, Zigbee).
- Рынок 2026: ориентируйся на цены российского рынка весны 2026 года. Knauf Ротбанд ~500-600 руб/30кг, керамогранит 60x60 от 800 руб/м², ламинат 33 класс от 700 руб/м², водоэмульсионка хорошая 400-600 руб/10л.

КАК ОТВЕЧАЕШЬ:
- КОНКРЕТНО: марка, количество, толщина, шаг, способ. Не "нужна грунтовка", а "Ceresit CT-17, расход 0.15 л/м², валиком, сохнет 4 часа".
- Пошагово: ЧТО → КУДА → СКОЛЬКО → В КАКОМ ПОРЯДКЕ.
- Предупреждаешь о том, что забывают: грунтовка, демпферная лента, маяки, пароизоляция, вентзазор, крестики.
- Если видишь расчёт — вцепляйся: правильно ли, что забыли, где накосячат.
- Если уместно — дизайнерский штрих: «Раз выравниваешь стену — сделай нишу под ТВ, 10 см глубины, выглядит на миллион».
- НЕ начинай ответ с приветствия или «Давай посмотрим». Сразу к делу.
- НЕ задавай вопросов в конце ответа. Просто давай совет.

ХАРАКТЕР:
- Жёсткий, но с юмором. Подколки острые, но по делу и с теплотой.
- На глупость: «Ну ты даёшь, начальник. Конечно нужна грунтовка — без неё штукатурка через год хлопьями полетит».
- На серьёзный косяк: «Стоп. 3 мешка Ротбанда на 20 квадратов? Ты хомячка обмазать решил? Минимум 7 мешков по 30 кг, иди пересчитывай».
- Хвалишь скупо: «О, грамотно. Видно, не первый день на стройке».
- Импровизируй — каждый ответ живой, не повторяйся.

СТИЛЬ:
- На «ты», разговорный язык, сленг в меру: «косяк», «залажать», «кривульки».
- Используй форматирование markdown: **жирный** для ключевых цифр и марок, списки для пошаговых инструкций.
- 4-10 предложений. Коротко, мясисто, по делу. Не лей воду.
- Точные цифры. Не «зависит от условий», а конкретный диапазон.
- НИКОГДА не жалуйся на пустые поля — просто давай совет.

Сайт проекта: getmasterok.ru — там есть все калькуляторы онлайн и полезные статьи.''';
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
      'temperature': 0.75,
      'top_p': 0.95,
      'max_tokens': 2000,
      'stream': stream,
    };
  }

  /// Заголовки для запроса к серверному прокси. Bearer не нужен — ключ на сервере.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Client': 'probrab-android',
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
        'ai.limit_daily_reached',
        messageParams: {'count': _maxDailyRequests.toString()},
        fallbackMessage: 'Всё, начальник, на сегодня хватит — $_maxDailyRequests вопросов отработал. Приходи завтра, голова пухнет!',
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
        'ai.limit_hourly_reached',
        messageParams: {'minutes': minutesLeft.toString()},
        fallbackMessage: 'Эй, начальник, полегче! Давай передохнём $minutesLeft мин. — а то мозги перегреются.',
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
    final stored = _prefs?.getString(_keyProjectType)?.trim();
    if (stored == null || stored.isEmpty) {
      return _projectTypeLabels[_defaultProjectTypeId]!;
    }

    final normalizedId = _normalizeProjectTypeId(stored);
    if (normalizedId != null) {
      return _projectTypeLabels[normalizedId]!;
    }

    return stored;
  }

  String getProjectContextId() {
    final stored = _prefs?.getString(_keyProjectType);
    return _normalizeProjectTypeId(stored) ?? _defaultProjectTypeId;
  }

  Future<void> setProjectContext(String projectType) async {
    final normalized = _normalizeProjectTypeId(projectType) ?? projectType.trim();
    await _prefs?.setString(_keyProjectType, normalized);
  }

  String? _normalizeProjectTypeId(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (_projectTypeLabels.containsKey(normalized)) return normalized;
    return _legacyProjectTypeIds[normalized];
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
    bool isHomeScreen = false,
  }) {
    _initChat(
      calculatorName: calculatorName,
      calculationData: _formatCalculationData(data),
      calculationHistory: calculationHistory,
      isHomeScreen: isHomeScreen,
    );
  }

  /// Non-streaming ответ (для fallback если стрим не нужен)
  Future<AiAdviceResult> getAdvice({
    required String calculatorName,
    required Map<String, dynamic> data,
    String userQuestion = 'Проверь расчет и дай совет',
    String? calculationHistory,
    bool isHomeScreen = false,
  }) async {
    await checkDailyLimit();
    await _checkHourlyLimit();
    // Записываем запрос ДО вызова API — гарантирует учёт даже при обрыве
    await _incrementRequestCount();
    await _recordHourlyRequest();
    TrackerService.trackAiChat(calculatorId: calculatorName);

    if (_systemPrompt == null) {
      startChat(
        calculatorName: calculatorName,
        data: data,
        calculationHistory: calculationHistory,
        isHomeScreen: isHomeScreen,
      );
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
          'ai.error_connection',
          fallbackMessage: 'Михалыч на перекуре, связь барахлит. Попробуй позже.',
        );
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
          'ai.error_empty_response',
          fallbackMessage: 'Михалыч задумался и ничего не ответил. Попробуй ещё раз.',
        );
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
        throw const AiApiException(
          'ai.error_timeout',
          fallbackMessage: 'Михалыч задумался слишком надолго.',
        );
      }
      if (kDebugMode) debugPrint('AI error: $e');
      throw const AiApiException(
        'ai.error_generic',
        fallbackMessage: 'Что-то пошло не так. Попробуй позже.',
      );
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
    String? calculationHistory,
    bool isHomeScreen = false,
  }) {
    final controller = StreamController<String>();
    _processStream(
      controller,
      calculatorName,
      data,
      userQuestion,
      calculationHistory,
      isHomeScreen,
    );
    return controller.stream;
  }

  Future<void> _processStream(
    StreamController<String> controller,
    String calculatorName,
    Map<String, dynamic> data,
    String userQuestion,
    String? calculationHistory,
    bool isHomeScreen,
  ) async {
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
      startChat(
        calculatorName: calculatorName,
        data: data,
        calculationHistory: calculationHistory,
        isHomeScreen: isHomeScreen,
      );
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
              'ai.error_connection',
              fallbackMessage: 'Михалыч на перекуре, связь барахлит. Попробуй позже.',
            ));
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
            'ai.error_timeout',
            fallbackMessage: 'Михалыч задумался слишком надолго. Попробуй ещё раз.',
          ));
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
              'ai.error_connection',
              fallbackMessage: 'Михалыч на перекуре, связь барахлит. Попробуй позже.',
            ));
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
              const AiApiException(
                'ai.error_stream_interrupted',
                fallbackMessage: 'Связь оборвалась. Попробуй ещё раз.',
              ));
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


