import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/ai_service.dart';

/// Кнопка «Спросить Михалыча» для главного экрана.
///
/// Собирает данные расчёта и отправляет в AI-сервис.
/// Результат показывается в BottomSheet-чате с аватаркой прораба.
class MikhalychButton extends StatelessWidget {
  final String calculatorName;
  final Map<String, dynamic> Function() dataCollector;
  final Color accentColor;
  final String? calculationHistory;

  const MikhalychButton({
    required this.calculatorName,
    required this.dataCollector,
    this.accentColor = CalculatorColors.interior,
    this.calculationHistory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.engineering,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('ai.title'),
                      style: CalculatorDesignSystem.titleMedium.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      loc.translate('ai.subtitle_short'),
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _askMikhalych(context),
              icon: const Icon(Icons.construction, size: 18),
              label: Text(loc.translate('ai.ask_button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _askMikhalych(BuildContext context) async {
    final data = dataCollector();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MikhalychBottomSheet(
          calculatorName: calculatorName,
          data: data,
          accentColor: accentColor,
          calculationHistory: calculationHistory,
        );
      },
    );
  }
}

// =============================================================================
// Модель сообщения
// =============================================================================

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  _ChatMessage copyWith({String? text, bool? isStreaming}) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
      );
}

// =============================================================================
// BottomSheet-чат с Михалычем
// =============================================================================

/// BottomSheet-чат с Михалычем.
///
/// **Архитектура стриминга:**
/// Используем StreamSubscription с onData/onError/onDone callbacks
/// вместо `await for`. Это гарантирует:
/// - `_isLoading = false` в onDone/onError ВСЕГДА
/// - Корректная отмена в dispose() (cancel)
/// - Никаких зависших спиннеров
///
/// **История диалога:**
/// Сохраняется между сеансами в SharedPreferences.
/// Ограничение — последние 20 сообщений.
class MikhalychBottomSheet extends StatefulWidget {
  final String calculatorName;
  final Map<String, dynamic> data;
  final Color accentColor;
  final String? calculationHistory;

  const MikhalychBottomSheet({
    required this.calculatorName,
    required this.data,
    required this.accentColor,
    this.calculationHistory,
    super.key,
  });

  @override
  State<MikhalychBottomSheet> createState() => _MikhalychBottomSheetState();
}

