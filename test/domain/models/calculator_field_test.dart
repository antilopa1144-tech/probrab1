import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_field.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';
import 'package:probrab_ai/core/enums/field_input_type.dart';

void main() {
  group('FieldOption', () {
    test('creates with required parameters', () {
      const option = FieldOption(
        value: 10.0,
        labelKey: 'option.label',
      );

      expect(option.value, 10.0);
      expect(option.labelKey, 'option.label');
      expect(option.descriptionKey, isNull);
    });

    test('creates with all parameters', () {
      const option = FieldOption(
        value: 20.0,
        labelKey: 'option.label',
        descriptionKey: 'option.description',
      );

      expect(option.value, 20.0);
      expect(option.labelKey, 'option.label');
      expect(option.descriptionKey, 'option.description');
    });
  });

  group('DependencyCondition', () {
    test('has all expected values', () {
      expect(DependencyCondition.values, contains(DependencyCondition.equals));
      expect(
        DependencyCondition.values,
        contains(DependencyCondition.greaterThan),
      );
      expect(
        DependencyCondition.values,
        contains(DependencyCondition.lessThan),
      );
      expect(
        DependencyCondition.values,
        contains(DependencyCondition.greaterOrEqual),
      );
      expect(
        DependencyCondition.values,
        contains(DependencyCondition.lessOrEqual),
      );
      expect(
        DependencyCondition.values,
        contains(DependencyCondition.notEquals),
      );
    });

    test('has exactly 6 values', () {
      expect(DependencyCondition.values.length, 6);
    });
  });

  group('FieldDependency', () {
    test('creates with required parameters', () {
      const dep = FieldDependency(
        fieldKey: 'mode',
        condition: DependencyCondition.equals,
        value: 1.0,
      );

      expect(dep.fieldKey, 'mode');
      expect(dep.condition, DependencyCondition.equals);
      expect(dep.value, 1.0);
    });

    group('isSatisfied', () {
      test('returns false when field is missing', () {
        const dep = FieldDependency(
          fieldKey: 'mode',
          condition: DependencyCondition.equals,
          value: 1.0,
        );

        expect(dep.isSatisfied({}), isFalse);
        expect(dep.isSatisfied({'other': 1.0}), isFalse);
      });

      test('equals condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'mode',
          condition: DependencyCondition.equals,
          value: 1.0,
        );

        expect(dep.isSatisfied({'mode': 1.0}), isTrue);
        expect(dep.isSatisfied({'mode': 2.0}), isFalse);
      });

      test('notEquals condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'mode',
          condition: DependencyCondition.notEquals,
          value: 1.0,
        );

        expect(dep.isSatisfied({'mode': 2.0}), isTrue);
        expect(dep.isSatisfied({'mode': 1.0}), isFalse);
      });

      test('greaterThan condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'area',
          condition: DependencyCondition.greaterThan,
          value: 10.0,
        );

        expect(dep.isSatisfied({'area': 15.0}), isTrue);
        expect(dep.isSatisfied({'area': 10.0}), isFalse);
        expect(dep.isSatisfied({'area': 5.0}), isFalse);
      });

      test('lessThan condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'area',
          condition: DependencyCondition.lessThan,
          value: 10.0,
        );

        expect(dep.isSatisfied({'area': 5.0}), isTrue);
        expect(dep.isSatisfied({'area': 10.0}), isFalse);
        expect(dep.isSatisfied({'area': 15.0}), isFalse);
      });

      test('greaterOrEqual condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'area',
          condition: DependencyCondition.greaterOrEqual,
          value: 10.0,
        );

        expect(dep.isSatisfied({'area': 15.0}), isTrue);
        expect(dep.isSatisfied({'area': 10.0}), isTrue);
        expect(dep.isSatisfied({'area': 5.0}), isFalse);
      });

      test('lessOrEqual condition works correctly', () {
        const dep = FieldDependency(
          fieldKey: 'area',
          condition: DependencyCondition.lessOrEqual,
          value: 10.0,
        );

        expect(dep.isSatisfied({'area': 5.0}), isTrue);
        expect(dep.isSatisfied({'area': 10.0}), isTrue);
        expect(dep.isSatisfied({'area': 15.0}), isFalse);
      });
    });
  });

  group('CalculatorField', () {
    test('creates with required parameters', () {
      const field = CalculatorField(
        key: 'area',
        labelKey: 'input.area',
        unitType: UnitType.squareMeters,
      );

      expect(field.key, 'area');
      expect(field.labelKey, 'input.area');
      expect(field.unitType, UnitType.squareMeters);
    });

    test('uses default values for optional parameters', () {
      const field = CalculatorField(
        key: 'area',
        labelKey: 'input.area',
        unitType: UnitType.squareMeters,
      );

      expect(field.hintKey, isNull);
      expect(field.inputType, FieldInputType.number);
      expect(field.defaultValue, 0.0);
      expect(field.minValue, isNull);
      expect(field.maxValue, isNull);
      expect(field.required, isTrue);
      expect(field.step, isNull);
      expect(field.iconName, isNull);
      expect(field.group, isNull);
      expect(field.order, 0);
      expect(field.dependency, isNull);
      expect(field.dependencies, isNull);
      expect(field.options, isNull);
    });

    test('creates with all parameters', () {
      const field = CalculatorField(
        key: 'area',
        labelKey: 'input.area',
        hintKey: 'hint.area',
        unitType: UnitType.squareMeters,
        inputType: FieldInputType.slider,
        defaultValue: 10.0,
        minValue: 1.0,
        maxValue: 100.0,
        required: false,
        step: 0.5,
        iconName: 'area_icon',
        group: 'dimensions',
        order: 1,
      );

      expect(field.key, 'area');
      expect(field.hintKey, 'hint.area');
      expect(field.inputType, FieldInputType.slider);
      expect(field.defaultValue, 10.0);
      expect(field.minValue, 1.0);
      expect(field.maxValue, 100.0);
      expect(field.required, isFalse);
      expect(field.step, 0.5);
      expect(field.iconName, 'area_icon');
      expect(field.group, 'dimensions');
      expect(field.order, 1);
    });

    group('shouldDisplay', () {
      test('returns true when no dependencies', () {
        const field = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
        );

        expect(field.shouldDisplay({}), isTrue);
        expect(field.shouldDisplay({'mode': 1.0}), isTrue);
      });

      test('checks single dependency', () {
        const field = CalculatorField(
          key: 'length',
          labelKey: 'input.length',
          unitType: UnitType.meters,
          dependency: FieldDependency(
            fieldKey: 'mode',
            condition: DependencyCondition.equals,
            value: 1.0,
          ),
        );

        expect(field.shouldDisplay({'mode': 1.0}), isTrue);
        expect(field.shouldDisplay({'mode': 2.0}), isFalse);
        expect(field.shouldDisplay({}), isFalse);
      });

      test('checks multiple dependencies with AND logic', () {
        const field = CalculatorField(
          key: 'length',
          labelKey: 'input.length',
          unitType: UnitType.meters,
          dependencies: [
            FieldDependency(
              fieldKey: 'mode',
              condition: DependencyCondition.equals,
              value: 1.0,
            ),
            FieldDependency(
              fieldKey: 'type',
              condition: DependencyCondition.greaterThan,
              value: 0.0,
            ),
          ],
        );

        expect(field.shouldDisplay({'mode': 1.0, 'type': 1.0}), isTrue);
        expect(field.shouldDisplay({'mode': 1.0, 'type': 0.0}), isFalse);
        expect(field.shouldDisplay({'mode': 2.0, 'type': 1.0}), isFalse);
        expect(field.shouldDisplay({'mode': 1.0}), isFalse);
      });

      test('multiple dependencies take precedence over single dependency', () {
        const field = CalculatorField(
          key: 'length',
          labelKey: 'input.length',
          unitType: UnitType.meters,
          dependency: FieldDependency(
            fieldKey: 'single',
            condition: DependencyCondition.equals,
            value: 1.0,
          ),
          dependencies: [
            FieldDependency(
              fieldKey: 'multi',
              condition: DependencyCondition.equals,
              value: 2.0,
            ),
          ],
        );

        // Multiple dependencies take precedence
        expect(field.shouldDisplay({'multi': 2.0}), isTrue);
        expect(field.shouldDisplay({'single': 1.0}), isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with same values when no changes', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          defaultValue: 10.0,
          order: 1,
        );

        final copy = original.copyWith();

        expect(copy.key, original.key);
        expect(copy.labelKey, original.labelKey);
        expect(copy.unitType, original.unitType);
        expect(copy.defaultValue, original.defaultValue);
        expect(copy.order, original.order);
      });

      test('creates copy with changed key', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
        );

        final copy = original.copyWith(key: 'new_area');

        expect(copy.key, 'new_area');
        expect(copy.labelKey, original.labelKey);
      });

      test('creates copy with changed labelKey', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
        );

        final copy = original.copyWith(labelKey: 'input.new_area');

        expect(copy.key, original.key);
        expect(copy.labelKey, 'input.new_area');
      });

      test('creates copy with changed unitType', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
        );

        final copy = original.copyWith(unitType: UnitType.meters);

        expect(copy.unitType, UnitType.meters);
      });

      test('creates copy with changed numeric values', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          defaultValue: 10.0,
          minValue: 0.0,
          maxValue: 100.0,
        );

        final copy = original.copyWith(
          defaultValue: 20.0,
          minValue: 5.0,
          maxValue: 200.0,
        );

        expect(copy.defaultValue, 20.0);
        expect(copy.minValue, 5.0);
        expect(copy.maxValue, 200.0);
      });

      test('creates copy with changed order', () {
        const original = CalculatorField(
          key: 'area',
          labelKey: 'input.area',
          unitType: UnitType.squareMeters,
          order: 1,
        );

        final copy = original.copyWith(order: 5);

        expect(copy.order, 5);
      });

      test('creates copy with options', () {
        const original = CalculatorField(
          key: 'mode',
          labelKey: 'input.mode',
          unitType: UnitType.pieces,
          inputType: FieldInputType.select,
        );

        const options = [
          FieldOption(value: 1.0, labelKey: 'option.one'),
          FieldOption(value: 2.0, labelKey: 'option.two'),
        ];

        final copy = original.copyWith(options: options);

        expect(copy.options, isNotNull);
        expect(copy.options!.length, 2);
        expect(copy.options![0].value, 1.0);
      });
    });
  });
}
