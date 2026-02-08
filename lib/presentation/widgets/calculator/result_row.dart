import 'package:flutter/material.dart';

class ResultRowData {
  final String label;
  final String value;
  final String? unit;
  final String? subtitle;

  const ResultRowData({
    required this.label,
    required this.value,
    this.unit,
    this.subtitle,
  });
}

class ResultRow extends StatelessWidget {
  final ResultRowData data;

  const ResultRow({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: theme.textTheme.bodyMedium,
              ),
              if (data.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  data.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            data.unit == null ? data.value : '${data.value} ${data.unit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
