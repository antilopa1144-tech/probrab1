import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/voice_input_provider.dart';
import '../../../core/services/voice_input_service.dart';

/// Кнопка для запуска голосового ввода
class VoiceInputButton extends ConsumerWidget {
  /// Callback для получения распознанного числа
  final void Function(double value) onNumberRecognized;

  /// Размер кнопки
  final double size;

  /// Цвет иконки
  final Color? iconColor;

  /// Tooltip текст
  final String? tooltip;

  const VoiceInputButton({
    super.key,
    required this.onNumberRecognized,
    this.size = 24,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputProvider);
    final theme = Theme.of(context);

    return IconButton(
      icon: voiceState.isListening
          ? SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  iconColor ?? theme.colorScheme.primary,
                ),
              ),
            )
          : Icon(
              Icons.mic_rounded,
              size: size,
              color: iconColor ?? theme.colorScheme.primary,
            ),
      onPressed: voiceState.isListening
          ? null
          : () => _startVoiceInput(context, ref),
      tooltip: tooltip ?? 'Голосовой ввод',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tight(Size(size + 8, size + 8)),
    );
  }

  Future<void> _startVoiceInput(BuildContext context, WidgetRef ref) async {
    // Проверяем и запрашиваем разрешение на микрофон
    final service = ref.read(voiceInputServiceProvider);
    final permissionStatus = await service.checkPermission();

    if (permissionStatus.isGranted) {
      // Разрешение уже есть, продолжаем
      if (!context.mounted) return;
      await _showVoiceInputDialog(context, ref);
      return;
    }

    // Запрашиваем разрешение
    final requestResult = await service.requestPermission();

    if (requestResult.isGranted) {
      // Разрешение получено
      if (!context.mounted) return;
      await _showVoiceInputDialog(context, ref);
    } else if (requestResult.isPermanentlyDenied) {
      // Разрешение навсегда отклонено - показываем диалог с кнопкой настроек
      if (context.mounted) {
        await _showPermissionDialog(context);
      }
    } else {
      // Разрешение отклонено - показываем ошибку
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Необходимо разрешение на использование микрофона'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVoiceInputDialog(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(voiceInputProvider.notifier);

    // Показываем диалог
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VoiceInputDialog(),
    );

    // Если получили результат, вызываем callback
    if (result != null) {
      onNumberRecognized(result);
    }

    // Останавливаем прослушивание
    await notifier.stopListening();
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Доступ к микрофону'),
          content: const Text(
            'Для использования голосового ввода необходимо разрешение на доступ к микрофону.\n\n'
            'Пожалуйста, откройте настройки приложения и предоставьте разрешение.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Открыть настройки'),
            ),
          ],
        );
      },
    );
  }
}

/// Диалог для прослушивания голосового ввода
class VoiceInputDialog extends ConsumerStatefulWidget {
  const VoiceInputDialog({super.key});

  @override
  ConsumerState<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends ConsumerState<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _lastRecognizedText;
  double? _lastRecognizedNumber;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();

    // Анимация пульсации микрофона
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Начинаем слушать при открытии диалога
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Отменяем слушание при закрытии диалога
    ref.read(voiceInputProvider.notifier).cancelListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    final notifier = ref.read(voiceInputProvider.notifier);

    // Таймаут для инициализации - если не запустилось за 5 секунд, закрываем
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isStarted && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось запустить распознавание речи'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final started = await notifier.startListening(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _lastRecognizedText = result.text;
          _lastRecognizedNumber = result.number;
        });

        // Если получили финальный результат с числом, закрываем диалог
        if (result.isFinal && result.number != null) {
          Navigator.of(context).pop(result.number);
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка распознавания: $error'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      },
    );

    _isStarted = started;

    // Если не удалось запустить, закрываем диалог
    if (!started && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceState = ref.watch(voiceInputProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Text(
              'Голосовой ввод',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Анимированный микрофон или иконка ошибки
            if (voiceState.status == VoiceInputStatus.permissionDenied)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.errorContainer,
                ),
                child: Icon(
                  Icons.mic_off_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
              )
            else
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.2),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Статус
            if (voiceState.status == VoiceInputStatus.permissionDenied)
              Text(
                'Доступ к микрофону запрещен',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (voiceState.isListening)
              Text(
                'Говорите...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                'Инициализация...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),

            // Распознанный текст
            if (_lastRecognizedText != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Распознано:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastRecognizedText!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_lastRecognizedNumber != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Число: $_lastRecognizedNumber',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Подсказка
            Text(
              'Назовите размер, например:\n"три метра сорок пять"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Кнопки
            if (voiceState.status == VoiceInputStatus.permissionDenied)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Открыть настройки'),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  if (_lastRecognizedNumber != null)
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_lastRecognizedNumber),
                      child: const Text('Применить'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
