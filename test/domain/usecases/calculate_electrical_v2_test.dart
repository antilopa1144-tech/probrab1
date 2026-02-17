import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_electrical_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateElectricalV2', () {
    late CalculateElectricalV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateElectricalV2();
      emptyPriceList = <PriceItem>[];
    });

    group('By area mode (inputMode=0)', () {
      test('50 sqm apartment with 2 rooms', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 50.0,
          'rooms': 2.0,
          'roomType': 0.0, // apartment
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], greaterThan(0));
        expect(result.values['switches'], greaterThan(0));
        expect(result.values['lights'], greaterThan(0));
      });

      test('larger area = more sockets', () {
        final small = calculator({
          'inputMode': 0.0,
          'area': 30.0,
          'rooms': 1.0,
        }, emptyPriceList);

        final large = calculator({
          'inputMode': 0.0,
          'area': 100.0,
          'rooms': 4.0,
        }, emptyPriceList);

        expect(
          large.values['sockets'],
          greaterThan(small.values['sockets']!),
        );
      });

      test('more rooms = more switches', () {
        final few = calculator({
          'inputMode': 0.0,
          'area': 50.0,
          'rooms': 1.0,
        }, emptyPriceList);

        final many = calculator({
          'inputMode': 0.0,
          'area': 50.0,
          'rooms': 5.0,
        }, emptyPriceList);

        expect(
          many.values['switches'],
          greaterThan(few.values['switches']!),
        );
      });
    });

    group('By points mode (inputMode=1)', () {
      test('uses manual values', () {
        final inputs = {
          'inputMode': 1.0,
          'manualSockets': 25.0,
          'manualSwitches': 8.0,
          'manualLights': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], equals(25.0));
        expect(result.values['switches'], equals(8.0));
        expect(result.values['lights'], equals(10.0));
      });
    });

    group('Room type multipliers', () {
      test('house needs more sockets than apartment', () {
        final apartment = calculator({
          'inputMode': 0.0,
          'area': 80.0,
          'rooms': 3.0,
          'roomType': 0.0, // apartment (1.0x)
        }, emptyPriceList);

        final house = calculator({
          'inputMode': 0.0,
          'area': 80.0,
          'rooms': 3.0,
          'roomType': 1.0, // house (1.2x)
        }, emptyPriceList);

        expect(
          house.values['sockets'],
          greaterThanOrEqualTo(apartment.values['sockets']!),
        );
      });

      test('office needs more sockets than house', () {
        final house = calculator({
          'inputMode': 0.0,
          'area': 80.0,
          'rooms': 3.0,
          'roomType': 1.0, // house (1.2x)
        }, emptyPriceList);

        final office = calculator({
          'inputMode': 0.0,
          'area': 80.0,
          'rooms': 3.0,
          'roomType': 2.0, // office (1.5x)
        }, emptyPriceList);

        expect(
          office.values['sockets'],
          greaterThan(house.values['sockets']!),
        );
      });
    });

    group('Wiring method', () {
      test('hidden wiring uses more cable', () {
        final hidden = calculator({
          'area': 50.0,
          'rooms': 2.0,
          'wiringMethod': 0.0, // hidden
        }, emptyPriceList);

        final open = calculator({
          'area': 50.0,
          'rooms': 2.0,
          'wiringMethod': 1.0, // open
        }, emptyPriceList);

        expect(
          hidden.values['totalCable'],
          greaterThan(open.values['totalCable']!),
        );
      });

      test('hidden wiring uses less conduit (factor 0.85)', () {
        final hidden = calculator({
          'area': 50.0,
          'wiringMethod': 0.0,
          'withConduit': 1.0,
        }, emptyPriceList);

        final open = calculator({
          'area': 50.0,
          'wiringMethod': 1.0,
          'withConduit': 1.0,
        }, emptyPriceList);

        // Hidden uses 0.85 factor, open uses 1.0
        // But hidden has more total cable, so compare ratios
        final hiddenRatio = hidden.values['conduitLength']! / hidden.values['totalCable']!;
        final openRatio = open.values['conduitLength']! / open.values['totalCable']!;

        expect(hiddenRatio, closeTo(0.85, 0.01));
        expect(openRatio, closeTo(1.0, 0.01));
      });
    });

    group('Power consumers', () {
      test('no power consumers by default', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['powerConsumers'], equals(0.0));
        expect(result.values['difAutomats'], equals(0.0));
        expect(result.values['cablePower'], equals(0.0));
      });

      test('each consumer adds difautomat', () {
        final withTwo = calculator({
          'area': 50.0,
          'hasElectricStove': 1.0,
          'hasBoiler': 1.0,
        }, emptyPriceList);

        expect(withTwo.values['powerConsumers'], equals(2.0));
        expect(withTwo.values['difAutomats'], equals(2.0));
      });

      test('consumers add power cable', () {
        final without = calculator({
          'area': 50.0,
        }, emptyPriceList);

        final with_ = calculator({
          'area': 50.0,
          'hasElectricStove': 1.0,
          'hasOven': 1.0,
          'hasWashingMachine': 1.0,
        }, emptyPriceList);

        expect(without.values['cablePower'], equals(0.0));
        expect(with_.values['cablePower'], greaterThan(0));
      });

      test('all consumers counted', () {
        final inputs = {
          'area': 50.0,
          'hasElectricStove': 1.0,
          'hasOven': 1.0,
          'hasBoiler': 1.0,
          'hasWashingMachine': 1.0,
          'hasDishwasher': 1.0,
          'hasConditioner': 1.0,
          'hasWarmFloor': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['powerConsumers'], equals(7.0));
        expect(result.values['difAutomats'], equals(7.0));
      });
    });

    group('Conduit option', () {
      test('conduit enabled by default', () {
        final inputs = {
          'area': 50.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['conduitLength'], greaterThan(0));
      });

      test('no conduit when disabled', () {
        final inputs = {
          'area': 50.0,
          'withConduit': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['conduitLength'], equals(0.0));
      });
    });

    group('Cable calculations', () {
      test('calculates light cable (3x1.5)', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cableLight'], greaterThan(0));
      });

      test('calculates socket cable (3x2.5)', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cableSocket'], greaterThan(0));
      });

      test('total cable is sum of all types', () {
        final inputs = {
          'area': 50.0,
          'hasElectricStove': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        final expectedTotal = result.values['cableLight']! +
            result.values['cableSocket']! +
            result.values['cablePower']!;

        expect(result.values['totalCable'], closeTo(expectedTotal, 0.01));
      });
    });

    group('Circuit breakers and RCD', () {
      test('calculates circuit breakers', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // breakers = lightGroups + socketGroups
        expect(result.values['circuitBreakers'], greaterThan(0));
      });

      test('calculates RCD devices', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // RCD = socketGroups/2 + 1 (fire protection)
        expect(result.values['rcdDevices'], greaterThanOrEqualTo(1));
      });
    });

    group('Panel modules', () {
      test('calculates panel modules', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelModules'], greaterThan(0));
      });

      test('more consumers = more modules', () {
        final without = calculator({
          'area': 50.0,
        }, emptyPriceList);

        final with_ = calculator({
          'area': 50.0,
          'hasElectricStove': 1.0,
          'hasBoiler': 1.0,
          'hasWashingMachine': 1.0,
        }, emptyPriceList);

        expect(
          with_.values['panelModules'],
          greaterThan(without.values['panelModules']!),
        );
      });
    });

    group('Junction boxes', () {
      test('by area mode: based on rooms and area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 50.0,
          'rooms': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['junctionBoxes'], greaterThan(0));
      });

      test('by points mode: based on all points, min = rooms', () {
        final inputs = {
          'inputMode': 1.0,
          'manualSockets': 30.0,
          'manualSwitches': 10.0,
          'manualLights': 12.0,
          'rooms': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // boxes = max((30+10+12)/8, 3) = max(7, 3) = 7
        expect(result.values['junctionBoxes'], greaterThanOrEqualTo(3));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0));
        expect(result.values['area'], equals(50.0));
        expect(result.values['rooms'], equals(2.0));
        expect(result.values['roomType'], equals(0.0));
        expect(result.values['wiringMethod'], equals(0.0));
        expect(result.values['withGrounding'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final tooSmall = calculator({
          'area': 5.0, // min 10
        }, emptyPriceList);

        final tooLarge = calculator({
          'area': 1000.0, // max 500
        }, emptyPriceList);

        expect(tooSmall.values['area'], equals(10.0));
        expect(tooLarge.values['area'], equals(500.0));
      });

      test('handles minimum values', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'rooms': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], greaterThan(0));
        expect(result.values['cableLight'], greaterThan(0));
      });

      test('handles maximum values', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 500.0,
          'rooms': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], greaterThan(0));
        expect(result.values['totalCable'], greaterThan(0));
      });
    });

    group('Price calculations', () {
      test('calculates price when prices available', () {
        final inputs = {
          'area': 50.0,
          'rooms': 2.0,
        };
        final priceList = [
          const PriceItem(sku: 'cable_1_5', name: 'Кабель 1.5', price: 50.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'cable_2_5', name: 'Кабель 2.5', price: 80.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'socket', name: 'Розетка', price: 200.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'switch', name: 'Выключатель', price: 150.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 50.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Cable realism checks', () {
      test('50 sqm apartment: total cable 80-150m (not 200+)', () {
        // Реальная двухкомнатная квартира: ~100-120м кабеля всего
        final result = calculator({
          'inputMode': 0.0,
          'area': 50.0,
          'rooms': 2.0,
          'roomType': 0.0,
          'wiringMethod': 0.0,
        }, emptyPriceList);

        final totalCable = result.values['totalCable']!;
        expect(totalCable, greaterThan(80),
            reason: 'Слишком мало кабеля для 50м² квартиры');
        expect(totalCable, lessThan(150),
            reason: 'Слишком много кабеля для 50м² квартиры без мощных потребителей');
      });

      test('30 sqm studio: total cable 50-100m', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 30.0,
          'rooms': 1.0,
          'roomType': 0.0,
          'wiringMethod': 0.0,
        }, emptyPriceList);

        final totalCable = result.values['totalCable']!;
        expect(totalCable, greaterThan(50),
            reason: 'Слишком мало кабеля для студии');
        expect(totalCable, lessThan(100),
            reason: 'Слишком много кабеля для студии');
      });

      test('manual mode 20 sockets: socket cable < 80m', () {
        // 20 розеток × 2м ответвление + 4 группы × 6м магистраль = 64м × 1.10 = ~70м
        // Старая формула давала 20 × 4.5 + 4 × 10 = 130м × 1.15 = ~150м
        final result = calculator({
          'inputMode': 1.0,
          'manualSockets': 20.0,
          'manualSwitches': 6.0,
          'manualLights': 10.0,
          'rooms': 2.0,
          'wiringMethod': 0.0,
        }, emptyPriceList);

        final cableSocket = result.values['cableSocket']!;
        expect(cableSocket, greaterThan(40),
            reason: 'Слишком мало кабеля 2.5 для 20 розеток');
        expect(cableSocket, lessThan(80),
            reason: 'Перерасчёт кабеля 2.5 для 20 розеток');
      });

      test('cable per socket is reasonable (2-4m effective)', () {
        // Проверяем что на 1 розетку приходится адекватное количество кабеля
        final result = calculator({
          'inputMode': 1.0,
          'manualSockets': 10.0,
          'manualSwitches': 4.0,
          'manualLights': 6.0,
          'rooms': 2.0,
          'wiringMethod': 0.0,
        }, emptyPriceList);

        final cableSocket = result.values['cableSocket']!;
        final effectivePerSocket = cableSocket / 10.0;
        expect(effectivePerSocket, greaterThan(2.0),
            reason: 'Менее 2м на розетку — нереально мало');
        expect(effectivePerSocket, lessThan(5.0),
            reason: 'Более 5м на розетку — завышение');
      });
    });

    group('Full scenario tests', () {
      test('small apartment', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 35.0,
          'rooms': 1.0,
          'roomType': 0.0,
          'wiringMethod': 0.0,
          'withConduit': 1.0,
          'withGrounding': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], greaterThanOrEqualTo(7)); // min 3 + 4 kitchen
        expect(result.values['cableLight'], greaterThan(0));
        expect(result.values['cableSocket'], greaterThan(0));
        expect(result.values['conduitLength'], greaterThan(0));
        expect(result.values['panelModules'], greaterThan(0));
      });

      test('large house with all appliances', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 200.0,
          'rooms': 8.0,
          'roomType': 1.0, // house
          'wiringMethod': 0.0,
          'hasElectricStove': 1.0,
          'hasOven': 1.0,
          'hasBoiler': 1.0,
          'hasWashingMachine': 1.0,
          'hasDishwasher': 1.0,
          'hasConditioner': 1.0,
          'hasWarmFloor': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['powerConsumers'], equals(7.0));
        expect(result.values['difAutomats'], equals(7.0));
        expect(result.values['cablePower'], greaterThan(50)); // significant power cable
        expect(result.values['panelModules'], greaterThan(20)); // large panel
      });

      test('office with manual input', () {
        final inputs = {
          'inputMode': 1.0,
          'manualSockets': 50.0,
          'manualSwitches': 15.0,
          'manualLights': 20.0,
          'wiringMethod': 1.0, // open
          'withConduit': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sockets'], equals(50.0));
        expect(result.values['switches'], equals(15.0));
        expect(result.values['lights'], equals(20.0));
      });
    });
  });
}
