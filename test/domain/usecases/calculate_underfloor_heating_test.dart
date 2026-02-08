import 'dart:math' show sqrt;

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_underfloor_heating.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  final emptyPriceList = <PriceItem>[];

  group('CalculateUnderfloorHeating', () {
    group('Электрический мат', () {
      test('стандартный расчёт — жилая комната 15м², 72% полезной площади', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 15.0,
          'systemType': 1.0,
          'roomType': 2.0, // living → 150 Вт/м²
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 15 * 0.72 = 10.8 м²
        expect(result.values['heatingArea'], closeTo(10.8, 0.1));
        expect(result.values['matArea'], closeTo(10.8, 0.1));
        // Power: 10.8 * 150 = 1620 Вт
        expect(result.values['totalPower'], closeTo(1620, 10));
      });

      test('ванная 6м² — повышенная мощность 180 Вт/м²', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 6.0,
          'systemType': 1.0,
          'roomType': 1.0, // bathroom → 180 Вт/м²
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 6 * 0.72 = 4.32 м²
        expect(result.values['heatingArea'], closeTo(4.32, 0.1));
        // Power: 4.32 * 180 = 777.6 Вт
        expect(result.values['totalPower'], closeTo(778, 10));
      });

      test('балкон 4м² — максимальная мощность 200 Вт/м²', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 4.0,
          'systemType': 1.0,
          'roomType': 4.0, // balcony → 200 Вт/м²
          'usefulAreaPercent': 80.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 4 * 0.80 = 3.2 м²
        expect(result.values['heatingArea'], closeTo(3.2, 0.1));
        // Power: 3.2 * 200 = 640 Вт
        expect(result.values['totalPower'], closeTo(640, 10));
      });

      test('кухня 10м² — мощность 130 Вт/м²', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 10.0,
          'systemType': 1.0,
          'roomType': 3.0, // kitchen → 130 Вт/м²
          'usefulAreaPercent': 70.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 10 * 0.70 = 7.0 м²
        expect(result.values['heatingArea'], closeTo(7.0, 0.1));
        // Power: 7 * 130 = 910 Вт
        expect(result.values['totalPower'], closeTo(910, 10));
      });
    });

    group('Электрический кабель', () {
      test('стандартный расчёт — жилая 20м², 70%', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 20.0,
          'systemType': 2.0,
          'roomType': 2.0, // living → 150 Вт/м²
          'usefulAreaPercent': 70.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 20 * 0.70 = 14 м²
        expect(result.values['heatingArea'], closeTo(14.0, 0.1));
        // Power: 14 * 150 = 2100 Вт
        expect(result.values['totalPower'], closeTo(2100, 10));
        // Cable length: 2100 / 18 = 116.7 м
        expect(result.values['cableLength'], closeTo(116.7, 1.0));
        // Montage tape: 14 * 2 = 28 м
        expect(result.values['montageTapeLength'], closeTo(28.0, 0.5));
      });

      test('монтажная лента зависит от площади обогрева', () {
        final calculator = CalculateUnderfloorHeating();

        final result50 = calculator({
          'area': 20.0,
          'systemType': 2.0,
          'roomType': 2.0,
          'usefulAreaPercent': 50.0,
        }, emptyPriceList);

        final result90 = calculator({
          'area': 20.0,
          'systemType': 2.0,
          'roomType': 2.0,
          'usefulAreaPercent': 90.0,
        }, emptyPriceList);

        // 50%: heatingArea=10, montageTape=20
        expect(result50.values['montageTapeLength'], closeTo(20.0, 0.5));
        // 90%: heatingArea=18, montageTape=36
        expect(result90.values['montageTapeLength'], closeTo(36.0, 0.5));
      });
    });

    group('ИК плёнка', () {
      test('стандартная ширина 80 см', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 12.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 75.0,
          'filmWidth': 1.0, // 80 cm
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 12 * 0.75 = 9 м²
        expect(result.values['heatingArea'], closeTo(9.0, 0.1));
        expect(result.values['filmArea'], closeTo(9.0, 0.1));
        expect(result.values['filmWidthCm'], equals(80.0));
        // Linear meters: 9 / 0.8 = 11.25 м.п.
        expect(result.values['filmLinearMeters'], closeTo(11.25, 0.1));
        // Reflective substrate = full area (not heating area)
        expect(result.values['reflectiveSubstrate'], equals(12.0));
      });

      test('ширина 50 см', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 10.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 80.0,
          'filmWidth': 0.0, // 50 cm
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['filmWidthCm'], equals(50.0));
        // Heating area: 10 * 0.80 = 8 м²
        // Linear meters: 8 / 0.5 = 16 м.п.
        expect(result.values['filmLinearMeters'], closeTo(16.0, 0.1));
      });

      test('ширина 100 см', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 15.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 72.0,
          'filmWidth': 2.0, // 100 cm
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['filmWidthCm'], equals(100.0));
        // Heating area: 15 * 0.72 = 10.8 м²
        // Linear meters: 10.8 / 1.0 = 10.8 м.п.
        expect(result.values['filmLinearMeters'], closeTo(10.8, 0.1));
      });

      test('контактные зажимы зависят от количества полос', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 12.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 75.0,
          'filmWidth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        final filmStrips = result.values['filmStrips']!;
        final contactClips = result.values['contactClips']!;
        // 2 зажима на полосу
        expect(contactClips, equals(filmStrips * 2));
      });
    });

    group('Водяной тёплый пол', () {
      test('жилая комната 25м² — шаг 150 мм', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 25.0,
          'systemType': 4.0,
          'roomType': 2.0, // living → шаг 150 мм
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 25 * 0.72 = 18 м²
        expect(result.values['heatingArea'], closeTo(18.0, 0.1));
        // Pipe step: 150mm
        expect(result.values['pipeStep'], equals(150.0));
        // Pipe per m²: 1 / 0.15 = 6.67 м/м²
        // Pipe length: 18 * 6.67 * 1.15 ≈ 138 м
        expect(result.values['pipeLength'], closeTo(138.0, 5.0));
        // Loop count: ceil(138 / 100) = 2
        expect(result.values['loopCount'], equals(2.0));
        expect(result.values['collectorOutputs'], equals(2.0));
        // Insulation = full area
        expect(result.values['insulationArea'], equals(25.0));
        // Screed: 25 * 0.08 = 2 м³
        expect(result.values['screedVolume'], closeTo(2.0, 0.1));
      });

      test('ванная — шаг 100 мм (обновлённый)', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 6.0,
          'systemType': 4.0,
          'roomType': 1.0, // bathroom → шаг 100 мм
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Pipe step for bathroom: 100mm (обновлено)
        expect(result.values['pipeStep'], equals(100.0));
        // Heating area: 6 * 0.72 = 4.32 м²
        // Pipe per m²: 1 / 0.1 = 10 м/м²
        // Pipe length: 4.32 * 10 * 1.15 ≈ 49.7 м
        expect(result.values['pipeLength'], closeTo(49.7, 2.0));
      });

      test('балкон — шаг 100 мм', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 4.0,
          'systemType': 4.0,
          'roomType': 4.0, // balcony → шаг 100 мм
          'usefulAreaPercent': 80.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['pipeStep'], equals(100.0));
        // Heating area: 4 * 0.8 = 3.2 м²
        // Pipe per m²: 1 / 0.1 = 10 м/м²
        // Pipe length: 3.2 * 10 * 1.15 = 36.8 м
        expect(result.values['pipeLength'], closeTo(36.8, 1.0));
      });

      test('демпферная лента — по периметру, не по площади', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 25.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Периметр: sqrt(25) * 4 = 20 м
        // Демпферная лента: 20 * 1.1 = 22 м
        final expectedPerimeter = sqrt(25.0) * 4;
        expect(result.values['perimeter'], closeTo(expectedPerimeter, 0.1));
        expect(result.values['damperTapeLength'], closeTo(expectedPerimeter * 1.1, 0.5));
      });

      test('скобы зависят от площади обогрева', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 20.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 20 * 0.72 = 14.4 м²
        // Brackets: ceil(14.4 * 10) = 144
        expect(result.values['bracketsCount'], closeTo(144.0, 1.0));
      });
    });

    group('Изменение usefulAreaPercent', () {
      test('увеличение % → увеличение мощности и материалов (электромат)', () {
        final calculator = CalculateUnderfloorHeating();

        final result60 = calculator({
          'area': 15.0,
          'systemType': 1.0,
          'roomType': 2.0,
          'usefulAreaPercent': 60.0,
        }, emptyPriceList);

        final result85 = calculator({
          'area': 15.0,
          'systemType': 1.0,
          'roomType': 2.0,
          'usefulAreaPercent': 85.0,
        }, emptyPriceList);

        // heatingArea: 9.0 vs 12.75
        expect(result60.values['heatingArea']!, lessThan(result85.values['heatingArea']!));
        // matArea follows heatingArea
        expect(result60.values['matArea']!, lessThan(result85.values['matArea']!));
        // totalPower follows heatingArea
        expect(result60.values['totalPower']!, lessThan(result85.values['totalPower']!));
      });

      test('увеличение % → увеличение длины кабеля (электрокабель)', () {
        final calculator = CalculateUnderfloorHeating();

        final result50 = calculator({
          'area': 20.0,
          'systemType': 2.0,
          'roomType': 2.0,
          'usefulAreaPercent': 50.0,
        }, emptyPriceList);

        final result90 = calculator({
          'area': 20.0,
          'systemType': 2.0,
          'roomType': 2.0,
          'usefulAreaPercent': 90.0,
        }, emptyPriceList);

        expect(result50.values['cableLength']!, lessThan(result90.values['cableLength']!));
      });

      test('увеличение % → увеличение длины трубы (водяной)', () {
        final calculator = CalculateUnderfloorHeating();

        final result50 = calculator({
          'area': 25.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 50.0,
        }, emptyPriceList);

        final result90 = calculator({
          'area': 25.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 90.0,
        }, emptyPriceList);

        expect(result50.values['pipeLength']!, lessThan(result90.values['pipeLength']!));
        expect(result50.values['bracketsCount']!, lessThan(result90.values['bracketsCount']!));
      });

      test('% НЕ влияет на теплоизоляцию и стяжку (полная площадь)', () {
        final calculator = CalculateUnderfloorHeating();

        final result50 = calculator({
          'area': 20.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 50.0,
        }, emptyPriceList);

        final result90 = calculator({
          'area': 20.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 90.0,
        }, emptyPriceList);

        // Insulation and screed use full area, not heatingArea
        expect(result50.values['insulationArea'], equals(result90.values['insulationArea']));
        expect(result50.values['screedVolume'], equals(result90.values['screedVolume']));
        // Damper tape also doesn't depend on usefulAreaPercent (based on perimeter)
        expect(result50.values['damperTapeLength'], equals(result90.values['damperTapeLength']));
      });

      test('% НЕ влияет на отражающую подложку ИК-плёнки (полная площадь)', () {
        final calculator = CalculateUnderfloorHeating();

        final result60 = calculator({
          'area': 15.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 60.0,
          'filmWidth': 1.0,
        }, emptyPriceList);

        final result80 = calculator({
          'area': 15.0,
          'systemType': 3.0,
          'roomType': 2.0,
          'usefulAreaPercent': 80.0,
          'filmWidth': 1.0,
        }, emptyPriceList);

        // Reflective substrate = full area for both
        expect(result60.values['reflectiveSubstrate'], equals(15.0));
        expect(result80.values['reflectiveSubstrate'], equals(15.0));
      });
    });

    group('Значения по умолчанию', () {
      test('при отсутствии параметров — электромат, жилая, 72%', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['systemType'], equals(1.0));
        expect(result.values['roomType'], equals(2.0));
        expect(result.values['heatingArea'], closeTo(7.2, 0.1)); // 10 * 0.72
        expect(result.values['matArea'], closeTo(7.2, 0.1));
      });
    });

    group('Общие материалы', () {
      test('термостат, датчик, гофротруба для всех типов', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 15.0,
          'systemType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thermostatCount'], equals(1.0));
        expect(result.values['sensorCount'], equals(1.0));
        expect(result.values['corrugatedTubeLength'], equals(2.5));
      });
    });

    group('Теплоизоляция', () {
      test('опциональна для электрических систем', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 20.0,
          'systemType': 1.0,
          'addInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(20.0));
      });

      test('обязательна для водяной системы (игнорирует addInsulation)', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 20.0,
          'systemType': 4.0,
          'addInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(20.0));
      });
    });

    group('Граничные условия', () {
      test('нулевая площадь → исключение', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('минимальная площадь 0.1 м² — расчёт без ошибок', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 0.1,
          'systemType': 1.0,
          'roomType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);
        expect(result.values['area'], closeTo(0.1, 0.01));
        expect(result.values['totalPower']!, greaterThan(0));
      });

      test('большая площадь 200 м²', () {
        final calculator = CalculateUnderfloorHeating();
        final inputs = {
          'area': 200.0,
          'systemType': 4.0,
          'roomType': 2.0,
          'usefulAreaPercent': 72.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Heating area: 200 * 0.72 = 144 м²
        expect(result.values['heatingArea'], closeTo(144.0, 0.5));
        // Pipe length будет очень большой
        expect(result.values['pipeLength']!, greaterThan(500));
        // Много контуров
        expect(result.values['loopCount']!, greaterThan(5));
      });
    });
  });
}
