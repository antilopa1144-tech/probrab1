import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/unit_conversion.dart';

void main() {
  group('Unit', () {
    test('creates with required fields', () {
      const unit = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.id, 'meter');
      expect(unit.symbol, 'm');
      expect(unit.category, UnitCategory.length);
      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, false);
    });

    test('creates as base unit', () {
      const unit = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.isBase, true);
    });

    test('creates for area', () {
      const unit = Unit(
        id: 'square_meter',
        symbol: 'm2',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.area);
      expect(unit.symbol, 'm2');
    });

    test('creates for volume', () {
      const unit = Unit(
        id: 'cubic_meter',
        symbol: 'm3',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.volume);
      expect(unit.symbol, 'm3');
    });

    test('creates for weight', () {
      const unit = Unit(
        id: 'kilogram',
        symbol: 'kg',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.weight);
      expect(unit.symbol, 'kg');
    });

    test('creates for quantity', () {
      const unit = Unit(
        id: 'piece',
        symbol: 'pcs',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.quantity);
      expect(unit.symbol, 'pcs');
    });

    test('creates with conversion factor', () {
      const kilometer = Unit(
        id: 'kilometer',
        symbol: 'km',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(kilometer.toBaseUnit, 1000.0);
    });

    test('creates with fractional conversion factor', () {
      const centimeter = Unit(
        id: 'centimeter',
        symbol: 'cm',
        category: UnitCategory.length,
        toBaseUnit: 0.01,
      );

      expect(centimeter.toBaseUnit, 0.01);
    });

    test('toString returns symbol', () {
      const unit = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.toString(), 'm');
    });

    test('operator == compares by id', () {
      const unit1 = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'meter',
        symbol: 'metre',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit1, equals(unit2));
    });

    test('operator == returns false for different ids', () {
      const unit1 = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'kilometer',
        symbol: 'km',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit1, isNot(equals(unit2)));
    });

    test('operator == returns true for identical object', () {
      const unit = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit, equals(unit));
    });

    test('hashCode depends on id', () {
      const unit1 = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'meter',
        symbol: 'metre',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit1.hashCode, equals(unit2.hashCode));
    });

    test('hashCode differs for different ids', () {
      const unit1 = Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'kilometer',
        symbol: 'km',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit1.hashCode, isNot(equals(unit2.hashCode)));
    });
  });

  group('UnitCategory', () {
    test('has all required categories', () {
      expect(UnitCategory.values.length, 5);
      expect(UnitCategory.values, contains(UnitCategory.area));
      expect(UnitCategory.values, contains(UnitCategory.length));
      expect(UnitCategory.values, contains(UnitCategory.volume));
      expect(UnitCategory.values, contains(UnitCategory.weight));
      expect(UnitCategory.values, contains(UnitCategory.quantity));
    });
  });

  group('ConversionResult', () {
    late Unit meterUnit;
    late Unit kilometerUnit;
    late DateTime testTime;

    setUp(() {
      meterUnit = const Unit(
        id: 'meter',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
        isBase: true,
      );

      kilometerUnit = const Unit(
        id: 'kilometer',
        symbol: 'km',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      testTime = DateTime(2024, 1, 15, 10, 30);
    });

    test('creates with required fields', () {
      final result = ConversionResult(
        fromValue: 1000.0,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.fromValue, 1000.0);
      expect(result.fromUnit, meterUnit);
      expect(result.toValue, 1.0);
      expect(result.toUnit, kilometerUnit);
      expect(result.timestamp, testTime);
    });

    test('formatted returns readable string', () {
      final result = ConversionResult(
        fromValue: 1000.0,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000 m = 1 km');
    });

    test('formatted formats fractional values', () {
      const centimeter = Unit(
        id: 'centimeter',
        symbol: 'cm',
        category: UnitCategory.length,
        toBaseUnit: 0.01,
      );

      final result = ConversionResult(
        fromValue: 10.5,
        fromUnit: meterUnit,
        toValue: 1050.0,
        toUnit: centimeter,
        timestamp: testTime,
      );

      expect(result.formatted, '10.5 m = 1050 cm');
    });

    test('formatted rounds to 4 decimal places', () {
      final result = ConversionResult(
        fromValue: 1.23456789,
        fromUnit: meterUnit,
        toValue: 0.00123456789,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      final formatted = result.formatted;
      expect(formatted, contains('1.2346'));
      expect(formatted, contains('0.0012'));
    });

    test('formatted removes trailing zeros', () {
      final result = ConversionResult(
        fromValue: 1.5000,
        fromUnit: meterUnit,
        toValue: 0.0015,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      final formatted = result.formatted;
      expect(formatted, contains('1.5'));
      expect(formatted, contains('0.0015'));
      expect(formatted, isNot(contains('1.5000')));
    });

    test('formatted shows integers without decimal part', () {
      final result = ConversionResult(
        fromValue: 1000.0,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000 m = 1 km');
      expect(result.formatted, isNot(contains('1000.0')));
      expect(result.formatted, isNot(contains('1.0')));
    });

    test('toString returns formatted', () {
      final result = ConversionResult(
        fromValue: 500.0,
        fromUnit: meterUnit,
        toValue: 0.5,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.toString(), result.formatted);
      expect(result.toString(), '500 m = 0.5 km');
    });

    test('works with zero values', () {
      final result = ConversionResult(
        fromValue: 0.0,
        fromUnit: meterUnit,
        toValue: 0.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '0 m = 0 km');
    });

    test('works with very small values', () {
      const millimeter = Unit(
        id: 'millimeter',
        symbol: 'mm',
        category: UnitCategory.length,
        toBaseUnit: 0.001,
      );

      final result = ConversionResult(
        fromValue: 0.001,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: millimeter,
        timestamp: testTime,
      );

      expect(result.formatted, '0.001 m = 1 mm');
    });

    test('works with very large values', () {
      final result = ConversionResult(
        fromValue: 1000000.0,
        fromUnit: meterUnit,
        toValue: 1000.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000000 m = 1000 km');
    });

    test('works with negative values', () {
      final result = ConversionResult(
        fromValue: -100.0,
        fromUnit: meterUnit,
        toValue: -0.1,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '-100 m = -0.1 km');
    });
  });

  group('Unit - various length units', () {
    test('kilometer has factor 1000', () {
      const unit = Unit(
        id: 'kilometer',
        symbol: 'km',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit.toBaseUnit, 1000.0);
      expect(unit.category, UnitCategory.length);
    });

    test('centimeter has factor 0.01', () {
      const unit = Unit(
        id: 'centimeter',
        symbol: 'cm',
        category: UnitCategory.length,
        toBaseUnit: 0.01,
      );

      expect(unit.toBaseUnit, 0.01);
      expect(unit.category, UnitCategory.length);
    });

    test('millimeter has factor 0.001', () {
      const unit = Unit(
        id: 'millimeter',
        symbol: 'mm',
        category: UnitCategory.length,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.length);
    });
  });

  group('Unit - various area units', () {
    test('square meter is base unit', () {
      const unit = Unit(
        id: 'square_meter',
        symbol: 'm2',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.area);
    });

    test('square centimeter has factor 0.0001', () {
      const unit = Unit(
        id: 'square_centimeter',
        symbol: 'cm2',
        category: UnitCategory.area,
        toBaseUnit: 0.0001,
      );

      expect(unit.toBaseUnit, 0.0001);
      expect(unit.category, UnitCategory.area);
    });

    test('square kilometer has factor 1000000', () {
      const unit = Unit(
        id: 'square_kilometer',
        symbol: 'km2',
        category: UnitCategory.area,
        toBaseUnit: 1000000.0,
      );

      expect(unit.toBaseUnit, 1000000.0);
      expect(unit.category, UnitCategory.area);
    });
  });

  group('Unit - various volume units', () {
    test('cubic meter is base unit', () {
      const unit = Unit(
        id: 'cubic_meter',
        symbol: 'm3',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.volume);
    });

    test('liter has factor 0.001', () {
      const unit = Unit(
        id: 'liter',
        symbol: 'l',
        category: UnitCategory.volume,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.volume);
    });

    test('cubic centimeter has factor 0.000001', () {
      const unit = Unit(
        id: 'cubic_centimeter',
        symbol: 'cm3',
        category: UnitCategory.volume,
        toBaseUnit: 0.000001,
      );

      expect(unit.toBaseUnit, 0.000001);
      expect(unit.category, UnitCategory.volume);
    });
  });

  group('Unit - various weight units', () {
    test('kilogram is base unit', () {
      const unit = Unit(
        id: 'kilogram',
        symbol: 'kg',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.weight);
    });

    test('gram has factor 0.001', () {
      const unit = Unit(
        id: 'gram',
        symbol: 'g',
        category: UnitCategory.weight,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.weight);
    });

    test('ton has factor 1000', () {
      const unit = Unit(
        id: 'ton',
        symbol: 't',
        category: UnitCategory.weight,
        toBaseUnit: 1000.0,
      );

      expect(unit.toBaseUnit, 1000.0);
      expect(unit.category, UnitCategory.weight);
    });
  });

  group('Unit - various quantity units', () {
    test('piece is base unit', () {
      const unit = Unit(
        id: 'piece',
        symbol: 'pcs',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.quantity);
    });

    test('roll is quantity unit', () {
      const unit = Unit(
        id: 'roll',
        symbol: 'roll',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.category, UnitCategory.quantity);
    });

    test('pack is quantity unit', () {
      const unit = Unit(
        id: 'pack',
        symbol: 'pack',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.category, UnitCategory.quantity);
    });
  });

  group('ConversionResult - various categories', () {
    test('area conversion', () {
      const squareMeter = Unit(
        id: 'square_meter',
        symbol: 'm2',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
      );

      const squareCentimeter = Unit(
        id: 'square_centimeter',
        symbol: 'cm2',
        category: UnitCategory.area,
        toBaseUnit: 0.0001,
      );

      final result = ConversionResult(
        fromValue: 1.0,
        fromUnit: squareMeter,
        toValue: 10000.0,
        toUnit: squareCentimeter,
        timestamp: DateTime.now(),
      );

      expect(result.formatted, '1 m2 = 10000 cm2');
    });

    test('volume conversion', () {
      const cubicMeter = Unit(
        id: 'cubic_meter',
        symbol: 'm3',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
      );

      const liter = Unit(
        id: 'liter',
        symbol: 'l',
        category: UnitCategory.volume,
        toBaseUnit: 0.001,
      );

      final result = ConversionResult(
        fromValue: 1.0,
        fromUnit: cubicMeter,
        toValue: 1000.0,
        toUnit: liter,
        timestamp: DateTime.now(),
      );

      expect(result.formatted, '1 m3 = 1000 l');
    });

    test('weight conversion', () {
      const kilogram = Unit(
        id: 'kilogram',
        symbol: 'kg',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
      );

      const gram = Unit(
        id: 'gram',
        symbol: 'g',
        category: UnitCategory.weight,
        toBaseUnit: 0.001,
      );

      final result = ConversionResult(
        fromValue: 2.5,
        fromUnit: kilogram,
        toValue: 2500.0,
        toUnit: gram,
        timestamp: DateTime.now(),
      );

      expect(result.formatted, '2.5 kg = 2500 g');
    });
  });

  group('ConversionResult - formatting edge cases', () {
    late Unit testUnit1;
    late Unit testUnit2;

    setUp(() {
      testUnit1 = const Unit(
        id: 'unit1',
        symbol: 'u1',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      testUnit2 = const Unit(
        id: 'unit2',
        symbol: 'u2',
        category: UnitCategory.length,
        toBaseUnit: 0.1,
      );
    });

    test('formatting value 0.0', () {
      final result = ConversionResult(
        fromValue: 0.0,
        fromUnit: testUnit1,
        toValue: 0.0,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      expect(result.formatted, '0 u1 = 0 u2');
    });

    test('formatting very small value', () {
      final result = ConversionResult(
        fromValue: 0.00001,
        fromUnit: testUnit1,
        toValue: 0.0001,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, isNot(contains('.0000')));
    });

    test('formatting value with 5+ decimals rounds to 4', () {
      final result = ConversionResult(
        fromValue: 1.123456,
        fromUnit: testUnit1,
        toValue: 11.23456,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      // Rounded to 4 decimal places
      expect(formatted, contains('1.1235'));
      expect(formatted, contains('11.2346'));
    });

    test('formatting integer with .0', () {
      final result = ConversionResult(
        fromValue: 100.0,
        fromUnit: testUnit1,
        toValue: 1000.0,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '100 u1 = 1000 u2');
      expect(formatted, isNot(contains('.0')));
    });

    test('formatting removes trailing zeros after decimal point', () {
      final result = ConversionResult(
        fromValue: 1.2000,
        fromUnit: testUnit1,
        toValue: 12.3400,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '1.2 u1 = 12.34 u2');
      expect(formatted, isNot(contains('1.2000')));
      expect(formatted, isNot(contains('12.3400')));
    });

    test('formatting removes decimal point if all zeros after', () {
      final result = ConversionResult(
        fromValue: 5.0000,
        fromUnit: testUnit1,
        toValue: 50.0000,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '5 u1 = 50 u2');
      expect(formatted, isNot(contains('.')));
    });
  });

  group('Unit - edge cases', () {
    test('creates with empty symbol', () {
      const unit = Unit(
        id: 'empty_symbol',
        symbol: '',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.symbol, '');
      expect(unit.toString(), '');
    });

    test('creates with factor 0', () {
      const unit = Unit(
        id: 'zero_unit',
        symbol: 'z',
        category: UnitCategory.length,
        toBaseUnit: 0.0,
      );

      expect(unit.toBaseUnit, 0.0);
    });

    test('creates with negative factor', () {
      const unit = Unit(
        id: 'negative_unit',
        symbol: 'neg',
        category: UnitCategory.length,
        toBaseUnit: -1.0,
      );

      expect(unit.toBaseUnit, -1.0);
    });

    test('creates with very large factor', () {
      const unit = Unit(
        id: 'huge_unit',
        symbol: 'huge',
        category: UnitCategory.length,
        toBaseUnit: 999999999.0,
      );

      expect(unit.toBaseUnit, 999999999.0);
    });

    test('creates with very small factor', () {
      const unit = Unit(
        id: 'tiny_unit',
        symbol: 'tiny',
        category: UnitCategory.length,
        toBaseUnit: 0.000000001,
      );

      expect(unit.toBaseUnit, 0.000000001);
    });
  });

  group('ConversionResult - timestamps', () {
    late Unit testUnit;

    setUp(() {
      testUnit = const Unit(
        id: 'test',
        symbol: 'tst',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );
    });

    test('preserves exact timestamp', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 45, 123);
      final result = ConversionResult(
        fromValue: 1.0,
        fromUnit: testUnit,
        toValue: 1.0,
        toUnit: testUnit,
        timestamp: timestamp,
      );

      expect(result.timestamp, timestamp);
      expect(result.timestamp.millisecond, 123);
    });

    test('can have past timestamp', () {
      final timestamp = DateTime(2020, 1, 1);
      final result = ConversionResult(
        fromValue: 1.0,
        fromUnit: testUnit,
        toValue: 1.0,
        toUnit: testUnit,
        timestamp: timestamp,
      );

      expect(result.timestamp.isBefore(DateTime.now()), true);
    });

    test('can have future timestamp', () {
      final timestamp = DateTime(2030, 1, 1);
      final result = ConversionResult(
        fromValue: 1.0,
        fromUnit: testUnit,
        toValue: 1.0,
        toUnit: testUnit,
        timestamp: timestamp,
      );

      expect(result.timestamp.isAfter(DateTime.now()), true);
    });
  });
}
