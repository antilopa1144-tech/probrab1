import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/field_input_type.dart';

void main() {
  group('FieldInputType', () {
    test('has all expected values', () {
      expect(FieldInputType.values, contains(FieldInputType.number));
      expect(FieldInputType.values, contains(FieldInputType.select));
      expect(FieldInputType.values, contains(FieldInputType.checkbox));
      expect(FieldInputType.values, contains(FieldInputType.switch_));
      expect(FieldInputType.values, contains(FieldInputType.radio));
      expect(FieldInputType.values, contains(FieldInputType.slider));
    });

    test('has exactly 6 values', () {
      expect(FieldInputType.values.length, 6);
    });

    test('number is the default type for numeric input', () {
      expect(FieldInputType.number.name, 'number');
    });

    test('select is for dropdown lists', () {
      expect(FieldInputType.select.name, 'select');
    });

    test('checkbox is for boolean toggles', () {
      expect(FieldInputType.checkbox.name, 'checkbox');
    });

    test('switch_ is for switch toggles', () {
      expect(FieldInputType.switch_.name, 'switch_');
    });

    test('radio is for radio button groups', () {
      expect(FieldInputType.radio.name, 'radio');
    });

    test('slider is for range selection', () {
      expect(FieldInputType.slider.name, 'slider');
    });

    test('all values have unique indices', () {
      final indices = FieldInputType.values.map((e) => e.index).toSet();
      expect(indices.length, FieldInputType.values.length);
    });

    test('values are ordered correctly', () {
      expect(FieldInputType.number.index, 0);
      expect(FieldInputType.select.index, 1);
      expect(FieldInputType.checkbox.index, 2);
      expect(FieldInputType.switch_.index, 3);
      expect(FieldInputType.radio.index, 4);
      expect(FieldInputType.slider.index, 5);
    });
  });
}
