import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String? title;
  final String? description;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  const EmptyState({
    super.key,
    this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
            ],
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            if (description != null) ...[
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (child != null) child!,
            if (onAction != null && actionLabel != null) ...[
              if (child != null) const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
