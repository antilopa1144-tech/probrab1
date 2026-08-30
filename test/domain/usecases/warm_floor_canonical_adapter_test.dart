import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_canonical_adapter.dart';

void main() {
  group('calculateCanonicalWarmFloor v3', () {
    test('проверяет один паспортный мат без скрытого запаса', () {
      final result = calculateCanonicalWarmFloor({});

      expect(result.formulaVersion, 'warm-floor-canonical-v3');
      expect(result.totals['roomArea'], 10);
      expect(result.totals['availableAreaM2'], 8);
      expect(result.totals['heatingArea'], 8);
      expect(result.totals['selectedCoverageAreaM2'], 8);
      expect(result.totals['totalPowerW'], 1200);
      expect(result.totals['circuitCurrentA'], closeTo(1200 / 230, 0.001));
      expect(result.scenarios['MIN']!.purchaseQuantity, 1);
      expect(result.scenarios['REC']!.purchaseQuantity, 1);
      expect(result.scenarios['MAX']!.purchaseQuantity, 1);
      expect(result.materials, hasLength(1));
    });

    test('не меняет паспортную длину кабеля между сценариями', () {
      final result = calculateCanonicalWarmFloor({
        'systemType': 1,
        'kitCount': 2,
        'kitCoverageAreaM2': 4,
        'kitRatedPowerW': 800,
        'cableLengthPerKitM': 40,
      });

      expect(result.totals['cableLength'], 80);
      expect(result.totals['cableStepMm'], 100);
      for (final scenario in result.scenarios.values) {
        expect(scenario.exactNeed, 2);
        expect(scenario.purchaseQuantity, 2);
        expect(scenario.leftover, 0);
      }
    });

    test('не придумывает клей, утеплитель и крепёж', () {
      final result = calculateCanonicalWarmFloor({});
      final names = result.materials.map((material) => material.name).join(' ');

      expect(names, isNot(contains('Клей')));
      expect(names, isNot(contains('Утепл')));
      expect(names, isNot(contains('лента')));
      expect(names, isNot(contains('Стяж')));
    });

    test('предупреждает о несовпадении комплекта с раскладкой', () {
      final result = calculateCanonicalWarmFloor({
        'roomAreaM2': 12,
        'excludedAreaM2': 2,
        'layoutAreaM2': 8,
        'kitCoverageAreaM2': 10,
      });

      expect(
        result.warnings.any((warning) => warning.contains('больше площади')),
        isTrue,
      );
    });

    test('сверяет проектную нагрузку и ток терморегулятора', () {
      final result = calculateCanonicalWarmFloor({
        'kitCount': 2,
        'kitRatedPowerW': 800,
        'designHeatLoadW': 1800,
        'supplyVoltageV': 230,
        'thermostatRatedCurrentA': 6,
      });

      expect(result.totals['totalPowerW'], 1600);
      expect(result.totals['circuitCurrentA'], closeTo(1600 / 230, 0.001));
      expect(
        result.warnings.any((warning) => warning.contains('ниже введённой')),
        isTrue,
      );
      expect(
        result.warnings.any(
          (warning) => warning.contains('выше паспортного тока'),
        ),
        isTrue,
      );
    });

    test('добавляет только явно введённые позиции ведомости', () {
      final result = calculateCanonicalWarmFloor({
        'thermostatCount': 1,
        'floorSensorCount': 1,
        'sensorConduitLengthM': 2.2,
        'sensorConduitStockLengthM': 1,
      });

      expect(result.materials, hasLength(4));
      final conduit = result.materials.firstWhere(
        (material) => material.name.contains('трубка'),
      );
      expect(conduit.quantity, 2.2);
      expect(conduit.purchaseQty, 3);
    });

    test('legacy area и процент открываются как проверка комплекта', () {
      final result = calculateCanonicalWarmFloor({
        'area': 20,
        'type': 2,
        'usefulAreaPercent': 70,
      });

      expect(result.totals['roomArea'], 20);
      expect(result.totals['excludedAreaM2'], closeTo(6, 0.001));
      expect(result.totals['heatingArea'], closeTo(14, 0.001));
      expect(result.totals['systemType'], 0);
      expect(
        result.warnings.any((warning) => warning.contains('Старые настройки')),
        isTrue,
      );
    });

    test('legacy размеры помещения нормализуются без выдуманной мощности', () {
      final result = calculateCanonicalWarmFloor({
        'length': 5,
        'width': 4,
        'type': 1,
      });

      expect(result.totals['roomArea'], 20);
      expect(result.totals['systemType'], 1);
      expect(result.totals['totalPowerW'], 1200);
    });

    test('legacy водяной режим безопасно отправляет в отдельный калькулятор', () {
      final result = calculateCanonicalWarmFloor({
        'area': 20,
        'systemType': 4,
      });

      expect(result.totals['legacyWaterMode'], 1);
      expect(result.materials, isEmpty);
      expect(result.scenarios['REC']!.purchaseQuantity, 0);
      expect(
        result.warnings.any((warning) => warning.contains('Водяной')),
        isTrue,
      );
    });
  });
}
