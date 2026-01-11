import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/unit_conversion.dart';

void main() {
  group('Unit', () {
    test('создаётся с обязательными полями', () {
      const unit = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.id, 'meter');
      expect(unit.name, 'метр');
      expect(unit.symbol, 'м');
      expect(unit.category, UnitCategory.length);
      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, false);
    });

    test('создаётся как базовая единица', () {
      const unit = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.isBase, true);
    });

    test('создаётся для площади', () {
      const unit = Unit(
        id: 'square_meter',
        name: 'квадратный метр',
        symbol: 'м²',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.area);
      expect(unit.symbol, 'м²');
    });

    test('создаётся для объёма', () {
      const unit = Unit(
        id: 'cubic_meter',
        name: 'кубический метр',
        symbol: 'м³',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.volume);
      expect(unit.symbol, 'м³');
    });

    test('создаётся для веса', () {
      const unit = Unit(
        id: 'kilogram',
        name: 'килограмм',
        symbol: 'кг',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.weight);
      expect(unit.symbol, 'кг');
    });

    test('создаётся для количества', () {
      const unit = Unit(
        id: 'piece',
        name: 'штука',
        symbol: 'шт',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.category, UnitCategory.quantity);
      expect(unit.symbol, 'шт');
    });

    test('создаётся с коэффициентом конвертации', () {
      const kilometer = Unit(
        id: 'kilometer',
        name: 'километр',
        symbol: 'км',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(kilometer.toBaseUnit, 1000.0);
    });

    test('создаётся с дробным коэффициентом', () {
      const centimeter = Unit(
        id: 'centimeter',
        name: 'сантиметр',
        symbol: 'см',
        category: UnitCategory.length,
        toBaseUnit: 0.01,
      );

      expect(centimeter.toBaseUnit, 0.01);
    });

    test('toString возвращает символ', () {
      const unit = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.toString(), 'м');
    });

    test('оператор == сравнивает по id', () {
      const unit1 = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'meter',
        name: 'metre',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit1, equals(unit2));
    });

    test('оператор == возвращает false для разных id', () {
      const unit1 = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'kilometer',
        name: 'километр',
        symbol: 'км',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit1, isNot(equals(unit2)));
    });

    test('оператор == возвращает true для идентичного объекта', () {
      const unit = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit, equals(unit));
    });

    test('hashCode зависит от id', () {
      const unit1 = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'meter',
        name: 'metre',
        symbol: 'm',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit1.hashCode, equals(unit2.hashCode));
    });

    test('hashCode разный для разных id', () {
      const unit1 = Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      const unit2 = Unit(
        id: 'kilometer',
        name: 'километр',
        symbol: 'км',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit1.hashCode, isNot(equals(unit2.hashCode)));
    });
  });

  group('UnitCategory', () {
    test('имеет все необходимые категории', () {
      expect(UnitCategory.values.length, 5);
      expect(UnitCategory.values, contains(UnitCategory.area));
      expect(UnitCategory.values, contains(UnitCategory.length));
      expect(UnitCategory.values, contains(UnitCategory.volume));
      expect(UnitCategory.values, contains(UnitCategory.weight));
      expect(UnitCategory.values, contains(UnitCategory.quantity));
    });
  });

  group('UnitCategoryExtension', () {
    test('displayName возвращает корректные названия', () {
      expect(UnitCategory.area.displayName, 'Площадь');
      expect(UnitCategory.length.displayName, 'Длина');
      expect(UnitCategory.volume.displayName, 'Объём');
      expect(UnitCategory.weight.displayName, 'Вес');
      expect(UnitCategory.quantity.displayName, 'Количество');
    });

    test('icon возвращает корректные иконки', () {
      expect(UnitCategory.area.icon, '📐');
      expect(UnitCategory.length.icon, '📏');
      expect(UnitCategory.volume.icon, '🧊');
      expect(UnitCategory.weight.icon, '⚖️');
      expect(UnitCategory.quantity.icon, '📦');
    });

    test('все displayName не пустые', () {
      for (final category in UnitCategory.values) {
        expect(category.displayName.isNotEmpty, true);
      }
    });

    test('все icon не пустые', () {
      for (final category in UnitCategory.values) {
        expect(category.icon.isNotEmpty, true);
      }
    });
  });

  group('ConversionResult', () {
    late Unit meterUnit;
    late Unit kilometerUnit;
    late DateTime testTime;

    setUp(() {
      meterUnit = const Unit(
        id: 'meter',
        name: 'метр',
        symbol: 'м',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
        isBase: true,
      );

      kilometerUnit = const Unit(
        id: 'kilometer',
        name: 'километр',
        symbol: 'км',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      testTime = DateTime(2024, 1, 15, 10, 30);
    });

    test('создаётся с обязательными полями', () {
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

    test('formatted возвращает читаемую строку', () {
      final result = ConversionResult(
        fromValue: 1000.0,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000 м = 1 км');
    });

    test('formatted форматирует дробные значения', () {
      const centimeter = Unit(
        id: 'centimeter',
        name: 'сантиметр',
        symbol: 'см',
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

      expect(result.formatted, '10.5 м = 1050 см');
    });

    test('formatted округляет до 4 знаков после запятой', () {
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

    test('formatted убирает trailing нули', () {
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

    test('formatted показывает целые числа без дробной части', () {
      final result = ConversionResult(
        fromValue: 1000.0,
        fromUnit: meterUnit,
        toValue: 1.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000 м = 1 км');
      expect(result.formatted, isNot(contains('1000.0')));
      expect(result.formatted, isNot(contains('1.0')));
    });

    test('toString возвращает formatted', () {
      final result = ConversionResult(
        fromValue: 500.0,
        fromUnit: meterUnit,
        toValue: 0.5,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.toString(), result.formatted);
      expect(result.toString(), '500 м = 0.5 км');
    });

    test('работает с нулевыми значениями', () {
      final result = ConversionResult(
        fromValue: 0.0,
        fromUnit: meterUnit,
        toValue: 0.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '0 м = 0 км');
    });

    test('работает с очень малыми значениями', () {
      const millimeter = Unit(
        id: 'millimeter',
        name: 'миллиметр',
        symbol: 'мм',
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

      expect(result.formatted, '0.001 м = 1 мм');
    });

    test('работает с очень большими значениями', () {
      final result = ConversionResult(
        fromValue: 1000000.0,
        fromUnit: meterUnit,
        toValue: 1000.0,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '1000000 м = 1000 км');
    });

    test('работает с отрицательными значениями', () {
      final result = ConversionResult(
        fromValue: -100.0,
        fromUnit: meterUnit,
        toValue: -0.1,
        toUnit: kilometerUnit,
        timestamp: testTime,
      );

      expect(result.formatted, '-100 м = -0.1 км');
    });
  });

  group('Unit - различные единицы длины', () {
    test('километр имеет коэффициент 1000', () {
      const unit = Unit(
        id: 'kilometer',
        name: 'километр',
        symbol: 'км',
        category: UnitCategory.length,
        toBaseUnit: 1000.0,
      );

      expect(unit.toBaseUnit, 1000.0);
      expect(unit.category, UnitCategory.length);
    });

    test('сантиметр имеет коэффициент 0.01', () {
      const unit = Unit(
        id: 'centimeter',
        name: 'сантиметр',
        symbol: 'см',
        category: UnitCategory.length,
        toBaseUnit: 0.01,
      );

      expect(unit.toBaseUnit, 0.01);
      expect(unit.category, UnitCategory.length);
    });

    test('миллиметр имеет коэффициент 0.001', () {
      const unit = Unit(
        id: 'millimeter',
        name: 'миллиметр',
        symbol: 'мм',
        category: UnitCategory.length,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.length);
    });
  });

  group('Unit - различные единицы площади', () {
    test('квадратный метр - базовая единица', () {
      const unit = Unit(
        id: 'square_meter',
        name: 'квадратный метр',
        symbol: 'м²',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.area);
    });

    test('квадратный сантиметр имеет коэффициент 0.0001', () {
      const unit = Unit(
        id: 'square_centimeter',
        name: 'квадратный сантиметр',
        symbol: 'см²',
        category: UnitCategory.area,
        toBaseUnit: 0.0001,
      );

      expect(unit.toBaseUnit, 0.0001);
      expect(unit.category, UnitCategory.area);
    });

    test('квадратный километр имеет коэффициент 1000000', () {
      const unit = Unit(
        id: 'square_kilometer',
        name: 'квадратный километр',
        symbol: 'км²',
        category: UnitCategory.area,
        toBaseUnit: 1000000.0,
      );

      expect(unit.toBaseUnit, 1000000.0);
      expect(unit.category, UnitCategory.area);
    });
  });

  group('Unit - различные единицы объёма', () {
    test('кубический метр - базовая единица', () {
      const unit = Unit(
        id: 'cubic_meter',
        name: 'кубический метр',
        symbol: 'м³',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.volume);
    });

    test('литр имеет коэффициент 0.001', () {
      const unit = Unit(
        id: 'liter',
        name: 'литр',
        symbol: 'л',
        category: UnitCategory.volume,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.volume);
    });

    test('кубический сантиметр имеет коэффициент 0.000001', () {
      const unit = Unit(
        id: 'cubic_centimeter',
        name: 'кубический сантиметр',
        symbol: 'см³',
        category: UnitCategory.volume,
        toBaseUnit: 0.000001,
      );

      expect(unit.toBaseUnit, 0.000001);
      expect(unit.category, UnitCategory.volume);
    });
  });

  group('Unit - различные единицы веса', () {
    test('килограмм - базовая единица', () {
      const unit = Unit(
        id: 'kilogram',
        name: 'килограмм',
        symbol: 'кг',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.weight);
    });

    test('грамм имеет коэффициент 0.001', () {
      const unit = Unit(
        id: 'gram',
        name: 'грамм',
        symbol: 'г',
        category: UnitCategory.weight,
        toBaseUnit: 0.001,
      );

      expect(unit.toBaseUnit, 0.001);
      expect(unit.category, UnitCategory.weight);
    });

    test('тонна имеет коэффициент 1000', () {
      const unit = Unit(
        id: 'ton',
        name: 'тонна',
        symbol: 'т',
        category: UnitCategory.weight,
        toBaseUnit: 1000.0,
      );

      expect(unit.toBaseUnit, 1000.0);
      expect(unit.category, UnitCategory.weight);
    });
  });

  group('Unit - различные единицы количества', () {
    test('штука - базовая единица', () {
      const unit = Unit(
        id: 'piece',
        name: 'штука',
        symbol: 'шт',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
        isBase: true,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.isBase, true);
      expect(unit.category, UnitCategory.quantity);
    });

    test('рулон - единица количества', () {
      const unit = Unit(
        id: 'roll',
        name: 'рулон',
        symbol: 'рул',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.category, UnitCategory.quantity);
    });

    test('упаковка - единица количества', () {
      const unit = Unit(
        id: 'pack',
        name: 'упаковка',
        symbol: 'уп',
        category: UnitCategory.quantity,
        toBaseUnit: 1.0,
      );

      expect(unit.toBaseUnit, 1.0);
      expect(unit.category, UnitCategory.quantity);
    });
  });

  group('ConversionResult - различные категории', () {
    test('конвертация площади', () {
      const squareMeter = Unit(
        id: 'square_meter',
        name: 'квадратный метр',
        symbol: 'м²',
        category: UnitCategory.area,
        toBaseUnit: 1.0,
      );

      const squareCentimeter = Unit(
        id: 'square_centimeter',
        name: 'квадратный сантиметр',
        symbol: 'см²',
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

      expect(result.formatted, '1 м² = 10000 см²');
    });

    test('конвертация объёма', () {
      const cubicMeter = Unit(
        id: 'cubic_meter',
        name: 'кубический метр',
        symbol: 'м³',
        category: UnitCategory.volume,
        toBaseUnit: 1.0,
      );

      const liter = Unit(
        id: 'liter',
        name: 'литр',
        symbol: 'л',
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

      expect(result.formatted, '1 м³ = 1000 л');
    });

    test('конвертация веса', () {
      const kilogram = Unit(
        id: 'kilogram',
        name: 'килограмм',
        symbol: 'кг',
        category: UnitCategory.weight,
        toBaseUnit: 1.0,
      );

      const gram = Unit(
        id: 'gram',
        name: 'грамм',
        symbol: 'г',
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

      expect(result.formatted, '2.5 кг = 2500 г');
    });
  });

  group('ConversionResult - граничные случаи форматирования', () {
    late Unit testUnit1;
    late Unit testUnit2;

    setUp(() {
      testUnit1 = const Unit(
        id: 'unit1',
        name: 'единица1',
        symbol: 'ед1',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      testUnit2 = const Unit(
        id: 'unit2',
        name: 'единица2',
        symbol: 'ед2',
        category: UnitCategory.length,
        toBaseUnit: 0.1,
      );
    });

    test('форматирование значения 0.0', () {
      final result = ConversionResult(
        fromValue: 0.0,
        fromUnit: testUnit1,
        toValue: 0.0,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      expect(result.formatted, '0 ед1 = 0 ед2');
    });

    test('форматирование очень малого значения', () {
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

    test('форматирование значения с 5+ знаками округляется до 4', () {
      final result = ConversionResult(
        fromValue: 1.123456,
        fromUnit: testUnit1,
        toValue: 11.23456,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      // Округлено до 4 знаков
      expect(formatted, contains('1.1235'));
      expect(formatted, contains('11.2346'));
    });

    test('форматирование целого числа с .0', () {
      final result = ConversionResult(
        fromValue: 100.0,
        fromUnit: testUnit1,
        toValue: 1000.0,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '100 ед1 = 1000 ед2');
      expect(formatted, isNot(contains('.0')));
    });

    test('форматирование убирает trailing нули после точки', () {
      final result = ConversionResult(
        fromValue: 1.2000,
        fromUnit: testUnit1,
        toValue: 12.3400,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '1.2 ед1 = 12.34 ед2');
      expect(formatted, isNot(contains('1.2000')));
      expect(formatted, isNot(contains('12.3400')));
    });

    test('форматирование убирает точку если все нули после', () {
      final result = ConversionResult(
        fromValue: 5.0000,
        fromUnit: testUnit1,
        toValue: 50.0000,
        toUnit: testUnit2,
        timestamp: DateTime.now(),
      );

      final formatted = result.formatted;
      expect(formatted, '5 ед1 = 50 ед2');
      expect(formatted, isNot(contains('.')));
    });
  });

  group('Unit - граничные случаи', () {
    test('создаётся с очень длинным названием', () {
      final longName = 'очень длинное название единицы измерения ' * 10;
      final unit = Unit(
        id: 'long_unit',
        name: longName,
        symbol: 'длин',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.name, longName);
    });

    test('создаётся с пустым символом', () {
      const unit = Unit(
        id: 'empty_symbol',
        name: 'единица',
        symbol: '',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );

      expect(unit.symbol, '');
      expect(unit.toString(), '');
    });

    test('создаётся с коэффициентом 0', () {
      const unit = Unit(
        id: 'zero_unit',
        name: 'нулевая единица',
        symbol: 'нул',
        category: UnitCategory.length,
        toBaseUnit: 0.0,
      );

      expect(unit.toBaseUnit, 0.0);
    });

    test('создаётся с отрицательным коэффициентом', () {
      const unit = Unit(
        id: 'negative_unit',
        name: 'отрицательная единица',
        symbol: 'отр',
        category: UnitCategory.length,
        toBaseUnit: -1.0,
      );

      expect(unit.toBaseUnit, -1.0);
    });

    test('создаётся с очень большим коэффициентом', () {
      const unit = Unit(
        id: 'huge_unit',
        name: 'огромная единица',
        symbol: 'огр',
        category: UnitCategory.length,
        toBaseUnit: 999999999.0,
      );

      expect(unit.toBaseUnit, 999999999.0);
    });

    test('создаётся с очень малым коэффициентом', () {
      const unit = Unit(
        id: 'tiny_unit',
        name: 'крошечная единица',
        symbol: 'кро',
        category: UnitCategory.length,
        toBaseUnit: 0.000000001,
      );

      expect(unit.toBaseUnit, 0.000000001);
    });
  });

  group('ConversionResult - метки времени', () {
    late Unit testUnit;

    setUp(() {
      testUnit = const Unit(
        id: 'test',
        name: 'тест',
        symbol: 'тст',
        category: UnitCategory.length,
        toBaseUnit: 1.0,
      );
    });

    test('сохраняет точную метку времени', () {
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

    test('может иметь метку времени в прошлом', () {
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

    test('может иметь метку времени в будущем', () {
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
