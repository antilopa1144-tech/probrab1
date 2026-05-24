import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNumberField extends StatefulWidget {
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

  @override
  State<AppNumberField> createState() => _AppNumberFieldState();
}

class _AppNumberFieldState extends State<AppNumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _usesExternalController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _usesExternalController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController(text: _formatValue(widget.value));
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AppNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _usesExternalController = widget.controller != null;
    }
    if (!_usesExternalController &&
        oldWidget.value != widget.value &&
        !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (!_usesExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitValue();
    }
  }

  double _clampValue(double next) {
    final minValue = widget.min ?? double.negativeInfinity;
    final maxValue = widget.max ?? double.infinity;
    return next.clamp(minValue, maxValue);
  }

  String _formatValue(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _updateValue(double next, {bool clampNow = true}) {
    widget.onChanged(clampNow ? _clampValue(next) : next);
  }

  void _commitValue() {
    final text = _controller.text.trim();
    if (text.isEmpty || text == '-' || text == '.') {
      _updateValue(widget.value);
      _controller.text = _formatValue(_clampValue(widget.value));
      return;
    }
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) {
      _updateValue(widget.value);
      _controller.text = _formatValue(_clampValue(widget.value));
      return;
    }
    final clamped = _clampValue(parsed);
    _controller.text = _formatValue(clamped);
    _updateValue(clamped);
  }

  void _handleTextChange(String text) {
    if (text.isEmpty || text == '-' || text == '.' || text.endsWith('.')) {
      return;
    }
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed != null) {
      _updateValue(parsed, clampNow: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (widget.required) ...[
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
              onPressed: widget.enabled
                  ? () => _updateValue(widget.value - widget.step)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildField(theme)),
            const SizedBox(width: 8),
            _StepButton(
              icon: Icons.add,
              onPressed: widget.enabled
                  ? () => _updateValue(widget.value + widget.step)
                  : null,
            ),
          ],
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ] else if (widget.min != null || widget.max != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.min != null)
                Text(
                  _formatValue(widget.min!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              else
                const SizedBox.shrink(),
              if (widget.max != null)
                Text(
                  _formatValue(widget.max!),
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
      suffixText: widget.unit,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]')),
    ];

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      decoration: decoration,
      inputFormatters: formatters,
      onChanged: _handleTextChange,
      onEditingComplete: _commitValue,
      onTapOutside: (_) => _commitValue(),
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
