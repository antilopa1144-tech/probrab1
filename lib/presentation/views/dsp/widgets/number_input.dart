import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInput extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const NumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toStringAsFixed(0));
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onSubmitted: (text) {
        final newValue = double.tryParse(text);
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      onTapOutside: (event) {
        final newValue = double.tryParse(controller.text);
        if (newValue != null) {
          onChanged(newValue);
        }
         FocusScope.of(context).unfocus();
      },
    );
  }
}