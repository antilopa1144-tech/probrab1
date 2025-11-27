import 'package:flutter/material.dart';

import '../../domain/calculators/definitions.dart';
import 'number_parser.dart';

/// Provides UI metadata (units, helper text, icons) for calculator inputs.
class InputFieldMetadata {
  final String? unit;
  final String? helperText;
  final IconData? icon;

  const InputFieldMetadata({
    this.unit,
    this.helperText,
    this.icon,
  });

  static InputFieldMetadata fromField(InputFieldDefinition field) {
    final key = field.key.toLowerCase();
    final unit = _unitForKey(key);
    final helper = _helperText(field, unit);
    final icon = _iconForKey(key);

    return InputFieldMetadata(
      unit: unit,
      helperText: helper,
      icon: icon,
    );
  }

  static String? _unitForKey(String key) {
    if (key.contains('area')) return 'м²';
    if (key.contains('volume')) return 'м³';
    if (key.contains('thickness') ||
        key.contains('joint') ||
        key.contains('gap') ||
        key.contains('layer')) {
      return 'мм';
    }
    if (key.contains('width') ||
        key.contains('length') ||
        key.contains('height') ||
        key.contains('perimeter') ||
        key.contains('diameter') ||
        key.contains('radius') ||
        key.contains('depth')) {
      return 'м';
    }
    if (key.contains('power')) return 'Вт';
    if (key.contains('slope') && key.contains('angle')) return '°';
    if (key.contains('consumption')) return 'кг/м²';
    if (key.contains('density')) return 'кг/м³';
    if (key.contains('weight')) return 'кг';
    if (key.contains('temperature')) return '°C';
    if (key.contains('rooms') ||
        key.contains('windows') ||
        key.contains('doors') ||
        key.contains('layers') ||
        key.contains('corners') ||
        key.contains('fixtures') ||
        key.contains('thermostats') ||
        key.contains('sheets') ||
        key.contains('rolls') ||
        key.contains('packs') ||
        key.contains('points')) {
      return 'шт';
    }
    return null;
  }

  static IconData? _iconForKey(String key) {
    if (key.contains('area')) return Icons.square_foot_outlined;
    if (key.contains('volume')) return Icons.inventory_2_outlined;
    if (key.contains('perimeter') || key.contains('length')) {
      return Icons.straighten;
    }
    if (key.contains('height')) return Icons.height;
    if (key.contains('width')) return Icons.swap_horiz;
    if (key.contains('thickness') || key.contains('layer')) {
      return Icons.unfold_more;
    }
    if (key.contains('power')) return Icons.flash_on;
    if (key.contains('temperature')) return Icons.thermostat;
    if (key.contains('rooms') || key.contains('points')) {
      return Icons.meeting_room_outlined;
    }
    if (key.contains('windows') || key.contains('doors')) {
      return Icons.window;
    }
    return null;
  }

  static String? _helperText(InputFieldDefinition field, String? unit) {
    final parts = <String>[];

    if (field.minValue != null && field.maxValue != null) {
      parts.add(
        '${NumberParser.format(field.minValue!)}–${NumberParser.format(field.maxValue!)}${unit ?? ''}',
      );
    } else if (field.minValue != null) {
      parts.add('≥ ${NumberParser.format(field.minValue!)}${unit ?? ''}');
    } else if (field.maxValue != null) {
      parts.add('≤ ${NumberParser.format(field.maxValue!)}${unit ?? ''}');
    }

    if (field.defaultValue != 0) {
      parts.add('◎ ${NumberParser.format(field.defaultValue)}${unit ?? ''}');
    }

    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
