import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePlaster', () {
    test('calculates plaster needed correctly (default substrate + evenness)', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
        'type': 1.0, // гипсовая
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      // Default: substrateType=1(бетон,1.0×), wallEvenness=1(ровная,1.0×)
      // 100 * 8.5 * 1.0 * 1.0 * 1.0 * 1.1 = 935 кг
      expect(result.values['plasterKg'], closeTo(935, 10));
      expect(result.values['plasterBags'], equals(32)); // 935/30 = 31.2 → 32
    });

    test('calculates cement plaster correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 50.0,
        'thickness': 20.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      // 50 * 17.0 * (20/10) * 1.0 * 1.0 * 1.1 = 1870 кг
      expect(result.values['plasterKg'], closeTo(1870, 50));
      expect(result.values['plasterBags'], equals(75)); // 1870/25 = 74.8 → 75
    });

    test('throws exception for zero area', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 0.0, 'thickness': 10.0};
      final emptyPriceList = <PriceItem>[];
      expect(() => calculator(inputs, emptyPriceList), throwsA(isA<CalculationException>()));
    });

    test('uses default values when missing', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0};
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      expect(result.values['plasterKg'], greaterThan(0));
      expect(result.values['plasterBags'], greaterThan(0));
    });

    test('calculates beacons needed', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0, 'thickness': 10.0};
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      expect(result.values['beacons'], equals(40));
      expect(result.values['beaconSize'], equals(6)); // <15mm → 6mm
    });

    test('calculates primer liters', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0, 'thickness': 10.0};
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      // Default substrate=бетон → бетоноконтакт: 100 * 0.3 * 1.1 = 33
      expect(result.values['primerLiters'], equals(33));
      expect(result.values['primerType'], equals(2)); // бетоноконтакт
    });

    test('calculates rule size', () {
      final calculator = CalculatePlaster();
      final inputs = {'area': 100.0, 'thickness': 10.0};
      final emptyPriceList = <PriceItem>[];
      final result = calculator(inputs, emptyPriceList);
      expect(result.values['ruleSize'], equals(1.5));
    });

    test('beacon size depends on thickness', () {
      final calculator = CalculatePlaster();
      final emptyPriceList = <PriceItem>[];

      // <15 мм → 6мм маяки
      var result = calculator({'area': 50.0, 'thickness': 9.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(6));
      result = calculator({'area': 50.0, 'thickness': 14.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(6));

      // >=15 мм → 10мм маяки
      result = calculator({'area': 50.0, 'thickness': 15.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(10));
      result = calculator({'area': 50.0, 'thickness': 25.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(10));
    });

    test('calculates mesh area for thick layers (>30mm)', () {
      final calculator = CalculatePlaster();
      final emptyPriceList = <PriceItem>[];

      // <=30 мм → нет сетки
      var result = calculator({'area': 50.0, 'thickness': 30.0}, emptyPriceList);
      expect(result.values.containsKey('meshArea'), isFalse);

      // >30 мм → сетка
      result = calculator({'area': 50.0, 'thickness': 35.0}, emptyPriceList);
      expect(result.values['meshArea'], closeTo(55, 1)); // 50 * 1.1 = 55
    });

    // ========= NEW: Substrate type tests =========

    group('substrate type multipliers', () {
      test('old brick increases consumption by 30%', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final resultConcrete = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'substrateType': 1.0,
        }, emptyPriceList);

        final resultOldBrick = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'substrateType': 3.0,
        }, emptyPriceList);

        // Old brick = 1.3×, concrete = 1.0×
        final ratio = resultOldBrick.values['plasterKg']! / resultConcrete.values['plasterKg']!;
        expect(ratio, closeTo(1.3, 0.01));
      });

      test('gas block increases consumption by 25%', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final resultConcrete = calculator({
          'area': 50.0, 'thickness': 15.0, 'type': 1.0, 'substrateType': 1.0,
        }, emptyPriceList);

        final resultGasBlock = calculator({
          'area': 50.0, 'thickness': 15.0, 'type': 1.0, 'substrateType': 4.0,
        }, emptyPriceList);

        final ratio = resultGasBlock.values['plasterKg']! / resultConcrete.values['plasterKg']!;
        expect(ratio, closeTo(1.25, 0.01));
      });

      test('concrete substrate uses betonkontakt primer', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'area': 50.0, 'thickness': 10.0, 'substrateType': 1.0,
        }, emptyPriceList);
        expect(result.values['primerType'], equals(2)); // betonkontakt
        // 50 * 0.3 * 1.1 = 16.5 → ceil = 17
        expect(result.values['primerLiters'], equals(17));
      });

      test('brick substrate uses deep penetration primer', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'area': 50.0, 'thickness': 10.0, 'substrateType': 2.0,
        }, emptyPriceList);
        expect(result.values['primerType'], equals(1)); // deep penetration
        // 50 * 0.1 * 1.1 = 5.5 → ceil = 6
        expect(result.values['primerLiters'], equals(6));
      });
    });

    group('wall evenness multipliers', () {
      test('uneven walls increase consumption by 15%', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final resultEven = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'wallEvenness': 1.0,
        }, emptyPriceList);

        final resultUneven = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'wallEvenness': 2.0,
        }, emptyPriceList);

        final ratio = resultUneven.values['plasterKg']! / resultEven.values['plasterKg']!;
        expect(ratio, closeTo(1.15, 0.01));
      });

      test('very uneven walls increase consumption by 30%', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final resultEven = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'wallEvenness': 1.0,
        }, emptyPriceList);

        final resultVeryUneven = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0, 'wallEvenness': 3.0,
        }, emptyPriceList);

        final ratio = resultVeryUneven.values['plasterKg']! / resultEven.values['plasterKg']!;
        expect(ratio, closeTo(1.30, 0.01));
      });
    });

    group('combined substrate + evenness', () {
      test('old brick + very uneven = 1.3 x 1.3 = 1.69x consumption', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final resultBase = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0,
          'substrateType': 1.0, 'wallEvenness': 1.0,
        }, emptyPriceList);

        final resultWorst = calculator({
          'area': 50.0, 'thickness': 20.0, 'type': 1.0,
          'substrateType': 3.0, 'wallEvenness': 3.0,
        }, emptyPriceList);

        final ratio = resultWorst.values['plasterKg']! / resultBase.values['plasterKg']!;
        expect(ratio, closeTo(1.69, 0.02));
      });
    });

    group('conditional warnings', () {
      test('thick layer warning at >40mm', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        var result = calculator({'area': 50.0, 'thickness': 40.0}, emptyPriceList);
        expect(result.values.containsKey('warningThickLayer'), isFalse);

        result = calculator({'area': 50.0, 'thickness': 41.0}, emptyPriceList);
        expect(result.values['warningThickLayer'], equals(1.0));
      });

      test('obryzg tip for old brick + very uneven', () {
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        var result = calculator({
          'area': 50.0, 'thickness': 20.0,
          'substrateType': 3.0, 'wallEvenness': 3.0,
        }, emptyPriceList);
        expect(result.values['tipObryzg'], equals(1.0));

        // Not triggered for other combos
        result = calculator({
          'area': 50.0, 'thickness': 20.0,
          'substrateType': 3.0, 'wallEvenness': 2.0,
        }, emptyPriceList);
        expect(result.values.containsKey('tipObryzg'), isFalse);
      });
    });

    group('practical verification', () {
      test('room 4x5m, brick, 20mm -> ~500kg Rotband', () {
        // Прораб ожидает ~500кг на кирпичную комнату 20м², 20мм
        final calculator = CalculatePlaster();
        final emptyPriceList = <PriceItem>[];

        final result = calculator({
          'area': 20.0,
          'thickness': 20.0,
          'type': 1.0,
          'substrateType': 2.0, // новый кирпич 1.15×
          'wallEvenness': 2.0,  // неровная 1.15×
        }, emptyPriceList);

        // 20 * 8.5 * 2.0 * 1.15 * 1.15 * 1.1 = 493.35 кг
        expect(result.values['plasterKg'], closeTo(493, 30));
      });
    });
  });
}
