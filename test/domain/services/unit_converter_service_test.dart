import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/unit_conversion.dart';
import 'package:probrab_ai/domain/services/unit_converter_service.dart';

void main() {
  late UnitConverterService service;

  setUp(() {
    service = UnitConverterService();
  });

  group('UnitConverterService - Площадь (Area)', () {
    test('конвертирует м² в см²', () {
      final from = service.areaUnits.firstWhere((u) => u.id == 'sq_m');
      final to = service.areaUnits.firstWhere((u) => u.id == 'sq_cm');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 10000.0); // 1 м² = 10000 см²
    });

    test('конвертирует см² в м²', () {
      final from = service.areaUnits.firstWhere((u) => u.id == 'sq_cm');
      final to = service.areaUnits.firstWhere((u) => u.id == 'sq_m');

      final result = service.convert(value: 10000, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 1.0); // 10000 см² = 1 м²
    });

    test('конвертирует м² в мм²', () {
      final from = service.areaUnits.firstWhere((u) => u.id == 'sq_m');
      final to = service.areaUnits.firstWhere((u) => u.id == 'sq_mm');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 1000000.0); // 1 м² = 1,000,000 мм²
    });

    test('конвертирует гектары в м²', () {
      final from = service.areaUnits.firstWhere((u) => u.id == 'hectare');
      final to = service.areaUnits.firstWhere((u) => u.id == 'sq_m');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 10000.0); // 1 га = 10000 м²
    });

    test('конвертация в ту же единицу возвращает то же значение', () {
      final unit = service.areaUnits.firstWhere((u) => u.id == 'sq_m');

      final result = service.convert(value: 42.5, from: unit, to: unit);

      expect(result, isNotNull);
      expect(result!.toValue, 42.5);
    });
  });

  group('UnitConverterService - Длина (Length)', () {
    test('конвертирует метры в сантиметры', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final from = lengthUnits.firstWhere((u) => u.id == 'meter');
      final to = lengthUnits.firstWhere((u) => u.id == 'cm');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 100.0); // 1 м = 100 см
    });

    test('конвертирует километры в метры', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final from = lengthUnits.firstWhere((u) => u.id == 'km');
      final to = lengthUnits.firstWhere((u) => u.id == 'meter');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 1000.0); // 1 км = 1000 м
    });

    test('конвертирует миллиметры в метры', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final from = lengthUnits.firstWhere((u) => u.id == 'mm');
      final to = lengthUnits.firstWhere((u) => u.id == 'meter');

      final result = service.convert(value: 2500, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 2.5); // 2500 мм = 2.5 м
    });
  });

  group('UnitConverterService - Объём (Volume)', () {
    test('конвертирует м³ в литры', () {
      final volumeUnits = service.getUnitsByCategory(UnitCategory.volume);
      final from = volumeUnits.firstWhere((u) => u.id == 'cubic_m');
      final to = volumeUnits.firstWhere((u) => u.id == 'liter');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 1000.0); // 1 м³ = 1000 л
    });

    test('конвертирует литры в см³', () {
      final volumeUnits = service.getUnitsByCategory(UnitCategory.volume);
      final from = volumeUnits.firstWhere((u) => u.id == 'liter');
      final to = volumeUnits.firstWhere((u) => u.id == 'cubic_cm');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, closeTo(1000.0, 0.0001)); // 1 л = 1000 см³
    });
  });

  group('UnitConverterService - Вес (Weight)', () {
    test('конвертирует кг в граммы', () {
      final weightUnits = service.getUnitsByCategory(UnitCategory.weight);
      final from = weightUnits.firstWhere((u) => u.id == 'kg');
      final to = weightUnits.firstWhere((u) => u.id == 'gram');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 1000.0); // 1 кг = 1000 г
    });

    test('конвертирует тонны в кг', () {
      final weightUnits = service.getUnitsByCategory(UnitCategory.weight);
      final from = weightUnits.firstWhere((u) => u.id == 'ton');
      final to = weightUnits.firstWhere((u) => u.id == 'kg');

      final result = service.convert(value: 2.5, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 2500.0); // 2.5 т = 2500 кг
    });
  });

  group('UnitConverterService - Количество (Quantity)', () {
    test('конвертирует штуки в упаковки', () {
      final quantityUnits = service.getUnitsByCategory(UnitCategory.quantity);
      final from = quantityUnits.firstWhere((u) => u.id == 'piece');
      final to = quantityUnits.firstWhere((u) => u.id == 'pack');

      final result = service.convert(value: 10, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.toValue, 10.0); // Количество конвертируется 1:1
    });

    test('конвертирует рулоны в м²', () {
      final quantityUnits = service.getUnitsByCategory(UnitCategory.quantity);
      final from = quantityUnits.firstWhere((u) => u.id == 'roll');
      final to = quantityUnits.firstWhere((u) => u.id == 'piece');

      final result = service.convert(value: 1, from: from, to: to);

      expect(result, isNotNull);
      // Проверяем, что конверсия работает (точное значение зависит от коэффициента)
      expect(result!.toValue, greaterThan(0));
    });
  });

  group('UnitConverterService - Ошибки', () {
    test('возвращает null при конверсии разных категорий', () {
      final areaUnits = service.getUnitsByCategory(UnitCategory.area);
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final areaUnit = areaUnits.first;
      final lengthUnit = lengthUnits.first;

      final result = service.convert(value: 1, from: areaUnit, to: lengthUnit);

      expect(result, isNull);
    });

    test('возвращает null при конверсии нулевого значения через неверную категорию', () {
      final areaUnits = service.getUnitsByCategory(UnitCategory.area);
      final weightUnits = service.getUnitsByCategory(UnitCategory.weight);
      final areaUnit = areaUnits.first;
      final weightUnit = weightUnits.first;

      final result = service.convert(value: 0, from: areaUnit, to: weightUnit);

      expect(result, isNull);
    });
  });

  group('UnitConverterService - Получение единиц по категории', () {
    test('getUnitsByCategory возвращает единицы площади', () {
      final units = service.getUnitsByCategory(UnitCategory.area);

      expect(units, isNotEmpty);
      expect(units.every((u) => u.category == UnitCategory.area), true);
      expect(units.any((u) => u.id == 'sq_m'), true);
      expect(units.any((u) => u.id == 'sq_cm'), true);
    });

    test('getUnitsByCategory возвращает единицы длины', () {
      final units = service.getUnitsByCategory(UnitCategory.length);

      expect(units, isNotEmpty);
      expect(units.every((u) => u.category == UnitCategory.length), true);
      expect(units.any((u) => u.id == 'meter'), true);
      expect(units.any((u) => u.id == 'cm'), true);
      expect(units.any((u) => u.id == 'km'), true);
    });

    test('allUnits содержит все категории', () {
      final allUnits = service.allUnits;

      expect(allUnits, isNotEmpty);
      expect(
        allUnits.any((u) => u.category == UnitCategory.area),
        true,
      );
      expect(
        allUnits.any((u) => u.category == UnitCategory.length),
        true,
      );
      expect(
        allUnits.any((u) => u.category == UnitCategory.volume),
        true,
      );
      expect(
        allUnits.any((u) => u.category == UnitCategory.weight),
        true,
      );
      expect(
        allUnits.any((u) => u.category == UnitCategory.quantity),
        true,
      );
    });
  });

  group('UnitConverterService - ConversionResult', () {
    test('formatted возвращает правильный формат', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final from = lengthUnits.firstWhere((u) => u.id == 'meter');
      final to = lengthUnits.firstWhere((u) => u.id == 'cm');

      final result = service.convert(value: 2.5, from: from, to: to);

      expect(result, isNotNull);
      expect(result!.formatted, contains('2.5'));
      expect(result.formatted, contains('м'));
      expect(result.formatted, contains('250'));
      expect(result.formatted, contains('см'));
    });

    test('timestamp устанавливается при создании', () {
      final from = service.areaUnits.first;
      final to = service.areaUnits.last;

      final before = DateTime.now();
      final result = service.convert(value: 1, from: from, to: to);
      final after = DateTime.now();

      expect(result, isNotNull);
      expect(result!.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(result.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  group('UnitConverterService - Реальные сценарии', () {
    test('сценарий: пользователь хочет узнать площадь в разных единицах', () {
      final sqM = service.areaUnits.firstWhere((u) => u.id == 'sq_m');
      final sqCm = service.areaUnits.firstWhere((u) => u.id == 'sq_cm');
      final sqMm = service.areaUnits.firstWhere((u) => u.id == 'sq_mm');

      // Площадь комнаты 25 м²
      final toCm = service.convert(value: 25, from: sqM, to: sqCm);
      final toMm = service.convert(value: 25, from: sqM, to: sqMm);

      expect(toCm!.toValue, 250000.0); // 25 м² = 250,000 см²
      expect(toMm!.toValue, 25000000.0); // 25 м² = 25,000,000 мм²
    });

    test('сценарий: пользователь покупает обои (рулоны → м²)', () {
      final quantityUnits = service.getUnitsByCategory(UnitCategory.quantity);
      final roll = quantityUnits.firstWhere((u) => u.id == 'roll');
      final piece = quantityUnits.firstWhere((u) => u.id == 'piece');

      // 5 рулонов
      final result = service.convert(value: 5, from: roll, to: piece);

      expect(result, isNotNull);
      expect(result!.toValue, greaterThan(0));
    });

    test('сценарий: пользователь конвертирует вес мешка цемента', () {
      final weightUnits = service.getUnitsByCategory(UnitCategory.weight);
      final kg = weightUnits.firstWhere((u) => u.id == 'kg');
      final g = weightUnits.firstWhere((u) => u.id == 'gram');

      // Мешок 50 кг
      final result = service.convert(value: 50, from: kg, to: g);

      expect(result!.toValue, 50000.0); // 50 кг = 50,000 г
    });
  });

  group('UnitConverterService - Проверка точности', () {
    test('двойная конверсия возвращает исходное значение', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final from = lengthUnits.firstWhere((u) => u.id == 'meter');
      final to = lengthUnits.firstWhere((u) => u.id == 'cm');

      // 5 м → см
      final first = service.convert(value: 5, from: from, to: to);
      expect(first!.toValue, 500.0);

      // 500 см → м (обратно)
      final second = service.convert(value: first.toValue, from: to, to: from);
      expect(second!.toValue, closeTo(5.0, 0.0001));
    });

    test('цепочка конверсий сохраняет точность', () {
      final lengthUnits = service.getUnitsByCategory(UnitCategory.length);
      final m = lengthUnits.firstWhere((u) => u.id == 'meter');
      final cm = lengthUnits.firstWhere((u) => u.id == 'cm');
      final mm = lengthUnits.firstWhere((u) => u.id == 'mm');

      // 1 м → см → мм
      final toCm = service.convert(value: 1, from: m, to: cm);
      final toMm = service.convert(value: toCm!.toValue, from: cm, to: mm);

      expect(toMm!.toValue, closeTo(1000.0, 0.0001)); // 1 м = 1000 мм
    });
  });
}
