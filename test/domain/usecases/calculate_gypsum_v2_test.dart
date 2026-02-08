import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gypsum_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateGypsumV2', () {
    late CalculateGypsumV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateGypsumV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Input modes', () {
      test('by area mode (default)', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['calculatedArea'], equals(25.0));
      });

      test('by room dimensions - wall lining', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 5.0,
          'width': 4.0,
          'height': 3.0,
          'constructionType': 0.0, // wall lining
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter × height = (5+4)*2*3 = 54 sqm
        expect(result.values['calculatedArea'], equals(54.0));
      });

      test('by room dimensions - partition', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 5.0,
          'height': 3.0,
          'constructionType': 1.0, // partition
        };

        final result = calculator(inputs, emptyPriceList);

        // Length × height = 5*3 = 15 sqm
        expect(result.values['calculatedArea'], equals(15.0));
      });

      test('by room dimensions - ceiling', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 5.0,
          'width': 4.0,
          'constructionType': 2.0, // ceiling
        };

        final result = calculator(inputs, emptyPriceList);

        // Length × width = 5*4 = 20 sqm
        expect(result.values['calculatedArea'], equals(20.0));
      });
    });

    group('GKL sheets calculation', () {
      test('calculates sheets based on area and sheet size', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 30.0, // 30 sqm
          'sheetSize': 1.0, // 2500x1200 = 3.0 sqm
          'layers': 1.0,
          'constructionType': 0.0, // wall lining (1x multiplier)
        };

        final result = calculator(inputs, emptyPriceList);

        // 30 * 1.05 / 3.0 = 10.5 -> 11 sheets
        expect(result.values['gklSheets'], equals(11.0));
      });

      test('partition needs double sheets', () {
        final wallLining = calculator({
          'inputMode': 0.0,
          'area': 20.0,
          'constructionType': 0.0, // wall lining
        }, emptyPriceList);

        final partition = calculator({
          'inputMode': 0.0,
          'area': 20.0,
          'constructionType': 1.0, // partition (2x)
        }, emptyPriceList);

        expect(
          partition.values['gklSheets'],
          greaterThan(wallLining.values['gklSheets']!),
        );
      });

      test('two layers need more sheets', () {
        final oneLayer = calculator({
          'area': 20.0,
          'layers': 1.0,
        }, emptyPriceList);

        final twoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
        }, emptyPriceList);

        expect(
          twoLayers.values['gklSheets'],
          greaterThan(oneLayer.values['gklSheets']!),
        );
      });

      test('different sheet sizes affect count', () {
        final small = calculator({
          'area': 30.0,
          'sheetSize': 0.0, // 2000x1200 = 2.4 sqm
        }, emptyPriceList);

        final large = calculator({
          'area': 30.0,
          'sheetSize': 3.0, // 3000x1200 = 3.6 sqm
        }, emptyPriceList);

        expect(
          small.values['gklSheets'],
          greaterThan(large.values['gklSheets']!),
        );
      });
    });

    group('Construction types - Wall lining', () {
      test('wall lining profile calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'constructionType': 0.0, // wall lining
        };

        final result = calculator(inputs, emptyPriceList);

        // PN = 20 * 0.8 = 16m
        // PP = 20 * 2.0 = 40m
        expect(result.values['pnMeters'], equals(16.0));
        expect(result.values['ppMeters'], equals(40.0));
        expect(result.values['pnPieces'], equals(6.0)); // ceil(16/3)
        expect(result.values['ppPieces'], equals(14.0)); // ceil(40/3)
      });

      test('wall lining has suspensions', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 0.0, // wall lining
        };

        final result = calculator(inputs, emptyPriceList);

        // Suspensions = 20 * 1.3 = 26
        expect(result.values['suspensions'], equals(26.0));
        expect(result.values['connectors'], equals(0.0));
      });
    });

    group('Construction types - Partition', () {
      test('partition profile calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'constructionType': 1.0, // partition
        };

        final result = calculator(inputs, emptyPriceList);

        // PN = 20 * 0.7 = 14m
        // PP = 20 * 2.0 = 40m
        expect(result.values['pnMeters'], equals(14.0));
        expect(result.values['ppMeters'], equals(40.0));
      });

      test('partition has more screws', () {
        // Use thickness 0 (9.5mm) to get TN25 screws
        final wallLining = calculator({
          'area': 20.0,
          'constructionType': 0.0,
          'thickness': 0.0, // 9.5mm -> TN25
        }, emptyPriceList);

        final partition = calculator({
          'area': 20.0,
          'constructionType': 1.0,
          'thickness': 0.0, // 9.5mm -> TN25
        }, emptyPriceList);

        // Partition: 50/sqm vs Wall lining: 34/sqm
        expect(
          partition.values['screwsTN25'],
          greaterThan(wallLining.values['screwsTN25']!),
        );
      });

      test('partition has more screws (12.5mm uses TN35)', () {
        // Default thickness 1 (12.5mm) -> TN35 screws
        final wallLining = calculator({
          'area': 20.0,
          'constructionType': 0.0,
          'thickness': 1.0, // 12.5mm -> TN35
        }, emptyPriceList);

        final partition = calculator({
          'area': 20.0,
          'constructionType': 1.0,
          'thickness': 1.0, // 12.5mm -> TN35
        }, emptyPriceList);

        // Partition: 50/sqm vs Wall lining: 34/sqm
        expect(
          partition.values['screwsTN35'],
          greaterThan(wallLining.values['screwsTN35']!),
        );
      });

      test('partition has no suspensions', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['suspensions'], equals(0.0));
      });
    });

    group('Construction types - Ceiling', () {
      test('ceiling profile calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'constructionType': 2.0, // ceiling
        };

        final result = calculator(inputs, emptyPriceList);

        // PN = 20 * 0.4 = 8m
        // PP = 20 * 3.3 = 66m
        expect(result.values['pnMeters'], equals(8.0));
        expect(result.values['ppMeters'], equals(66.0));
      });

      test('ceiling has connectors', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 2.0, // ceiling
        };

        final result = calculator(inputs, emptyPriceList);

        // Connectors = 20 * 2.4 = 48
        expect(result.values['connectors'], equals(48.0));
      });

      test('ceiling dowels based on suspensions', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Suspensions = 20 * 0.7 = 14
        // Dowels = 14 * 2 = 28
        expect(result.values['suspensions'], equals(14.0));
        expect(result.values['dowels'], equals(28.0));
      });
    });

    group('Layers', () {
      test('second layer adds TN35 screws (for 9.5mm sheets)', () {
        // For 9.5mm thickness, first layer uses TN25, second layer adds TN35
        final oneLayer = calculator({
          'area': 20.0,
          'layers': 1.0,
          'thickness': 0.0, // 9.5mm -> TN25 for first layer
        }, emptyPriceList);

        final twoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
          'thickness': 0.0, // 9.5mm -> TN25 + TN35 for second layer
        }, emptyPriceList);

        expect(oneLayer.values['screwsTN35'], equals(0.0));
        expect(twoLayers.values['screwsTN35'], greaterThan(0));
      });

      test('12.5mm sheets use TN35 for all layers', () {
        // For 12.5mm thickness, both layers use TN35
        final oneLayer = calculator({
          'area': 20.0,
          'layers': 1.0,
          'thickness': 1.0, // 12.5mm -> TN35
        }, emptyPriceList);

        final twoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
          'thickness': 1.0, // 12.5mm -> TN35 for both
        }, emptyPriceList);

        // Both have TN35
        expect(oneLayer.values['screwsTN35'], greaterThan(0));
        expect(oneLayer.values['screwsTN25'], equals(0.0));
        // Two layers has more TN35
        expect(twoLayers.values['screwsTN35'], greaterThan(oneLayer.values['screwsTN35']!));
      });

      test('partition two layers doubles TN35 screws', () {
        final wallLiningTwoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
          'constructionType': 0.0,
        }, emptyPriceList);

        final partitionTwoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
          'constructionType': 1.0,
        }, emptyPriceList);

        // Partition multiplier = 2
        expect(
          partitionTwoLayers.values['screwsTN35'],
          greaterThan(wallLiningTwoLayers.values['screwsTN35']!),
        );
      });

      test('filler amount scales with layers', () {
        final oneLayer = calculator({
          'area': 20.0,
          'layers': 1.0,
        }, emptyPriceList);

        final twoLayers = calculator({
          'area': 20.0,
          'layers': 2.0,
        }, emptyPriceList);

        expect(
          twoLayers.values['fillerKg'],
          greaterThan(oneLayer.values['fillerKg']!),
        );
      });
    });

    group('Insulation', () {
      test('no insulation by default', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['useInsulation'], equals(0.0));
        expect(result.values['insulationArea'], equals(0.0));
      });

      test('insulation with margin when enabled', () {
        final inputs = {
          'area': 20.0,
          'useInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.05 = 21 sqm
        expect(result.values['insulationArea'], closeTo(21.0, 0.1));
      });
    });

    group('Materials', () {
      test('armature tape calculation', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.2 = 24m
        expect(result.values['armatureTape'], closeTo(24.0, 0.1));
      });

      test('filler amount - standard', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 0.0, // not partition
          'layers': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 0.8 * 1 = 16 kg (Knauf Fugen ~0.8 кг/м²)
        expect(result.values['fillerKg'], closeTo(16.0, 0.1));
      });

      test('filler amount - partition (more)', () {
        final inputs = {
          'area': 20.0,
          'constructionType': 1.0, // partition
          'layers': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 1.5 * 1 = 30 kg (перегородка: 2 стороны)
        expect(result.values['fillerKg'], closeTo(30.0, 0.1));
      });

      test('primer calculation', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 0.15 = 3 liters
        expect(result.values['primerLiters'], closeTo(3.0, 0.1));
      });
    });

    group('Sheet sizes', () {
      test('sheet size 0 = 2.4 sqm', () {
        final result = calculator({'sheetSize': 0.0}, emptyPriceList);
        expect(result.values['sheetArea'], equals(2.4));
      });

      test('sheet size 1 = 3.0 sqm', () {
        final result = calculator({'sheetSize': 1.0}, emptyPriceList);
        expect(result.values['sheetArea'], equals(3.0));
      });

      test('sheet size 2 = 3.24 sqm', () {
        final result = calculator({'sheetSize': 2.0}, emptyPriceList);
        expect(result.values['sheetArea'], equals(3.24));
      });

      test('sheet size 3 = 3.6 sqm', () {
        final result = calculator({'sheetSize': 3.0}, emptyPriceList);
        expect(result.values['sheetArea'], equals(3.6));
      });
    });

    group('GKL types', () {
      test('standard type (0)', () {
        final result = calculator({'gklType': 0.0}, emptyPriceList);
        expect(result.values['gklType'], equals(0.0));
      });

      test('moisture resistant type (1)', () {
        final result = calculator({'gklType': 1.0}, emptyPriceList);
        expect(result.values['gklType'], equals(1.0));
      });

      test('fire resistant type (2)', () {
        final result = calculator({'gklType': 2.0}, emptyPriceList);
        expect(result.values['gklType'], equals(2.0));
      });
    });

    group('Thickness and weight', () {
      test('9.5mm thickness uses TN25 screws', () {
        final result = calculator({
          'area': 20.0,
          'thickness': 0.0, // 9.5mm
        }, emptyPriceList);

        expect(result.values['thickness'], equals(0.0));
        expect(result.values['screwsTN25'], greaterThan(0));
        expect(result.values['screwsTN35'], equals(0.0));
      });

      test('12.5mm thickness uses TN35 screws', () {
        final result = calculator({
          'area': 20.0,
          'thickness': 1.0, // 12.5mm
        }, emptyPriceList);

        expect(result.values['thickness'], equals(1.0));
        expect(result.values['screwsTN25'], equals(0.0));
        expect(result.values['screwsTN35'], greaterThan(0));
      });

      test('sheet weight depends on thickness and size', () {
        // 9.5mm, 2500x1200 = 22.5 kg
        final thin = calculator({
          'thickness': 0.0,
          'sheetSize': 1.0,
        }, emptyPriceList);

        // 12.5mm, 2500x1200 = 29 kg
        final thick = calculator({
          'thickness': 1.0,
          'sheetSize': 1.0,
        }, emptyPriceList);

        expect(thin.values['sheetWeight'], equals(22.5));
        expect(thick.values['sheetWeight'], equals(29.0));
      });

      test('total weight is sheet weight times count', () {
        final result = calculator({
          'area': 30.0,
          'thickness': 1.0,
          'sheetSize': 1.0, // 3.0 sqm, 29 kg each
        }, emptyPriceList);

        final sheets = result.values['gklSheets']!;
        final sheetWeight = result.values['sheetWeight']!;
        final totalWeight = result.values['totalWeight']!;

        expect(totalWeight, equals(sheets * sheetWeight));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(0.0));
        expect(result.values['area'], equals(20.0));
        expect(result.values['length'], equals(4.0));
        expect(result.values['width'], equals(3.0));
        expect(result.values['height'], equals(2.7));
        expect(result.values['constructionType'], equals(0.0));
        expect(result.values['gklType'], equals(0.0));
        expect(result.values['sheetSize'], equals(1.0));
        expect(result.values['layers'], equals(1.0));
        expect(result.values['useInsulation'], equals(0.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final tooSmall = calculator({
          'area': 0.5, // min 1
        }, emptyPriceList);

        final tooLarge = calculator({
          'area': 1000.0, // max 500
        }, emptyPriceList);

        expect(tooSmall.values['area'], equals(1.0));
        expect(tooLarge.values['area'], equals(500.0));
      });

      test('clamps dimensions to valid range', () {
        final inputs = {
          'length': 0.5, // min 1
          'width': 25.0, // max 20
          'height': 1.5, // min 2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(1.0));
        expect(result.values['width'], equals(20.0));
        expect(result.values['height'], equals(2.0));
      });

      test('clamps layers to valid range', () {
        final tooFew = calculator({
          'layers': 0.0, // min 1
        }, emptyPriceList);

        final tooMany = calculator({
          'layers': 5.0, // max 2
        }, emptyPriceList);

        expect(tooFew.values['layers'], equals(1.0));
        expect(tooMany.values['layers'], equals(2.0));
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'area': 20.0,
          'useInsulation': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'gkl_sheet', name: 'ГКЛ', price: 350.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'profile_pn', name: 'ПН', price: 150.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'profile_pp', name: 'ПП', price: 180.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'screw_tn25', name: 'TN25', price: 0.5, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'dowel', name: 'Дюбель', price: 2.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 100.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'filler', name: 'Шпаклёвка', price: 30.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 50.0, unit: 'л', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
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
      test('small wall lining with insulation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 15.0,
          'constructionType': 0.0, // wall lining
          'gklType': 0.0, // standard
          'sheetSize': 1.0, // 2500x1200
          'layers': 1.0,
          'useInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['calculatedArea'], equals(15.0));
        expect(result.values['gklSheets'], greaterThan(0));
        expect(result.values['pnPieces'], greaterThan(0));
        expect(result.values['ppPieces'], greaterThan(0));
        expect(result.values['suspensions'], greaterThan(0));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['fillerKg'], greaterThan(0));
        expect(result.values['primerLiters'], greaterThan(0));
      });

      test('large partition two layers', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 10.0,
          'height': 3.0,
          'constructionType': 1.0, // partition
          'gklType': 1.0, // moisture resistant
          'sheetSize': 2.0, // 2700x1200
          'layers': 2.0,
          'useInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 10 * 3 = 30 sqm
        expect(result.values['calculatedArea'], equals(30.0));
        expect(result.values['gklType'], equals(1.0));
        expect(result.values['layers'], equals(2.0));
        expect(result.values['screwsTN35'], greaterThan(0));
        expect(result.values['insulationArea'], greaterThan(0));
      });

      test('ceiling calculation by room dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'length': 5.0,
          'width': 4.0,
          'constructionType': 2.0, // ceiling
          'sheetSize': 3.0, // 3000x1200
          'layers': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Ceiling area = 5 * 4 = 20 sqm
        expect(result.values['calculatedArea'], equals(20.0));
        expect(result.values['connectors'], greaterThan(0));
        expect(result.values['suspensions'], greaterThan(0));
        // Ceiling has no sealing tape
        expect(result.values['sealingTape'], equals(0.0));
      });
    });
  });
}
