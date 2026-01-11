import 'package:flutter/material.dart';

/// Состояния feedback overlay
enum VoiceFeedbackState {
  idle,
  listening,
  processing,
  success,
  error,
}

/// Overlay для отображения feedback во время голосового ввода
class VoiceFeedbackOverlay extends StatefulWidget {
  /// Состояние feedback
  final VoiceFeedbackState state;

  /// Распознанный текст
  final String? recognizedText;

  /// Сообщение об ошибке
  final String? errorMessage;

  /// Callback для отмены
  final VoidCallback? onCancel;

  /// Показывать ли анимацию пульсации
  final bool showPulse;

  const VoiceFeedbackOverlay({
    super.key,
    required this.state,
    this.recognizedText,
    this.errorMessage,
    this.onCancel,
    this.showPulse = true,
  });

  @override
  State<VoiceFeedbackOverlay> createState() => _VoiceFeedbackOverlayState();
}

class _VoiceFeedbackOverlayState extends State<VoiceFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    if (widget.showPulse &&
        (widget.state == VoiceFeedbackState.listening ||
            widget.state == VoiceFeedbackState.processing)) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceFeedbackOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      if (widget.showPulse &&
          (widget.state == VoiceFeedbackState.listening ||
              widget.state == VoiceFeedbackState.processing)) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.state == VoiceFeedbackState.idle) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка с анимацией
              _buildIconSection(theme),
              const SizedBox(height: 24),

              // Статус
              _buildStatusSection(theme),

              // Распознанный текст
              if (widget.recognizedText != null &&
                  widget.recognizedText!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecognizedTextSection(theme),
              ],

              // Ошибка
              if (widget.state == VoiceFeedbackState.error &&
                  widget.errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorSection(theme),
              ],

              // Кнопка отмены
              if (widget.onCancel != null &&
                  widget.state != VoiceFeedbackState.success &&
                  widget.state != VoiceFeedbackState.error) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Отмена'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection(ThemeData theme) {
    final icon = _getIconForState();
    final color = _getColorForState(theme);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final shouldAnimate = widget.showPulse &&
            (widget.state == VoiceFeedbackState.listening ||
                widget.state == VoiceFeedbackState.processing);

        return Transform.scale(
          scale: shouldAnimate ? _scaleAnimation.value : 1.0,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(
                  alpha: shouldAnimate ? _opacityAnimation.value * 0.3 : 0.3),
            ),
            child: Icon(
              icon,
              size: 40,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    final status = _getStatusText();
    final color = _getColorForState(theme);

    return Text(
      status,
      style: theme.textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRecognizedTextSection(ThemeData theme) {
    return Container(
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
            widget.recognizedText!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForState() {
    switch (widget.state) {
      case VoiceFeedbackState.idle:
        return Icons.mic_none_rounded;
      case VoiceFeedbackState.listening:
        return Icons.mic_rounded;
      case VoiceFeedbackState.processing:
        return Icons.hourglass_empty_rounded;
      case VoiceFeedbackState.success:
        return Icons.check_circle_rounded;
      case VoiceFeedbackState.error:
        return Icons.error_rounded;
    }
  }

  Color _getColorForState(ThemeData theme) {
    switch (widget.state) {
      case VoiceFeedbackState.idle:
        return theme.colorScheme.onSurfaceVariant;
      case VoiceFeedbackState.listening:
        return theme.colorScheme.primary;
      case VoiceFeedbackState.processing:
        return theme.colorScheme.tertiary;
      case VoiceFeedbackState.success:
        return Colors.green;
      case VoiceFeedbackState.error:
        return theme.colorScheme.error;
    }
  }

  String _getStatusText() {
    switch (widget.state) {
      case VoiceFeedbackState.idle:
        return 'Готов к прослушиванию';
      case VoiceFeedbackState.listening:
        return 'Говорите...';
      case VoiceFeedbackState.processing:
        return 'Обрабатываем...';
      case VoiceFeedbackState.success:
        return 'Готово!';
      case VoiceFeedbackState.error:
        return 'Ошибка';
    }
  }
}
