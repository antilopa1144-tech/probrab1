import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/heating_canonical_adapter.dart';

void main() {
  group('calculateCanonicalHeating v3', () {
    test('отделяет точную потребность от покупки целыми секциями', () {
      final result = calculateCanonicalHeating({
        'totalArea': 80,
        'ceilingHeight': 2.7,
        'climateZone': 1,
        'buildingType': 1,
        'radiatorType': 0,
        'roomCount': 4,
      });
      final radiator = result.materials.first;

      expect(result.formulaVersion, 'heating-canonical-v3');
      expect(result.totals['totalPowerW'], 8000);
      expect(result.totals['exactUnits'], closeTo(8000 / 180, 0.000001));
      expect(result.totals['totalUnits'], 45);
      expect(radiator.quantity, closeTo(8000 / 180, 0.000001));
      expect(radiator.withReserve, closeTo(8000 / 180, 0.000001));
      expect(radiator.purchaseQty, 45);
      expect(radiator.unit, 'секций');
    });

    test('не применяет монтажные отходы к тепловой мощности', () {
      final inputs = {
        'totalArea': 80.0,
        'ceilingHeight': 2.7,
        'climateZone': 1.0,
        'buildingType': 1.0,
        'radiatorType': 3.0,
        'roomCount': 4.0,
        'accuracyMode': 2.0,
      };
      final result = calculateCanonicalHeating(inputs);

      expect(result.scenarios['MIN']!.exactNeed, closeTo(8000 / 700, 0.000001));
      expect(result.scenarios['REC']!.exactNeed, closeTo(8000 / 700, 0.000001));
      expect(result.scenarios['MAX']!.exactNeed, closeTo(8000 / 700, 0.000001));
      expect(result.scenarios['REC']!.purchaseQuantity, 12);
      expect(result.scenarios['REC']!.buyPlan.unit, 'шт');
    });

    test('трубу считает по помещениям, крепёж — по приборам', () {
      final result = calculateCanonicalHeating({
        'totalArea': 80,
        'ceilingHeight': 2.7,
        'climateZone': 1,
        'buildingType': 1,
        'radiatorType': 3,
        'roomCount': 4,
      });

      expect(result.totals['pipeSticks'], 12);
      expect(result.totals['radiatorCount'], 12);
      expect(result.totals['brackets'], 38);
    });
  });
}
