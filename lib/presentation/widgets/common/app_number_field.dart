import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNumberField extends StatelessWidget {
  final String? label;
  final double value;
  final double? min;
  final double? max;
  final double step;
  final String? unit;
  final String? helperText;
  final bool required;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final TextEditingController? controller;

  const AppNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.min,
    this.max,
    this.step = 1.0,
    this.unit,
    this.helperText,
    this.required = false,
    this.enabled = true,
    this.controller,
  });

  double _clampValue(double next) {
    final minValue = min ?? double.negativeInfinity;
    final maxValue = max ?? double.infinity;
    return next.clamp(minValue, maxValue);
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _updateValue(double next) {
    onChanged(_clampValue(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onPressed: enabled
                  ? () => _updateValue(value - step)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildField(theme)),
            const SizedBox(width: 8),
            _StepButton(
              icon: Icons.add,
              onPressed: enabled
                  ? () => _updateValue(value + step)
                  : null,
            ),
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ] else if (min != null || max != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (min != null)
                Text(
                  _formatValue(min!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (max != null)
                Text(
                  _formatValue(max!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildField(ThemeData theme) {
    final decoration = InputDecoration(
      suffixText: unit,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
    ];

    if (controller != null) {
      return TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        decoration: decoration,
        inputFormatters: formatters,
        onChanged: (text) {
          final parsed = double.tryParse(text.replaceAll(',', '.'));
          if (parsed != null) {
            _updateValue(parsed);
          }
        },
      );
    }

    return TextFormField(
      key: ValueKey(value),
      initialValue: _formatValue(value),
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: decoration,
      inputFormatters: formatters,
      onChanged: (text) {
        final parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed != null) {
          _updateValue(parsed);
        }
      },
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: onPressed != null
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
