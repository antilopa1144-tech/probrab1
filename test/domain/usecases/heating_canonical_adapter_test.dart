import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/heating_canonical_adapter.dart';

void main() {
  group('calculateCanonicalHeating v4', () {
    test('принимает готовую нагрузку и мощность для рабочего режима', () {
      final result = calculateCanonicalHeating({
        'loadMode': 0,
        'designHeatLoadW': 8000,
        'deviceKind': 0,
        'devicePowerMode': 0,
        'deviceOutputAtDesignW': 180,
      });
      final radiator = result.materials.first;

      expect(result.formulaVersion, 'heating-canonical-v4');
      expect(result.totals['heatLoadW'], 8000);
      expect(result.totals['effectiveDeviceOutputW'], 180);
      expect(result.scenarios['MIN']!.exactNeed, closeTo(8000 / 180, 0.000001));
      expect(result.scenarios['REC']!.purchaseQuantity, 45);
      expect(radiator.unit, 'секций');
    });

    test('предварительный режим использует явные площадь и Вт/м²', () {
      final result = calculateCanonicalHeating({
        'loadMode': 1,
        'heatedAreaM2': 60,
        'specificHeatLoadWm2': 120,
        'deviceOutputAtDesignW': 200,
      });

      expect(result.totals['heatLoadW'], 7200);
      expect(result.scenarios['REC']!.purchaseQuantity, 36);
      expect(
        result.warnings.any((warning) => warning.contains('Вт/м²')),
        isTrue,
      );
    });

    test('legacy totalArea открывается как предварительная оценка', () {
      final result = calculateCanonicalHeating({'totalArea': 60});

      expect(result.totals['loadMode'], 1);
      expect(result.totals['heatedAreaM2'], 60);
      expect(result.totals['heatLoadW'], 6000);
    });

    test('для готового прибора округляет покупку в штуках', () {
      final result = calculateCanonicalHeating({
        'designHeatLoadW': 8000,
        'deviceKind': 1,
        'deviceOutputAtDesignW': 1500,
      });

      expect(
        result.scenarios['MIN']!.exactNeed,
        closeTo(8000 / 1500, 0.000001),
      );
      expect(result.scenarios['REC']!.purchaseQuantity, 6);
      expect(result.materials.first.unit, 'шт');
      expect(result.scenarios['REC']!.buyPlan.unit, 'шт');
    });

    test('пересчитывает паспортную теплоотдачу по ΔT и n', () {
      final result = calculateCanonicalHeating({
        'designHeatLoadW': 8000,
        'devicePowerMode': 1,
        'nominalDeviceOutputW': 1000,
        'ratedDeltaTK': 50,
        'supplyTempC': 55,
        'returnTempC': 45,
        'roomTempC': 20,
        'temperatureExponent': 1.3,
      });
      final expectedOutput = 1000 * math.pow(30 / 50, 1.3);

      expect(result.totals['designDeltaTK'], 30);
      expect(
        result.totals['effectiveDeviceOutputW'],
        closeTo(expectedOutput, 0.001),
      );
      expect(
        result.scenarios['REC']!.purchaseQuantity,
        (8000 / expectedOutput).ceil(),
      );
    });

    test('MIN без запаса, REC и MAX только с явным запасом', () {
      final result = calculateCanonicalHeating({
        'designHeatLoadW': 8000,
        'deviceOutputAtDesignW': 200,
        'designReservePercent': 10,
      });

      expect(result.scenarios['MIN']!.exactNeed, 40);
      expect(result.scenarios['MIN']!.purchaseQuantity, 40);
      expect(result.scenarios['REC']!.exactNeed, 44);
      expect(result.scenarios['REC']!.purchaseQuantity, 44);
      expect(result.scenarios['MAX']!.exactNeed, 44);
      expect(result.materials.first.quantity, 40);
      expect(result.materials.first.withReserve, 44);
    });

    test('не придумывает трубы и арматуру по тепловой нагрузке', () {
      final result = calculateCanonicalHeating({
        'designHeatLoadW': 8000,
        'deviceOutputAtDesignW': 180,
      });

      expect(result.materials, hasLength(1));
      expect(
        result.warnings.any((warning) => warning.contains('ведомости')),
        isTrue,
      );
    });

    test('округляет явную длину трубы до покупных отрезков', () {
      final result = calculateCanonicalHeating({
        'pipeLengthM': 10,
        'pipeStockLengthM': 4,
        'pipeReservePercent': 10,
      });
      final pipe = result.materials.firstWhere(
        (material) => material.name.contains('Труба отопления'),
      );

      expect(pipe.quantity, 10);
      expect(pipe.withReserve, 11);
      expect(pipe.purchaseQty, 12);
      expect(pipe.packageInfo, {
        'count': 3,
        'size': 4,
        'packageUnit': 'отрезков',
      });
    });

    test('добавляет только явно заданные штучные позиции', () {
      final result = calculateCanonicalHeating({
        'fittingCount': 8,
        'bracketCount': 4,
        'valveSetCount': 2,
        'airVentCount': 2,
      });

      double purchase(String name) => result.materials
          .firstWhere((material) => material.name.contains(name))
          .purchaseQty!;
      expect(purchase('Фитинги'), 8);
      expect(purchase('Кронштейны'), 4);
      expect(purchase('регулирующей'), 2);
      expect(purchase('Воздухоотводчики'), 2);
    });

    test('фиксирует расчёт по помещению и границы гидравлики', () {
      final result = calculateCanonicalHeating({});

      expect(
        result.warnings.any((warning) => warning.contains('одного помещения')),
        isTrue,
      );
      expect(
        result.warnings.any((warning) => warning.contains('Гидравлический')),
        isTrue,
      );
    });

    test('ограничивает входы canonical-диапазонами', () {
      final result = calculateCanonicalHeating({
        'designHeatLoadW': -1,
        'deviceOutputAtDesignW': 999999,
        'designReservePercent': 90,
        'fittingCount': 2.6,
      });

      expect(result.totals['heatLoadW'], 100);
      expect(result.totals['effectiveDeviceOutputW'], 50000);
      expect(result.totals['designReservePercent'], 30);
      expect(result.totals['fittings'], 3);
    });
  });
}
