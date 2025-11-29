import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/validation/calculator_input_validator.dart';
import '../../../domain/calculators/definitions.dart';

class CalculatorInputField extends StatelessWidget {
  final InputFieldDefinition field;
  final TextEditingController controller;
  final AppLocalizations localization;

  const CalculatorInputField({
    super.key,
    required this.field,
    required this.controller,
    required this.localization,
  });

  String? _getHintForField() {
    if (field.key.contains('area')) return 'Введите площадь';
    if (field.key.contains('length')) return 'Введите длину';
    if (field.key.contains('width')) return 'Введите ширину';
    if (field.key.contains('height')) return 'Введите высоту';
    if (field.key.contains('thickness')) return 'Введите толщину';
    if (field.key.contains('perimeter')) return 'Введите периметр';
    if (field.key.contains('volume')) return 'Введите объём';
    return null;
  }

  String? _getUnitForField() {
    if (field.key.contains('area')) return 'м²';
    if (field.key.contains('length') ||
        field.key.contains('perimeter') ||
        field.key.contains('height')) {
      return 'м';
    }
    if (field.key.contains('width') &&
        (field.key.contains('tile') ||
            field.key.contains('panel') ||
            field.key.contains('board'))) {
      return 'см';
    }
    if (field.key.contains('width')) return 'м';
    if (field.key.contains('thickness')) return 'мм';
    if (field.key.contains('volume')) return 'м³';
    if (field.key.contains('layers') || field.key.contains('count')) return 'шт';
    if (field.key.contains('consumption')) return 'л/м²';
    if (field.key.contains('power')) return 'Вт/м²';
    return null;
  }

  Icon? _getIconForField() {
    if (field.key.contains('area')) {
      return const Icon(Icons.square_foot, size: 20);
    }
    if (field.key.contains('length') || field.key.contains('perimeter')) {
      return const Icon(Icons.straighten, size: 20);
    }
    if (field.key.contains('height')) {
      return const Icon(Icons.height, size: 20);
    }
    if (field.key.contains('width')) {
      return const Icon(Icons.width_normal, size: 20);
    }
    if (field.key.contains('thickness')) {
      return const Icon(Icons.layers, size: 20);
    }
    if (field.key.contains('volume')) {
      return const Icon(Icons.view_in_ar, size: 20);
    }
    if (field.key.contains('window')) {
      return const Icon(Icons.window, size: 20);
    }
    if (field.key.contains('door')) {
      return const Icon(Icons.door_front_door, size: 20);
    }
    if (field.key.contains('power')) {
      return const Icon(Icons.power, size: 20);
    }
    if (field.key.contains('temperature')) {
      return const Icon(Icons.thermostat, size: 20);
    }
    return const Icon(Icons.edit, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: localization.translate(field.labelKey),
        hintText: _getHintForField(),
        suffixText: _getUnitForField(),
        helperText:
            field.defaultValue != 0 ? 'По умолчанию: ${field.defaultValue}' : null,
        helperMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        prefixIcon: _getIconForField(),
        errorMaxLines: 2,
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        if (value.contains(',')) {
          final newValue = value.replaceAll(',', '.');
          controller.value = TextEditingValue(
            text: newValue,
            selection: TextSelection.collapsed(
              offset: newValue.length,
            ),
          );
        }
      },
      validator: (value) =>
          CalculatorInputValidator.validate(value, field, localization),
    );
  }
}
