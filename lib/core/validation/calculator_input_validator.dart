import '../localization/app_localizations.dart';
import '../../domain/calculators/definitions.dart';

/// Общий валидатор для полей калькуляторов.
class CalculatorInputValidator {
  static const double maxArea = 10000;
  static const double maxVolume = 1000;
  static const double maxHeight = 10;
  static const double maxThickness = 500;
  static const double maxWidth = 100;
  static const double maxPerimeter = 1000;

  static String? validate(
    String? value,
    InputFieldDefinition field,
    AppLocalizations loc,
  ) {
    final rawValue = value?.trim() ?? '';

    if (field.required && rawValue.isEmpty) {
      return loc.translate('input.required') ?? 'Это поле обязательно';
    }

    if (!field.required && rawValue.isEmpty) {
      return null;
    }

    final sanitizedValue = rawValue.replaceAll(',', '.');
    final numValue = double.tryParse(sanitizedValue);
    if (numValue == null) {
      return loc.translate('input.invalid_number') ?? 'Введите корректное число';
    }

    if (numValue < 0) {
      return loc.translate('input.positive_number') ?? 'Введите положительное число';
    }

    if (field.required &&
        numValue == 0 &&
        !field.key.contains('rapport') &&
        !field.key.contains('windows') &&
        !field.key.contains('doors')) {
      return loc.translate('input.cannot_be_zero') ??
          'Значение должно быть больше нуля';
    }

    if (field.minValue != null && numValue < field.minValue!) {
      return '${loc.translate('input.min_value') ?? 'Минимальное значение'}: ${field.minValue}';
    }

    if (field.maxValue != null && numValue > field.maxValue!) {
      return '${loc.translate('input.max_value') ?? 'Максимальное значение'}: ${field.maxValue}';
    }

    if (field.key.contains('area') && numValue > maxArea) {
      return loc.translate('input.area_too_large') ??
          'Проверьте значение. Слишком большое число для площади (макс. $maxArea м²)';
    }

    if (field.key.contains('volume') && numValue > maxVolume) {
      return loc.translate('input.volume_too_large') ??
          'Проверьте значение. Слишком большое число для объёма (макс. $maxVolume м³)';
    }

    if (field.key.contains('height') && numValue > maxHeight) {
      return loc.translate('input.height_too_large') ??
          'Проверьте значение. Слишком большая высота (макс. $maxHeight м)';
    }

    if (field.key.contains('thickness') && numValue > maxThickness) {
      return loc.translate('input.thickness_too_large') ??
          'Проверьте значение. Слишком большая толщина (макс. $maxThickness мм)';
    }

    if (field.key.contains('width') &&
        !field.key.contains('tile') &&
        !field.key.contains('panel') &&
        numValue > maxWidth) {
      return loc.translate('input.width_too_large') ??
          'Проверьте значение. Слишком большая ширина (макс. $maxWidth м)';
    }

    if (field.key.contains('perimeter') && numValue > maxPerimeter) {
      return loc.translate('input.perimeter_too_large') ??
          'Проверьте значение. Слишком большой периметр (макс. $maxPerimeter м)';
    }

    return null;
  }
}
