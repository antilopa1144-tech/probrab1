import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/validation/field_validator.dart';
import 'package:probrab_ai/domain/models/calculator_field.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';

void main() {
  group('FieldValidator', () {
    group('validate', () {
      test('returns null for valid required field', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: true,
          minValue: 1,
          maxValue: 100,
        );

        final error = FieldValidator.validate(field, 50.0);
        expect(error, isNull);
      });

      test('returns error for missing required field', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: true,
        );

        final error = FieldValidator.validate(field, null);
        expect(error, isNotNull);
        expect(error?.code, equals('REQUIRED_FIELD'));
        expect(error?.fieldName, equals('area'));
      });

      test('returns null for missing optional field', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: false,
        );

        final error = FieldValidator.validate(field, null);
        expect(error, isNull);
      });

      test('returns error for negative value when minValue >= 0', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          minValue: 0,
        );

        final error = FieldValidator.validate(field, -5.0);
        expect(error, isNotNull);
        expect(error?.code, equals('NEGATIVE_VALUE'));
        expect(error?.invalidValue, equals(-5.0));
      });

      test('returns error for value below minValue', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          minValue: 10,
        );

        final error = FieldValidator.validate(field, 5.0);
        expect(error, isNotNull);
        expect(error?.code, equals('MIN_VALUE'));
        expect(error?.details?['min'], equals(10));
        expect(error?.details?['actual'], equals(5.0));
      });

      test('returns error for value above maxValue', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          maxValue: 100,
        );

        final error = FieldValidator.validate(field, 150.0);
        expect(error, isNotNull);
        expect(error?.code, equals('MAX_VALUE'));
        expect(error?.details?['max'], equals(100));
        expect(error?.details?['actual'], equals(150.0));
      });

      test('allows negative values when minValue is negative', () {
        const field = CalculatorField(
          key: 'temperature',
          labelKey: 'temperature',
          unitType: UnitType.pieces,
          minValue: -10,
        );

        final error = FieldValidator.validate(field, -5.0);
        expect(error, isNull);
      });

      test('validates boundary values correctly', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          minValue: 10,
          maxValue: 100,
        );

        expect(FieldValidator.validate(field, 10.0), isNull);
        expect(FieldValidator.validate(field, 100.0), isNull);
        expect(FieldValidator.validate(field, 9.9), isNotNull);
        expect(FieldValidator.validate(field, 100.1), isNotNull);
      });
    });

    group('validateAll', () {
      final fields = [
        const CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: true,
          minValue: 1,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'height',
          unitType: UnitType.meters,
          required: false,
          maxValue: 10,
        ),
        const CalculatorField(
          key: 'width',
          labelKey: 'width',
          unitType: UnitType.meters,
          required: true,
        ),
      ];

      test('returns empty list for valid inputs', () {
        final inputs = {'area': 50.0, 'height': 3.0, 'width': 10.0};
        final errors = FieldValidator.validateAll(fields, inputs);
        expect(errors, isEmpty);
      });

      test('returns errors for invalid inputs', () {
        final inputs = {'area': 0.5, 'height': 15.0};
        final errors = FieldValidator.validateAll(fields, inputs);

        expect(errors.length, equals(3));
        expect(errors[0].code, equals('MIN_VALUE')); // area < 1
        expect(errors[1].code, equals('MAX_VALUE')); // height > 10
        expect(errors[2].code, equals('REQUIRED_FIELD')); // width missing
      });

      test('handles missing optional fields', () {
        final inputs = {'area': 50.0, 'width': 10.0};
        final errors = FieldValidator.validateAll(fields, inputs);
        expect(errors, isEmpty);
      });
    });

    group('validateByKey', () {
      final fields = [
        const CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          minValue: 1,
          maxValue: 100,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'height',
          unitType: UnitType.meters,
        ),
      ];

      test('validates existing field by key', () {
        final error = FieldValidator.validateByKey(fields, 'area', 150.0);
        expect(error, isNotNull);
        expect(error?.code, equals('MAX_VALUE'));
      });

      test('returns null for non-existent field key', () {
        final error = FieldValidator.validateByKey(fields, 'nonexistent', 50.0);
        expect(error, isNull);
      });

      test('validates field with valid value', () {
        final error = FieldValidator.validateByKey(fields, 'area', 50.0);
        expect(error, isNull);
      });
    });

    group('areRequiredFieldsFilled', () {
      final fields = [
        const CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: true,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'height',
          unitType: UnitType.meters,
          required: false,
        ),
        const CalculatorField(
          key: 'width',
          labelKey: 'width',
          unitType: UnitType.meters,
          required: true,
        ),
      ];

      test('returns true when all required fields present', () {
        final inputs = {'area': 50.0, 'width': 10.0};
        expect(FieldValidator.areRequiredFieldsFilled(fields, inputs), isTrue);
      });

      test('returns false when required field missing', () {
        final inputs = {'area': 50.0};
        expect(FieldValidator.areRequiredFieldsFilled(fields, inputs), isFalse);
      });

      test('ignores optional fields', () {
        final inputs = {'area': 50.0, 'width': 10.0, 'height': 3.0};
        expect(FieldValidator.areRequiredFieldsFilled(fields, inputs), isTrue);
      });
    });

    group('getMissingRequiredFields', () {
      final fields = [
        const CalculatorField(
          key: 'area',
          labelKey: 'area',
          unitType: UnitType.squareMeters,
          required: true,
        ),
        const CalculatorField(
          key: 'height',
          labelKey: 'height',
          unitType: UnitType.meters,
          required: false,
        ),
        const CalculatorField(
          key: 'width',
          labelKey: 'width',
          unitType: UnitType.meters,
          required: true,
        ),
      ];

      test('returns empty list when all required fields present', () {
        final inputs = {'area': 50.0, 'width': 10.0};
        final missing = FieldValidator.getMissingRequiredFields(fields, inputs);
        expect(missing, isEmpty);
      });

      test('returns missing required field keys', () {
        final inputs = {'area': 50.0};
        final missing = FieldValidator.getMissingRequiredFields(fields, inputs);
        expect(missing, equals(['width']));
      });

      test('returns all missing required fields', () {
        final inputs = <String, double>{};
        final missing = FieldValidator.getMissingRequiredFields(fields, inputs);
        expect(missing, equals(['area', 'width']));
      });

      test('ignores optional fields', () {
        final inputs = {'area': 50.0, 'width': 10.0};
        final missing = FieldValidator.getMissingRequiredFields(fields, inputs);
        expect(missing, isNot(contains('height')));
      });
    });

    group('validateLogical', () {
      test('returns error for area > 10000', () {
        final inputs = {'area': 15000.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.fieldName, equals('area'));
      });

      test('returns error for volume > 1000', () {
        final inputs = {'volume': 1500.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.fieldName, equals('volume'));
      });

      test('returns error when length >> width', () {
        final inputs = {'length': 100.0, 'width': 5.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.message, contains('Длина'));
      });

      test('returns error when width >> length', () {
        final inputs = {'length': 5.0, 'width': 100.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.message, contains('Ширина'));
      });

      test('returns error for thickness > 500', () {
        final inputs = {'thickness': 600.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.fieldName, equals('thickness'));
      });

      test('returns error for very small thickness', () {
        final inputs = {'thickness': 0.05};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.fieldName, equals('thickness'));
      });

      test('returns error for height > 10', () {
        final inputs = {'height': 15.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.fieldName, equals('height'));
      });

      test('returns error for perimeter too small for area', () {
        final inputs = {'area': 100.0, 'perimeter': 10.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
        expect(error?.message, contains('Периметр'));
      });

      test('returns null for valid inputs', () {
        final inputs = {'area': 50.0, 'length': 10.0, 'width': 5.0, 'height': 3.0};
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNull);
      });
    });

    group('validateConsumption', () {
      test('returns error for excessive paint consumption', () {
        final error = FieldValidator.validateConsumption(
          55.0, // consumption (1.1 л/м² > 1.0 threshold)
          50.0, // area
          'paint',
        );
        expect(error, isNotNull);
        expect(error?.message, contains('краски'));
      });

      test('returns error for excessive primer consumption', () {
        final error = FieldValidator.validateConsumption(
          30.0,
          50.0,
          'primer',
        );
        expect(error, isNotNull);
        expect(error?.message, contains('грунтовки'));
      });

      test('returns error for excessive plaster consumption', () {
        final error = FieldValidator.validateConsumption(
          1500.0,
          50.0,
          'plaster',
        );
        expect(error, isNotNull);
        expect(error?.message, contains('штукатурки'));
      });

      test('returns null for normal paint consumption', () {
        final error = FieldValidator.validateConsumption(
          5.0, // 0.1 л/м²
          50.0,
          'paint',
        );
        expect(error, isNull);
      });

      test('returns null for normal primer consumption', () {
        final error = FieldValidator.validateConsumption(
          5.0, // 0.1 л/м²
          50.0,
          'primer',
        );
        expect(error, isNull);
      });

      test('returns null for normal plaster consumption', () {
        final error = FieldValidator.validateConsumption(
          500.0, // 10 кг/м²
          50.0,
          'plaster',
        );
        expect(error, isNull);
      });
    });

    group('sqrt extension', () {
      test('calculates square root correctly', () {
        final inputs = {'area': 100.0, 'perimeter': 35.0};
        // For square: P = 4√A = 4*10 = 40
        // 35 < 40 * 0.9 = 36, so should give error
        final error = FieldValidator.validateLogical(inputs);
        expect(error, isNotNull);
      });

      test('handles zero area', () {
        final inputs = {'area': 0.0, 'perimeter': 10.0};
        final error = FieldValidator.validateLogical(inputs);
        // sqrt(0) = 0, minPerimeter = 0, so perimeter > 0 is valid
        // This is an edge case where validation passes
        expect(error, isNull);
      });
    });
  });
}
// ignore_for_file: avoid_dynamic_calls
