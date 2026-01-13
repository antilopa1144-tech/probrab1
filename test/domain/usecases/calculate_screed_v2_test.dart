// ignore_for_file: unnecessary_null_checks

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateScreedV2', () {
    late CalculateScreedV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateScreedV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('cement-sand screed, 20 sqm, 50mm thickness', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0, // cement-sand
          'needMesh': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // volume = 20 * 0.05 = 1 m³
        expect(result.values['volume'], closeTo(1.0, 0.01));
        // cementKg = 1 * 400 = 400 kg
        expect(result.values['cementKg'], closeTo(400.0, 0.1));
        // cementBags = ceil(400 / 50) = 8
        expect(result.values['cementBags'], equals(8));
        // sandKg = 1 * 1200 = 1200 kg
        expect(result.values['sandKg'], closeTo(1200.0, 0.1));
        // sandCbm = 1200 / 1500 = 0.8 m³
        expect(result.values['sandCbm'], closeTo(0.8, 0.01));
      });

      test('different screed types use different cement amounts', () {
        final cementSandInputs = {
          'area': 10.0,
          'thickness': 100.0, // 1 m³ for easier calculation
          'screedType': 0.0, // cement-sand (400 kg/m³)
          'needMesh': 0.0,
          'needFilm': 0.0,
        };
        final semidryInputs = {
          'area': 10.0,
          'thickness': 100.0,
          'screedType': 1.0, // semidry (350 kg/m³)
          'needMesh': 0.0,
          'needFilm': 0.0,
        };
        final concreteInputs = {
          'area': 10.0,
          'thickness': 100.0,
          'screedType': 2.0, // concrete (300 kg/m³)
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final cementSandResult = calculator(cementSandInputs, emptyPriceList);
        final semidryResult = calculator(semidryInputs, emptyPriceList);
        final concreteResult = calculator(concreteInputs, emptyPriceList);

        // Cement-sand uses most cement
        expect(cementSandResult.values['cementKg'], equals(400.0));
        expect(semidryResult.values['cementKg'], equals(350.0));
        expect(concreteResult.values['cementKg'], equals(300.0));
      });
    });

    group('Room dimensions input', () {
      test('calculates area from room dimensions', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 5 = 20 m²
        expect(result.values['area'], equals(20.0));
      });

      test('area input takes priority over room dimensions', () {
        final inputs = {
          'area': 30.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(30.0));
      });
    });

    group('Thickness variations', () {
      test('thicker screed needs more materials', () {
        final thinInputs = {
          'area': 20.0,
          'thickness': 30.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };
        final thickInputs = {
          'area': 20.0,
          'thickness': 100.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final thinResult = calculator(thinInputs, emptyPriceList);
        final thickResult = calculator(thickInputs, emptyPriceList);

        // Thick needs more cement
        expect(
          thickResult.values['cementKg']!,
          greaterThan(thinResult.values['cementKg']!),
        );
        // Ratio should be 100/30 = 3.33
        final ratio = thickResult.values['cementKg']! / thinResult.values['cementKg']!;
        expect(ratio, closeTo(100 / 30, 0.01));
      });
    });

    group('Mesh calculations', () {
      test('calculates mesh with 10% margin', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // meshArea = 20 * 1.1 = 22 m²
        expect(result.values['meshArea'], closeTo(22.0, 0.1));
        expect(result.values['needMesh'], equals(1.0));
      });

      test('no mesh when disabled', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['meshArea'], equals(0));
        expect(result.values['needMesh'], equals(0));
      });
    });

    group('Film calculations', () {
      test('calculates film with 15% margin', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // filmArea = 20 * 1.15 = 23 m²
        expect(result.values['filmArea'], closeTo(23.0, 0.1));
        expect(result.values['needFilm'], equals(1.0));
      });

      test('no film when disabled', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['filmArea'], equals(0));
        expect(result.values['needFilm'], equals(0));
      });
    });

    group('Screed type consumption rates', () {
      final testCases = <(int, double, double)>[
        (0, 400.0, 1200.0), // cement-sand
        (1, 350.0, 1050.0), // semidry
        (2, 300.0, 900.0),  // concrete
      ];

      for (final (screedType, cementRate, sandRate) in testCases) {
        test('screedType=$screedType → cement=$cementRate, sand=$sandRate', () {
          final inputs = {
            'area': 10.0,
            'thickness': 100.0, // 1 m³ for easy calculation
            'screedType': screedType.toDouble(),
            'needMesh': 0.0,
            'needFilm': 0.0,
          };

          final result = calculator(inputs, emptyPriceList);

          expect(result.values['cementKg'], equals(cementRate));
          expect(result.values['sandKg'], equals(sandRate));
        });
      }
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(50.0));
        expect(result.values['screedType'], equals(0)); // cement-sand
        expect(result.values['needMesh'], equals(1)); // enabled
        expect(result.values['needFilm'], equals(1)); // enabled
      });
    });

    group('Edge cases', () {
      test('clamps screedType to valid range', () {
        final inputs = {
          'area': 20.0,
          'screedType': 99.0, // Invalid, should clamp to 2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['screedType'], equals(2));
      });

      test('clamps thickness to valid range', () {
        final inputs = {
          'area': 20.0,
          'thickness': 200.0, // Invalid, should clamp to 150
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(150.0));
      });

      test('handles small area correctly', () {
        final inputs = {
          'area': 3.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['volume'], greaterThan(0));
        expect(result.values['cementBags'], greaterThan(0));
      });

      test('handles large area correctly', () {
        final inputs = {
          'area': 500.0,
          'thickness': 100.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // volume = 500 * 0.1 = 50 m³
        expect(result.values['volume'], closeTo(50.0, 0.1));
        // cementKg = 50 * 400 = 20000 kg
        expect(result.values['cementKg'], closeTo(20000.0, 1.0));
        // cementBags = ceil(20000/50) = 400
        expect(result.values['cementBags'], equals(400));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area without dimensions', () {
        final inputs = {
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'area': -10.0,
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
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'cement', name: 'Цемент', price: 350.0, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 1500.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'mesh', name: 'Сетка', price: 50.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'film', name: 'Плёнка', price: 30.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice!, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical room screed installation', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 m²
        expect(result.values['area'], equals(20.0));
        // Volume = 1 m³
        expect(result.values['volume'], closeTo(1.0, 0.01));
        // Cement: 8 bags (400 kg)
        expect(result.values['cementBags'], equals(8));
        // Sand: 0.8 m³
        expect(result.values['sandCbm'], closeTo(0.8, 0.01));
        // Mesh: 22 m²
        expect(result.values['meshArea'], closeTo(22.0, 0.1));
        // Film: 23 m²
        expect(result.values['filmArea'], closeTo(23.0, 0.1));
      });

      test('minimal installation without extras', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['meshArea'], equals(0));
        expect(result.values['filmArea'], equals(0));
        // Still has cement and sand
        expect(result.values['cementBags'], greaterThan(0));
        expect(result.values['sandCbm'], greaterThan(0));
      });
    });
  });
}
