import 'package:flutter/material.dart';

class InputFieldRow extends StatelessWidget {
  final String label;
  final Widget field;
  final String? helperText;
  final bool required;

  const InputFieldRow({
    super.key,
    required this.label,
    required this.field,
    this.helperText,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (required)
              Text(
                '*',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
        const SizedBox(height: 8),
        field,
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}