class _MikhalychBottomSheetState extends State<MikhalychBottomSheet> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _error;
  bool _isLoading = false;

  /// Флаг: показываем Welcome-экран (до первого вопроса)
  bool _showWelcome = true;

  /// Кэшированный сервис — без повторного await на каждое сообщение
  AiService? _service;

  /// Текущая подписка на стрим — для cancel() в dispose
  StreamSubscription<String>? _streamSub;

  /// Safety-таймер: если _isLoading висит > 90 сек — принудительный сброс
  Timer? _safetyTimer;

  static const _historyPrefsKey = 'mikhalych_chat_history';
  static const _maxSavedMessages = 20;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _streamSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Инициализация
  // ---------------------------------------------------------------------------

  Future<void> _initService() async {
    try {
      _service = AiService.instanceSync ?? await AiService.instance;
      _service!.startChat(
        calculatorName: widget.calculatorName,
        data: widget.data,
        calculationHistory: widget.calculationHistory,
      );
    } catch (_) {
      // Ошибка инициализации — _askStream обработает null _service
    }

    // Загружаем историю диалога из памяти
    await _loadHistory();

    // Если есть сохранённая история — сразу показываем чат (не welcome)
    if (_messages.isNotEmpty && mounted) {
      setState(() {
        _showWelcome = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_historyPrefsKey);
      if (json == null) return;
      final list = jsonDecode(json) as List<dynamic>;
      final loaded = list
          .cast<Map<String, dynamic>>()
          .map(_ChatMessage.fromJson)
          .toList();
      if (mounted && loaded.isNotEmpty) {
        setState(() => _messages.addAll(loaded));
      }
    } catch (_) {
      // Ошибка загрузки истории — начинаем с чистого листа
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _messages.length > _maxSavedMessages
          ? _messages.sublist(_messages.length - _maxSavedMessages)
          : _messages;
      final json = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_historyPrefsKey, json);
    } catch (_) {}
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyPrefsKey);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Welcome-экран и быстрые вопросы
  // ---------------------------------------------------------------------------

  List<String> _getQuickQuestions() {
    if (widget.calculatorName == 'Главный экран') {
      return [
        'Что важно не забыть при ремонте в новостройке?',
        'С чего начать расчёт материалов для ванной?',
        'Какие ошибки чаще всего делают при укладке плитки?',
        'Как правильно выбрать тип штукатурки?',
      ];
    }
    if (widget.data.isNotEmpty) {
      return [
        'Проверь мой расчёт — всё правильно?',
        'Что я мог забыть в этом расчёте?',
        'Какой материал посоветуешь для этого случая?',
        'На что обратить внимание при работе с этим?',
      ];
    }
    return [
      'Дай практический совет по ${widget.calculatorName}.',
      'Какие ошибки чаще всего делают?',
      'Какой материал посоветуешь?',
      'С чего начать?',
    ];
  }

  String _getWelcomePhrase() {
    final hour = DateTime.now().hour;
    if (widget.calculatorName == 'Главный экран') {
      if (hour < 12) {
        return 'Доброе утро. Ну что, за работу?';
      } else if (hour < 18) {
        return 'О, заявился. Давай, спрашивай — время не ждёт.';
      } else {
        return 'Поздновато, конечно, но ладно. Чего хотел?';
      }
    }
    return 'Смотрю на ${widget.calculatorName}. Ну, задавай вопрос.';
  }

  void _onQuickQuestion(String question) {
    setState(() {
      _showWelcome = false;
      _messages.add(_ChatMessage(text: question, isUser: true));
      _error = null;
    });
    _scrollToBottom();
    _askStream(question);
  }

  // ---------------------------------------------------------------------------
  // Отправка сообщения и стриминг ответа
  // ---------------------------------------------------------------------------

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _showWelcome = false;
      _messages.add(_ChatMessage(text: text, isUser: true));
      _error = null;
    });
    _textController.clear();
    _scrollToBottom();

    _askStream(text);
  }

  /// Отправляет вопрос и слушает стрим через StreamSubscription.
  void _askStream(String question) {
    // Отменяем предыдущий стрим и safety-таймер
    _safetyTimer?.cancel();
    _streamSub?.cancel();
    _streamSub = null;

    final service = _service;
    if (service == null) {
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      setState(() {
        _error = loc.translate('ai.error_not_initialized');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Safety-таймер: если через 90 сек ответ не пришёл — сбросить спиннер
    _safetyTimer = Timer(const Duration(seconds: 90), () {
      if (!mounted || !_isLoading) return;
      _streamSub?.cancel();
      final loc = AppLocalizations.of(context);
      setState(() {
        _isLoading = false;
        _error = loc.translate('ai.error_timeout');
      });
    });

    // Добавляем placeholder для ответа Михалыча
    final aiIndex = _messages.length;
    setState(() {
      _messages.add(const _ChatMessage(
        text: '',
        isUser: false,
        isStreaming: true,
      ));
    });

    var fullText = '';

    final stream = service.getAdviceStream(
      calculatorName: widget.calculatorName,
      data: widget.data,
      userQuestion: question,
    );

    _streamSub = stream.listen(
      // onData — каждый чанк текста
      (chunk) {
        if (!mounted) return;
        fullText += chunk;
        setState(() {
          if (aiIndex < _messages.length) {
            _messages[aiIndex] = _messages[aiIndex].copyWith(text: fullText);
          }
        });
        _scrollToBottom();
      },

      // onError — ошибка из стрима (API, сеть, таймаут)
      onError: (Object error) {
        _safetyTimer?.cancel();
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        setState(() {
          if (fullText.isEmpty && aiIndex < _messages.length) {
            // Нет текста — убираем placeholder, показываем ошибку
            _messages.removeAt(aiIndex);
            _error = error is AiApiException
                ? error.message
                : error is AiDailyLimitException
                    ? error.message
                    : loc.translate('ai.error_generic');
          } else if (aiIndex < _messages.length) {
            // Есть частичный текст — оставляем, завершаем стриминг
            _messages[aiIndex] =
                _messages[aiIndex].copyWith(isStreaming: false);
          }
          _isLoading = false;
        });
        _saveHistory();
        _scrollToBottom();
      },

      // onDone — стрим завершён успешно
      onDone: () {
        _safetyTimer?.cancel();
        if (!mounted) return;
        setState(() {
          if (aiIndex < _messages.length && !_messages[aiIndex].isUser) {
            _messages[aiIndex] =
                _messages[aiIndex].copyWith(isStreaming: false);
          }
          _isLoading = false;
        });
        _saveHistory();
        _scrollToBottom();
      },

      cancelOnError: false,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    _streamSub?.cancel();
    _safetyTimer?.cancel();
    _service?.resetChat();
    _clearHistory();
    // Переинициализируем чат в сервисе
    _service?.startChat(
      calculatorName: widget.calculatorName,
      data: widget.data,
      calculationHistory: widget.calculationHistory,
    );
    setState(() {
      _messages.clear();
      _error = null;
      _isLoading = false;
      _showWelcome = true;
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final loc = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.engineering,
                    color: widget.accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('ai.mikhalych'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        loc.translate('ai.subtitle'),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Кнопка "Начать заново" — только если есть история
                if (_messages.isNotEmpty)
                  IconButton(
                    onPressed: _resetChat,
                    tooltip: loc.translate('ai.clear_chat'),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
          ),

          // Контент: Welcome или чат
          Flexible(
            child: _showWelcome
                ? _buildWelcomeScreen(isDark, loc)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length + (_error != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_error != null && index == _messages.length) {
                        return _buildErrorBubble(isDark);
                      }
                      return _buildMessageBubble(_messages[index], isDark, loc);
                    },
                  ),
          ),

          Divider(
            height: 1,
            color:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
          ),

          // Поле ввода
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomPadding),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: loc.translate('ai.ask_placeholder'),
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: _isLoading
                      ? (isDark ? Colors.white12 : Colors.black12)
                      : widget.accentColor,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isLoading ? null : _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: widget.accentColor,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Welcome-экран
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeScreen(bool isDark, AppLocalizations loc) {
    final questions = _getQuickQuestions();
    final welcomePhrase = _getWelcomePhrase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветственное сообщение от Михалыча
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              welcomePhrase,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.87)
                    : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Заголовок быстрых вопросов
          Text(
            'Быстрые вопросы:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Кнопки быстрых вопросов
          ...questions.map(
            (q) => _buildQuickQuestionChip(q, isDark),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildQuickQuestionChip(String question, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onQuickQuestion(question),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(12),
              color: widget.accentColor.withValues(
                alpha: isDark ? 0.08 : 0.05,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: widget.accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Виджеты сообщений
  // ---------------------------------------------------------------------------

  Widget _buildMessageBubble(
    _ChatMessage message,
    bool isDark,
    AppLocalizations loc,
  ) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.accentColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Сообщение Михалыча
    final isComplete = !message.isStreaming && message.text.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 48, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: message.text.isEmpty && message.isStreaming
                ? _buildTypingIndicator()
                : Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.87)
                          : Colors.black87,
                    ),
                  ),
          ),
          if (isComplete)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionChip(
                    icon: Icons.copy_rounded,
                    label: loc.translate('ai.action_copy'),
                    isDark: isDark,
                    onTap: () => _copyText(message.text),
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.share_rounded,
                    label: loc.translate('ai.action_share'),
                    isDark: isDark,
                    onTap: () => _shareText(message.text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('ai.copied_snackbar')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareText(String text) {
    final loc = AppLocalizations.of(context);
    SharePlus.instance.share(
      ShareParams(
        text: '$text\n\n${loc.translate('ai.share_footer')}',
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return _AnimatedTypingIndicator(accentColor: widget.accentColor);
  }

  Widget _buildErrorBubble(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Анимированный индикатор «Михалыч думает»
// =============================================================================

class _AnimatedTypingIndicator extends StatefulWidget {
  final Color accentColor;

  const _AnimatedTypingIndicator({required this.accentColor});

  @override
  State<_AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<_AnimatedTypingIndicator> {
  static const _phraseKeys = [
    'ai.thinking.0',
    'ai.thinking.1',
    'ai.thinking.2',
    'ai.thinking.3',
    'ai.thinking.4',
    'ai.thinking.5',
    'ai.thinking.6',
    'ai.thinking.7',
  ];

  int _phraseIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _phraseIndex = (_phraseIndex + 1) % _phraseKeys.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            '${loc.translate(_phraseKeys[_phraseIndex])}...',
            key: ValueKey(_phraseIndex),
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Action chip
// =============================================================================

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
