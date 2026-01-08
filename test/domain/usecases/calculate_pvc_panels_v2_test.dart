import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_pvc_panels_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePvcPanelsV2', () {
    late CalculatePvcPanelsV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculatePvcPanelsV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('3x2.5 wall, wall panels', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelWidth': 0.25,
          'panelType': 0.0, // wall
          'inputMode': 1.0, // dimensions mode
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 3 * 2.5 = 7.5 sqm
        expect(result.values['area'], equals(7.5));
        // Panel area = 0.25 * 2.7 = 0.675 sqm
        expect(result.values['panelArea'], closeTo(0.675, 0.01));
        // Panels = ceil(7.5 * 1.1 / 0.675) = ceil(12.22) = 13
        expect(result.values['panelsCount'], equals(13.0));
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
      test('wall panels: length = 2.7m', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 0.0, // wall
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelLength'], equals(2.7));
      });

      test('ceiling panels: length = 3.0m', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 1.0, // ceiling
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelLength'], equals(3.0));
      });

      test('bathroom panels: length = 2.7m', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 2.0, // bathroom
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelLength'], equals(2.7));
      });

      test('ceiling panels include plinth', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 1.0, // ceiling
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Plinth = 2 * (3 + 2.5) = 11
        expect(result.values['plinthLength'], equals(11.0));
        // Plinth pieces = ceil(11 / 3) = 4
        expect(result.values['plinthPieces'], equals(4.0));
      });

      test('wall panels do not include plinth', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 0.0, // wall
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['plinthLength'], equals(0.0));
        expect(result.values['plinthPieces'], equals(0.0));
      });
    });

    group('Panel width', () {
      test('wider panels = fewer panels', () {
        final narrowInputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelWidth': 0.1, // 100mm
          'inputMode': 1.0,
        };
        final wideInputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelWidth': 0.5, // 500mm
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
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelWidth': 0.3, // 300mm
          'panelType': 0.0, // wall (2.7m)
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Panel area = 0.3 * 2.7 = 0.81 sqm
        expect(result.values['panelArea'], closeTo(0.81, 0.01));
      });
    });

    group('Profile calculations', () {
      test('profile calculated when needed', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'needProfile': 1.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rows = ceil(2.5 / 0.4) + 1 = 7 + 1 = 8
        // Profile = 8 * 3 * 1.1 = 26.4
        expect(result.values['profileLength'], closeTo(26.4, 0.1));
      });

      test('no profile when not needed', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'needProfile': 0.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['profileLength'], equals(0.0));
      });

      test('more profile for taller wall', () {
        final shortInputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.0,
          'needProfile': 1.0,
          'inputMode': 1.0,
        };
        final tallInputs = {
          'wallWidth': 3.0,
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

    group('Corner calculations', () {
      test('corners calculated when needed', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'needCorners': 1.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Corners = ceil(2.5 * 4 / 3) = ceil(3.33) = 4
        expect(result.values['cornerCount'], equals(4.0));
      });

      test('no corners when not needed', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'needCorners': 0.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cornerCount'], equals(0.0));
      });

      test('more corners for taller wall', () {
        final shortInputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.0,
          'needCorners': 1.0,
          'inputMode': 1.0,
        };
        final tallInputs = {
          'wallWidth': 3.0,
          'wallHeight': 4.0,
          'needCorners': 1.0,
          'inputMode': 1.0,
        };

        final shortResult = calculator(shortInputs, emptyPriceList);
        final tallResult = calculator(tallInputs, emptyPriceList);

        expect(
          tallResult.values['cornerCount'],
          greaterThan(shortResult.values['cornerCount']!),
        );
      });
    });

    group('Input modes', () {
      test('dimensions mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 4.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(12.0));
        expect(result.values['wallWidth'], equals(4.0));
        expect(result.values['wallHeight'], equals(3.0));
      });

      test('manual mode uses area and calculates dimensions', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 15.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(15.0));
        // Dimensions calculated from sqrt(15) * 1.5 and sqrt(15) / 1.5
        expect(result.values['wallWidth'], greaterThan(0));
        expect(result.values['wallHeight'], greaterThan(0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'area': 15.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0)); // manual mode
        expect(result.values['panelType'], equals(0.0)); // wall
        expect(result.values['panelWidth'], equals(0.25)); // 250mm
        expect(result.values['needProfile'], equals(1.0)); // yes
        expect(result.values['needCorners'], equals(1.0)); // yes
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

      test('handles small bathroom', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 1.5,
          'wallHeight': 2.5,
          'panelType': 2.0, // bathroom
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(3.75));
        expect(result.values['panelsCount'], greaterThan(0));
      });

      test('handles large wall', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 10.0,
          'wallHeight': 4.0,
          'panelType': 0.0, // wall
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
          'area': -15.0,
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
          'wallHeight': 2.5,
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
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'panelType': 1.0, // ceiling (includes plinth)
          'inputMode': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'pvc_panel', name: 'ПВХ панель', price: 150.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 50.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'corner', name: 'Угол', price: 80.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'plinth', name: 'Плинтус', price: 120.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'wallWidth': 3.0,
          'wallHeight': 2.5,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical bathroom wall', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 2.0,
          'wallHeight': 2.5,
          'panelType': 2.0, // bathroom
          'panelWidth': 0.25,
          'needProfile': 1.0,
          'needCorners': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 2 * 2.5 = 5
        expect(result.values['area'], equals(5.0));
        // Panel area = 0.25 * 2.7 = 0.675
        // Panels = ceil(5 * 1.1 / 0.675) = ceil(8.15) = 9
        expect(result.values['panelsCount'], equals(9.0));
        // No plinth for bathroom
        expect(result.values['plinthPieces'], equals(0.0));
      });

      test('ceiling with plinth', () {
        final inputs = {
          'inputMode': 1.0,
          'wallWidth': 4.0,
          'wallHeight': 3.0,
          'panelType': 1.0, // ceiling
          'panelWidth': 0.25,
        };

        final result = calculator(inputs, emptyPriceList);

        // Panel length = 3.0 for ceiling
        expect(result.values['panelLength'], equals(3.0));
        // Plinth = 2 * (4 + 3) = 14
        expect(result.values['plinthLength'], equals(14.0));
        // Plinth pieces = ceil(14 / 3) = 5
        expect(result.values['plinthPieces'], equals(5.0));
      });

      test('manual mode calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'panelType': 0.0, // wall
          'panelWidth': 0.3,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20
        expect(result.values['area'], equals(20.0));
        // Panel area = 0.3 * 2.7 = 0.81
        // Panels = ceil(20 * 1.1 / 0.81) = ceil(27.16) = 28
        expect(result.values['panelsCount'], equals(28.0));
      });
    });
  });
}
