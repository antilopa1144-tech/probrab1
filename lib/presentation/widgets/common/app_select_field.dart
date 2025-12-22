import 'package:flutter/material.dart';

class SelectOption<T> {
  final T value;
  final String label;
  final Widget? leading;
  final bool enabled;

  const SelectOption({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
  });
}

class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<SelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppSelectField({
    super.key,
    required this.options,
    required this.onChanged,
    this.label,
    this.hint,
    this.value,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option.value,
              enabled: option.enabled,
              child: Row(
                children: [
                  if (option.leading != null) ...[
                    option.leading!,
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(option.label)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
