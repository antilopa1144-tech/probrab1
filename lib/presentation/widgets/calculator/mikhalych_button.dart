import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
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

  /// Обратная связь: null = не оценено, true = полезно, false = не полезно
  final bool? feedback;

  /// Прикреплённое фото (только в памяти, не сохраняется в prefs)
  final Uint8List? imageBytes;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.feedback,
    this.imageBytes,
  });

  _ChatMessage copyWith({String? text, bool? isStreaming, bool? feedback}) {
    return _ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      isStreaming: isStreaming ?? this.isStreaming,
      feedback: feedback ?? this.feedback,
      imageBytes: imageBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        if (feedback != null) 'feedback': feedback,
        // imageBytes не сериализуем — изображения не персистируем
      };

  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        feedback: json['feedback'] as bool?,
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

  /// Флаг: Privacy Notice принят
  bool _privacyAccepted = false;

  /// Последний вопрос для retry
  String? _lastQuestion;

  /// Кэшированный сервис — без повторного await на каждое сообщение
  AiService? _service;

  /// Текущая подписка на стрим — для cancel() в dispose
  StreamSubscription<String>? _streamSub;

  /// Safety-таймер: если _isLoading висит > 90 сек — принудительный сброс
  Timer? _safetyTimer;

  /// Выбранное фото для отправки (null = ничего не выбрано)
  Uint8List? _selectedImageBytes;
  String _selectedImageMimeType = 'image/jpeg';

  static const _historyPrefsKey = 'mikhalych_chat_history';
  static const _privacyAcceptedKey = 'mikhalych_privacy_accepted';
  static const _maxSavedMessages = 50;

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
    } catch (_) {
      // Ошибка инициализации — _askStream обработает null _service
    }

    // Проверяем, принят ли Privacy Notice
    try {
      final prefs = await SharedPreferences.getInstance();
      _privacyAccepted = prefs.getBool(_privacyAcceptedKey) ?? false;
    } catch (_) {
      _privacyAccepted = false;
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

  Future<void> _acceptPrivacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_privacyAcceptedKey, true);
    } catch (e) {
      debugPrint('Mikhalych: failed to save privacy acceptance: $e');
    }
    if (mounted) {
      setState(() => _privacyAccepted = true);
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
    } catch (e) {
      debugPrint('Mikhalych: failed to save history: $e');
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyPrefsKey);
    } catch (e) {
      debugPrint('Mikhalych: failed to clear history: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Welcome-экран и быстрые вопросы
  // ---------------------------------------------------------------------------

  bool _isHomeScreenContext(AppLocalizations loc) {
    return widget.calculatorName == loc.translate('home.main_screen');
  }

  List<String> _getQuickQuestions() {
    final loc = AppLocalizations.of(context);
    if (_isHomeScreenContext(loc)) {
      return [
        loc.translate('ai.quick_question.home.1'),
        loc.translate('ai.quick_question.home.2'),
        loc.translate('ai.quick_question.home.3'),
        loc.translate('ai.quick_question.home.4'),
      ];
    }
    if (widget.data.isNotEmpty) {
      return [
        loc.translate('ai.quick_question.calculation.1'),
        loc.translate('ai.quick_question.calculation.2'),
        loc.translate('ai.quick_question.calculation.3'),
        loc.translate('ai.quick_question.calculation.4'),
      ];
    }
    return [
      loc.translate('ai.quick_question.generic.1').replaceFirst('{name}', widget.calculatorName),
      loc.translate('ai.quick_question.generic.2'),
      loc.translate('ai.quick_question.generic.3'),
      loc.translate('ai.quick_question.generic.4'),
    ];
  }

  String _getWelcomePhrase() {
    final loc = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (_isHomeScreenContext(loc)) {
      if (hour < 12) {
        return loc.translate('ai.welcome.home.morning');
      } else if (hour < 18) {
        return loc.translate('ai.welcome.home.day');
      } else {
        return loc.translate('ai.welcome.home.evening');
      }
    }
    return loc.translate('ai.welcome.calculator').replaceFirst('{name}', widget.calculatorName);
  }

  String _localizeAiError(Object error, AppLocalizations loc) {
    if (error is AiApiException) {
      return loc.translate(error.messageKey, error.messageParams);
    }
    if (error is AiDailyLimitException) {
      return loc.translate(error.messageKey, error.messageParams);
    }
    return loc.translate('ai.error_generic');
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
  // Выбор фото
  // ---------------------------------------------------------------------------

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Камера'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галерея'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final mime = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageMimeType = mime;
      });
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Отправка сообщения и стриминг ответа
  // ---------------------------------------------------------------------------

  void _sendMessage() {
    final text = _textController.text.trim();
    final imageBytes = _selectedImageBytes;
    final imageMime = _selectedImageMimeType;
    if ((text.isEmpty && imageBytes == null) || _isLoading) return;

    setState(() {
      _showWelcome = false;
      _messages.add(_ChatMessage(text: text, isUser: true, imageBytes: imageBytes));
      _error = null;
      _selectedImageBytes = null;
      _selectedImageMimeType = 'image/jpeg';
    });
    _textController.clear();
    _scrollToBottom();

    _askStream(text, imageBytes: imageBytes, imageMimeType: imageMime);
  }

  void _retryLastQuestion() {
    final q = _lastQuestion;
    if (q == null || _isLoading) return;
    setState(() {
      _error = null;
      _messages.add(_ChatMessage(text: q, isUser: true));
    });
    _scrollToBottom();
    _askStream(q);
  }

  /// Отправляет вопрос (опционально с фото) и слушает стрим.
  void _askStream(String question, {Uint8List? imageBytes, String imageMimeType = 'image/jpeg'}) {
    _lastQuestion = question.isNotEmpty ? question : '📷 фото';

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

    final loc = AppLocalizations.of(context);
    final effectiveQuestion = question.isEmpty && imageBytes != null
        ? 'Посмотри на это фото и скажи, что видишь. Дай строительный совет если уместно.'
        : question;
    final stream = service.getAdviceStream(
      calculatorName: widget.calculatorName,
      data: widget.data,
      userQuestion: effectiveQuestion,
      calculationHistory: widget.calculationHistory,
      isHomeScreen: _isHomeScreenContext(loc),
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
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
            _error = _localizeAiError(error, loc);
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

          // Контент: Privacy → Welcome → чат
          Flexible(
            child: _showWelcome && !_privacyAccepted
                ? _buildPrivacyNotice(isDark, loc)
                : _showWelcome
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

          // Превью выбранного фото
          if (_selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() { _selectedImageBytes = null; }),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Поле ввода
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomPadding),
            child: Row(
              children: [
                // Кнопка прикрепить фото
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _isLoading ? null : _showImageSourceDialog,
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: _selectedImageBytes != null
                            ? widget.accentColor
                            : (isDark ? Colors.white38 : Colors.black38),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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

  Widget _buildPrivacyNotice(bool isDark, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined,
                        color: Colors.blue[600], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      loc.translate('ai.privacy.title'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('ai.privacy.description'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.translate('ai.privacy.data_info'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acceptPrivacy,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(loc.translate('ai.privacy.accept')),
            ),
          ),
        ],
      ),
    );
  }

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
            loc.translate('ai.quick_questions_title'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.imageBytes != null)
                Padding(
                  padding: EdgeInsets.only(bottom: message.text.isNotEmpty ? 8 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      message.imageBytes!,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
            ],
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
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.87)
                            : Colors.black87,
                      ),
                      strong: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.87)
                            : Colors.black87,
                      ),
                      listBullet: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.87)
                            : Colors.black87,
                      ),
                      code: TextStyle(
                        fontSize: 13,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      blockSpacing: 8,
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
                  const SizedBox(width: 12),
                  // Thumbs up/down
                  _FeedbackChip(
                    isPositive: true,
                    isSelected: message.feedback == true,
                    isDark: isDark,
                    onTap: () => _setFeedback(message, true),
                  ),
                  const SizedBox(width: 4),
                  _FeedbackChip(
                    isPositive: false,
                    isSelected: message.feedback == false,
                    isDark: isDark,
                    onTap: () => _setFeedback(message, false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _setFeedback(_ChatMessage message, bool isPositive) {
    final index = _messages.indexOf(message);
    if (index < 0) return;
    // Toggle: если уже выбрано то же — снимаем
    final newFeedback = message.feedback == isPositive ? null : isPositive;
    setState(() {
      _messages[index] = message.copyWith(feedback: newFeedback);
    });
    _saveHistory();
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
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (_lastQuestion != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _retryLastQuestion,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(loc.translate('ai.retry')),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
          ],
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

class _FeedbackChip extends StatelessWidget {
  final bool isPositive;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FeedbackChip({
    required this.isPositive,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isPositive ? Icons.thumb_up_outlined : Icons.thumb_down_outlined;
    final selectedIcon = isPositive ? Icons.thumb_up : Icons.thumb_down;
    final color = isSelected
        ? (isPositive ? Colors.green : Colors.red)
        : (isDark ? Colors.white38 : Colors.black38);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isSelected ? selectedIcon : icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

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

