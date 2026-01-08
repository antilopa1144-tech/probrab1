import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_mdf_panels_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateMdfPanelsV2', () {
    late CalculateMdfPanelsV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateMdfPanelsV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('4x2.7 wall, 250mm panels', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelWidth': 0.25,
          'panelType': 1.0, // laminated
          'inputMode': 1.0, // wall mode
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 2.7 = 10.8 sqm
        expect(result.values['area'], closeTo(10.8, 0.01));
        // Panel area = 0.25 * 2.7 = 0.675 sqm
        expect(result.values['panelArea'], closeTo(0.675, 0.01));
        // Panels = ceil(10.8 * 1.1 / 0.675) = ceil(17.6) = 18
        expect(result.values['panelsCount'], equals(18.0));
        // Clips = 18 * 5 = 90
        expect(result.values['clipsCount'], equals(90.0));
      });

      test('larger wall needs more panels', () {
        final smallInputs = {
          'wallWidth': 2.0,
          'wallHeight': 2.0,
          'panelWidth': 0.25,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'wallWidth': 5.0,
          'wallHeight': 3.0,
          'panelWidth': 0.25,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['panelsCount'],
          greaterThan(smallResult.values['panelsCount']!),
        );
      });
    });

    group('Panel types', () {
      test('stores panel type correctly', () {
        final standard = calculator({
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelType': 0.0, // standard
          'inputMode': 1.0,
        }, emptyPriceList);
        final laminated = calculator({
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelType': 1.0, // laminated
          'inputMode': 1.0,
        }, emptyPriceList);
        final veneer = calculator({
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelType': 2.0, // veneer
          'inputMode': 1.0,
        }, emptyPriceList);

        expect(standard.values['panelType'], equals(0.0));
        expect(laminated.values['panelType'], equals(1.0));
        expect(veneer.values['panelType'], equals(2.0));
      });
    });

    group('Panel width', () {
      test('wider panels = fewer panels', () {
        final narrowInputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelWidth': 0.1, // 100mm
          'inputMode': 1.0,
        };
        final wideInputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelWidth': 0.4, // 400mm
          'inputMode': 1.0,
        };

        final narrowResult = calculator(narrowInputs, emptyPriceList);
        final wideResult = calculator(wideInputs, emptyPriceList);

        expect(
          wideResult.values['panelsCount'],
          lessThan(narrowResult.values['panelsCount']!),
        );
      });

      test('panel area calculated correctly', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelWidth': 0.3, // 300mm
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Panel area = 0.3 * 2.7 = 0.81 sqm
        expect(result.values['panelArea'], closeTo(0.81, 0.01));
      });
    });

    group('Clips calculations', () {
      test('clips = panels * 5', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'panelWidth': 0.25,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final panelsCount = result.values['panelsCount']!;

        expect(result.values['clipsCount'], equals(panelsCount * 5));
      });

      test('more clips for larger wall', () {
        final smallInputs = {
          'wallWidth': 2.0,
          'wallHeight': 2.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'wallWidth': 6.0,
          'wallHeight': 3.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['clipsCount'],
          greaterThan(smallResult.values['clipsCount']!),
        );
      });
    });

    group('Profile calculations', () {
      test('profile calculated when needed', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'needProfile': 1.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Horizontal profiles = ceil(2.7 / 0.5) + 1 = 6 + 1 = 7
        // Profile = 7 * 4 * 1.1 = 30.8
        expect(result.values['profileLength'], closeTo(30.8, 0.1));
      });

      test('no profile when not needed', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'needProfile': 0.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['profileLength'], equals(0.0));
      });

      test('more profile for taller wall', () {
        final shortInputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.0,
          'needProfile': 1.0,
          'inputMode': 1.0,
        };
        final tallInputs = {
          'wallWidth': 4.0,
          'wallHeight': 4.0,
          'needProfile': 1.0,
          'inputMode': 1.0,
        };

        final shortResult = calculator(shortInputs, emptyPriceList);
        final tallResult = calculator(tallInputs, emptyPriceList);

        expect(
          tallResult.values['profileLength'],
          greaterThan(shortResult.values['profileLength']!),
        );
      });
    });

    group('Plinth calculations', () {
      test('plinth calculated when needed', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'needPlinth': 1.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Plinth length = 4 * 2 + 2 = 10
        expect(result.values['plinthLength'], equals(10.0));
        // Plinth pieces = ceil(10 / 2.7) = 4
        expect(result.values['plinthPieces'], equals(4.0));
      });

      test('no plinth when not needed', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'needPlinth': 0.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plinthLength'], equals(0.0));
        expect(result.values['plinthPieces'], equals(0.0));
      });

      test('wider wall needs more plinth', () {
        final narrowInputs = {
          'wallWidth': 2.0,
          'wallHeight': 2.7,
          'needPlinth': 1.0,
          'inputMode': 1.0,
        };
        final wideInputs = {
          'wallWidth': 8.0,
          'wallHeight': 2.7,
          'needPlinth': 1.0,
          'inputMode': 1.0,
        };

        final narrowResult = calculator(narrowInputs, emptyPriceList);
        final wideResult = calculator(wideInputs, emptyPriceList);

        expect(
          wideResult.values['plinthPieces'],
          greaterThan(narrowResult.values['plinthPieces']!),
        );
      });
    });

    group('Input modes', () {
      test('wall mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 5.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(15.0));
        expect(result.values['wallWidth'], equals(5.0));
        expect(result.values['wallHeight'], equals(3.0));
      });

      test('manual mode uses area and calculates dimensions', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(20.0));
        // Dimensions calculated from sqrt(20) * 1.5 and sqrt(20) / 1.5
        expect(result.values['wallWidth'], greaterThan(0));
        expect(result.values['wallHeight'], greaterThan(0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0)); // manual mode
        expect(result.values['panelType'], equals(1.0)); // laminated
        expect(result.values['panelWidth'], equals(0.25)); // 250mm
        expect(result.values['needProfile'], equals(1.0)); // yes
        expect(result.values['needPlinth'], equals(1.0)); // yes
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1000.0, // Invalid, should clamp to 500
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(500.0));
      });

      test('clamps wall dimensions to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 100.0, // Invalid, should clamp to 30
          'wallHeight': 50.0, // Invalid, should clamp to 10
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallWidth'], equals(30.0));
        expect(result.values['wallHeight'], equals(10.0));
      });

      test('handles small wall', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 1.0,
          'wallHeight': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(2.0));
        expect(result.values['panelsCount'], greaterThan(0));
        expect(result.values['clipsCount'], greaterThan(0));
      });

      test('handles large wall', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 10.0,
          'wallHeight': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(40.0));
        expect(result.values['panelsCount'], greaterThan(0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area in manual mode', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': -20.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero wall width', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 0.0,
          'wallHeight': 2.7,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'inputMode': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'mdf_panel', name: 'МДФ панель', price: 200.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'clips', name: 'Кляймер', price: 5.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 50.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'plinth', name: 'Плинтус', price: 150.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'wallWidth': 4.0,
          'wallHeight': 2.7,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical living room wall', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 5.0,
          'wallHeight': 2.7,
          'panelType': 1.0, // laminated
          'panelWidth': 0.25,
          'needProfile': 1.0,
          'needPlinth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 5 * 2.7 = 13.5
        expect(result.values['area'], equals(13.5));
        // Panels = ceil(13.5 * 1.1 / 0.675) = ceil(22) = 22
        expect(result.values['panelsCount'], equals(22.0));
        // Clips = 22 * 5 = 110
        expect(result.values['clipsCount'], equals(110.0));
        // Plinth = 5 * 2 + 2 = 12
        expect(result.values['plinthLength'], equals(12.0));
      });

      test('hallway wall without plinth', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 0.0, // standard
          'panelWidth': 0.2,
          'needProfile': 1.0,
          'needPlinth': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 3 * 2.5 = 7.5
        expect(result.values['area'], equals(7.5));
        // No plinth
        expect(result.values['plinthPieces'], equals(0.0));
        // Profile still calculated
        expect(result.values['profileLength'], greaterThan(0));
      });

      test('manual mode calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 15.0,
          'panelType': 2.0, // veneer
          'panelWidth': 0.3,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 15
        expect(result.values['area'], equals(15.0));
        // Panel area = 0.3 * 2.7 = 0.81
        // Panels = ceil(15 * 1.1 / 0.81) = ceil(20.37) = 21
        expect(result.values['panelsCount'], equals(21.0));
        // Clips = 21 * 5 = 105
        expect(result.values['clipsCount'], equals(105.0));
      });
    });
  });
}
