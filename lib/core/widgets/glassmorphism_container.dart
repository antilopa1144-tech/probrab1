import 'dart:ui';
import 'package:flutter/material.dart';

/// Контейнер с эффектом glassmorphism (размытие фона).
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;
  final Border? border;

  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderRadius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.surfaceContainerHighest)
                .withValues(alpha: opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: border ??
                Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

