import 'package:flutter/material.dart';

class ErrorMessage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorMessage({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon ?? Icons.error_outline,
          size: 40,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}
