import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/validation/calculator_input_validator.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/domain/calculators/definitions.dart';
import 'package:flutter/material.dart';

// Mock AppLocalizations
class MockAppLocalizations extends AppLocalizations {
  MockAppLocalizations() : super(const Locale('ru'));

  @override
  String translate(String key) {
    final translations = {
      'input.required': 'Это поле обязательно',
      'input.invalid_number': 'Введите корректное число',
      'input.positive_number': 'Введите положительное число',
      'input.cannot_be_zero': 'Значение должно быть больше нуля',
      'input.min_value': 'Минимальное значение',
      'input.max_value': 'Максимальное значение',
      'input.area_too_large': 'Проверьте значение. Слишком большое число для площади (макс. ${CalculatorInputValidator.maxArea} м²)',
      'input.volume_too_large': 'Проверьте значение. Слишком большое число для объёма (макс. ${CalculatorInputValidator.maxVolume} м³)',
      'input.height_too_large': 'Проверьте значение. Слишком большая высота (макс. ${CalculatorInputValidator.maxHeight} м)',
      'input.thickness_too_large': 'Проверьте значение. Слишком большая толщина (макс. ${CalculatorInputValidator.maxThickness} мм)',
      'input.width_too_large': 'Проверьте значение. Слишком большая ширина (макс. ${CalculatorInputValidator.maxWidth} м)',
      'input.perimeter_too_large': 'Проверьте значение. Слишком большой периметр (макс. ${CalculatorInputValidator.maxPerimeter} м)',
    };
    return translations[key] ?? key;
  }
}

void main() {
  late AppLocalizations loc;

  setUp(() {
    loc = MockAppLocalizations();
  });

  group('CalculatorInputValidator', () {
    group('validate - required field', () {
      test('returns error for empty required field', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate('', field, loc);
        expect(error, equals('Это поле обязательно'));
      });

      test('returns error for null required field', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate(null, field, loc);
        expect(error, equals('Это поле обязательно'));
      });

      test('returns null for empty optional field', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: false,
        );

        final error = CalculatorInputValidator.validate('', field, loc);
        expect(error, isNull);
      });
    });

    group('validate - number parsing', () {
      test('returns error for non-numeric input', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate('abc', field, loc);
        expect(error, equals('Введите корректное число'));
      });

      test('accepts numeric input with comma', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('12,5', field, loc);
        expect(error, isNull);
      });

      test('accepts numeric input with dot', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('12.5', field, loc);
        expect(error, isNull);
      });
    });

    group('validate - negative values', () {
      test('returns error for negative value', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate('-5', field, loc);
        expect(error, equals('Введите положительное число'));
      });
    });

    group('validate - zero values', () {
      test('returns error for zero in required field (non-rapport/windows/doors)', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate('0', field, loc);
        expect(error, equals('Значение должно быть больше нуля'));
      });

      test('allows zero for rapport fields', () {
        const field = InputFieldDefinition(
          key: 'rapport_height',
          labelKey: 'input.rapport_height',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('0', field, loc);
        expect(error, isNull);
      });

      test('allows zero for windows fields', () {
        const field = InputFieldDefinition(
          key: 'windows_area',
          labelKey: 'input.windows_area',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('0', field, loc);
        expect(error, isNull);
      });

      test('allows zero for doors fields', () {
        const field = InputFieldDefinition(
          key: 'doors_area',
          labelKey: 'input.doors_area',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('0', field, loc);
        expect(error, isNull);
      });
    });

    group('validate - min/max values', () {
      test('returns error for value below minValue', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          minValue: 10,
        );

        final error = CalculatorInputValidator.validate('5', field, loc);
        expect(error, equals('Минимальное значение: 10.0'));
      });

      test('returns error for value above maxValue', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          maxValue: 100,
        );

        final error = CalculatorInputValidator.validate('150', field, loc);
        expect(error, equals('Максимальное значение: 100.0'));
      });

      test('accepts value at minValue boundary', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          minValue: 10,
        );

        final error = CalculatorInputValidator.validate('10', field, loc);
        expect(error, isNull);
      });

      test('accepts value at maxValue boundary', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          maxValue: 100,
        );

        final error = CalculatorInputValidator.validate('100', field, loc);
        expect(error, isNull);
      });
    });

    group('validate - special field limits', () {
      test('returns error for area above maxArea', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
        );

        final error = CalculatorInputValidator.validate('15000', field, loc);
        expect(error, contains('площади'));
        expect(error, contains('10000'));
      });

      test('returns error for volume above maxVolume', () {
        const field = InputFieldDefinition(
          key: 'volume',
          labelKey: 'input.volume',
          required: true,
        );

        final error = CalculatorInputValidator.validate('1500', field, loc);
        expect(error, contains('объёма'));
        expect(error, contains('1000'));
      });

      test('returns error for height above maxHeight', () {
        const field = InputFieldDefinition(
          key: 'height',
          labelKey: 'input.height',
          required: true,
        );

        final error = CalculatorInputValidator.validate('15', field, loc);
        expect(error, contains('высота'));
        expect(error, contains('10'));
      });

      test('returns error for thickness above maxThickness', () {
        const field = InputFieldDefinition(
          key: 'thickness',
          labelKey: 'input.thickness',
          required: true,
        );

        final error = CalculatorInputValidator.validate('600', field, loc);
        expect(error, contains('толщина'));
        expect(error, contains('500'));
      });

      test('returns error for width above maxWidth (non-tile/panel)', () {
        const field = InputFieldDefinition(
          key: 'width',
          labelKey: 'input.width',
          required: true,
        );

        final error = CalculatorInputValidator.validate('150', field, loc);
        expect(error, contains('ширина'));
        expect(error, contains('100'));
      });

      test('allows large width for tile fields', () {
        const field = InputFieldDefinition(
          key: 'tile_width',
          labelKey: 'input.tile_width',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('150', field, loc);
        expect(error, isNull);
      });

      test('allows large width for panel fields', () {
        const field = InputFieldDefinition(
          key: 'panel_width',
          labelKey: 'input.panel_width',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('150', field, loc);
        expect(error, isNull);
      });

      test('returns error for perimeter above maxPerimeter', () {
        const field = InputFieldDefinition(
          key: 'perimeter',
          labelKey: 'input.perimeter',
          required: true,
        );

        final error = CalculatorInputValidator.validate('1500', field, loc);
        expect(error, contains('периметр'));
        expect(error, contains('1000'));
      });
    });

    group('validate - whitespace handling', () {
      test('trims whitespace from input', () {
        const field = InputFieldDefinition(
          key: 'area',
          labelKey: 'input.area',
          required: true,
          minValue: 0,
        );

        final error = CalculatorInputValidator.validate('  50  ', field, loc);
        expect(error, isNull);
      });
    });
  });
}
