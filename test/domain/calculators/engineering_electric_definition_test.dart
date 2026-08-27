import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/field_input_type.dart';
import 'package:probrab_ai/domain/calculators/definitions/engineering_calculators.dart';

void main() {
  test('engineering_electrics публикует canonical v3 input-контракт', () {
    final definition = engineeringCalculators.singleWhere(
      (calculator) => calculator.id == 'engineering_electrics',
    );

    expect(definition.fields.map((field) => field.key).toList(), [
      'apartmentArea',
      'roomsCount',
      'ceilingHeight',
      'wiringType',
      'hasKitchen',
      'cablePurchaseMode',
      'reserve',
    ]);

    final defaults = {
      for (final field in definition.fields) field.key: field.defaultValue,
    };
    expect(defaults, {
      'apartmentArea': 60,
      'roomsCount': 3,
      'ceilingHeight': 2.7,
      'wiringType': 0,
      'hasKitchen': 1,
      'cablePurchaseMode': 0,
      'reserve': 15,
    });

    final purchaseMode = definition.fields.singleWhere(
      (field) => field.key == 'cablePurchaseMode',
    );
    expect(purchaseMode.inputType, FieldInputType.select);
    expect(purchaseMode.options?.map((option) => option.value), [0, 1]);
  });
}
