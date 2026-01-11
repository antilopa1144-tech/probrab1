import 'package:flutter/material.dart';

/// Состояния анимированного микрофона
enum MicIconState {
  idle,
  listening,
  processing,
}

/// Анимированная иконка микрофона
class AnimatedMicIcon extends StatefulWidget {
  /// Текущее состояние
  final MicIconState state;

  /// Размер иконки
  final double size;

  /// Цвет иконки
  final Color? color;

  /// Цвет фона
  final Color? backgroundColor;

  /// Показывать ли фон
  final bool showBackground;

  /// Callback при нажатии
  final VoidCallback? onTap;

  const AnimatedMicIcon({
    super.key,
    required this.state,
    this.size = 48,
    this.color,
    this.backgroundColor,
    this.showBackground = true,
    this.onTap,
  });

  @override
  State<AnimatedMicIcon> createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<AnimatedMicIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _transitionController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  MicIconState _previousState = MicIconState.idle;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateAnimations();
  }

  void _initAnimations() {
    // Пульсация для состояния listening
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Вращение для состояния processing
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.linear,
      ),
    );

    // Анимация перехода между состояниями
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _updateAnimations() {
    // Останавливаем все анимации
    _pulseController.stop();
    _rotateController.stop();

    // Запускаем нужную анимацию в зависимости от состояния
    switch (widget.state) {
      case MicIconState.idle:
        _pulseController.value = 0;
        _rotateController.value = 0;
        break;
      case MicIconState.listening:
        _pulseController.repeat(reverse: true);
        break;
      case MicIconState.processing:
        _rotateController.repeat();
        break;
    }

    // Анимация перехода
    if (_previousState != widget.state) {
      _transitionController.forward(from: 0);
      _previousState = widget.state;
    }
  }

  @override
  void didUpdateWidget(AnimatedMicIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.color ?? theme.colorScheme.primary;
    final bgColor = widget.backgroundColor ??
        iconColor.withValues(alpha: 0.1);

    final content = AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotateController,
        _transitionController,
      ]),
      builder: (context, child) {
        Widget micIcon = Icon(
          _getIconForState(),
          size: widget.size * 0.6,
          color: iconColor,
        );

        // Применяем вращение для processing
        if (widget.state == MicIconState.processing) {
          micIcon = RotationTransition(
            turns: _rotationAnimation,
            child: micIcon,
          );
        }

        // Применяем scale для listening
        double scale = 1.0;
        if (widget.state == MicIconState.listening) {
          scale = _scaleAnimation.value;
        }

        // Применяем transition анимацию
        final transitionScale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(
              CurvedAnimation(
                parent: _transitionController,
                curve: Curves.easeOut,
              ),
            )
            .value;

        return Transform.scale(
          scale: scale * transitionScale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: widget.showBackground
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor.withValues(
                      alpha: widget.state == MicIconState.listening
                          ? _opacityAnimation.value * 0.3
                          : 0.1,
                    ),
                    border: Border.all(
                      color: widget.state == MicIconState.idle
                          ? iconColor.withValues(alpha: 0.3)
                          : iconColor.withValues(
                              alpha: widget.state == MicIconState.listening
                                  ? _opacityAnimation.value
                                  : 1.0,
                            ),
                      width: 2,
                    ),
                  )
                : null,
            child: Center(child: micIcon),
          ),
        );
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }

  IconData _getIconForState() {
    switch (widget.state) {
      case MicIconState.idle:
        return Icons.mic_none_rounded;
      case MicIconState.listening:
        return Icons.mic_rounded;
      case MicIconState.processing:
        return Icons.settings_voice_rounded;
    }
  }
}

/// Кнопка с анимированным микрофоном
class AnimatedMicButton extends StatelessWidget {
  /// Текущее состояние
  final MicIconState state;

  /// Размер кнопки
  final double size;

  /// Callback при нажатии
  final VoidCallback? onPressed;

  /// Tooltip
  final String? tooltip;

  /// Цвет иконки
  final Color? iconColor;

  const AnimatedMicButton({
    super.key,
    required this.state,
    this.size = 56,
    this.onPressed,
    this.tooltip,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? _getTooltipForState(),
      child: AnimatedMicIcon(
        state: state,
        size: size,
        color: iconColor,
        onTap: onPressed,
      ),
    );
  }

  String _getTooltipForState() {
    switch (state) {
      case MicIconState.idle:
        return 'Начать голосовой ввод';
      case MicIconState.listening:
        return 'Слушаю...';
      case MicIconState.processing:
        return 'Обработка...';
    }
  }
}
