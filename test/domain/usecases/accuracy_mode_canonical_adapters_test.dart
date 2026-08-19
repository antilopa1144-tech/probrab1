import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/aerated_concrete_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/electric_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fasteners_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wallpaper_canonical_adapter.dart';

void main() {
  double recNeed(Map<String, double> inputs) =>
      calculateCanonicalAeratedConcrete(inputs).scenarios['REC']!.exactNeed;

  group('canonical adapter accuracy modes', () {
    test('generic primary material grows from basic to professional', () {
      const inputs = <String, double>{
        'inputMode': 1,
        'area': 42,
        'blockLength': 600,
        'blockHeight': 200,
        'blockThickness': 300,
      };

      final basic = recNeed({...inputs, 'accuracyMode': 0});
      final realistic = recNeed({...inputs, 'accuracyMode': 1});
      final professional = recNeed({...inputs, 'accuracyMode': 2});

      expect(realistic, greaterThan(basic));
      expect(professional, greaterThan(realistic));
    });

    test(
      'tile applies category multipliers to the main material and accessories',
      () {
        const inputs = <String, double>{
          'inputMode': 1,
          'area': 12,
          'tileWidthCm': 30,
          'tileHeightCm': 30,
          'jointWidth': 3,
          'layoutPattern': 1,
          'roomComplexity': 1,
          'packArea': 1.44,
        };

        final basic = calculateCanonicalTile({...inputs, 'accuracyMode': 0});
        final realistic = calculateCanonicalTile({
          ...inputs,
          'accuracyMode': 1,
        });
        final professional = calculateCanonicalTile({
          ...inputs,
          'accuracyMode': 2,
        });

        expect(basic.scenarios['REC']!.exactNeed, 146.666667);
        expect(basic.scenarios['REC']!.purchaseQuantity, 160);
        expect(realistic.scenarios['REC']!.exactNeed, 158.741458);
        expect(realistic.scenarios['REC']!.purchaseQuantity, 160);
        expect(professional.scenarios['REC']!.exactNeed, 168.264096);
        expect(professional.scenarios['REC']!.purchaseQuantity, 176);

        double quantityByName(
          CanonicalCalculatorContractResult result,
          String name,
        ) => result.materials
            .firstWhere((material) => material.name.contains(name))
            .quantity;
        expect(quantityByName(basic, 'Плиточный клей'), 48);
        expect(quantityByName(realistic, 'Плиточный клей'), 54.533606);
        expect(quantityByName(professional, 'Плиточный клей'), 61.135339);
        expect(quantityByName(basic, 'Крестики'), 192);
        expect(quantityByName(realistic, 'Крестики'), 202);
        expect(quantityByName(professional, 'Крестики'), 233);
      },
    );

    test('wallpaper primer uses its own primary accuracy profile', () {
      final basic = calculateCanonicalWallpaper({
        'perimeter': 14,
        'accuracyMode': 0,
      });
      final realistic = calculateCanonicalWallpaper({
        'perimeter': 14,
        'accuracyMode': 1,
      });
      final professional = calculateCanonicalWallpaper({
        'perimeter': 14,
        'accuracyMode': 2,
      });

      expect(basic.scenarios['REC']!.exactNeed, 9);
      expect(basic.scenarios['REC']!.purchaseQuantity, 9);
      expect(realistic.scenarios['REC']!.exactNeed, 9.837398);
      expect(realistic.scenarios['REC']!.purchaseQuantity, 10);
      expect(professional.scenarios['REC']!.exactNeed, 10.424616);
      expect(professional.scenarios['REC']!.purchaseQuantity, 11);
      final basicPrimer = basic.materials
          .firstWhere((material) => material.category == 'Грунтовка')
          .quantity;
      final professionalPrimer = professional.materials
          .firstWhere((material) => material.category == 'Грунтовка')
          .quantity;
      expect(professionalPrimer, greaterThan(basicPrimer));
    });

    test('electric applies accuracy before the spool rounding stage', () {
      final basic = calculateCanonicalElectric({'accuracyMode': 0});
      final realistic = calculateCanonicalElectric({'accuracyMode': 1});
      final professional = calculateCanonicalElectric({'accuracyMode': 2});

      expect(basic.scenarios['REC']!.exactNeed, 5.3);
      expect(basic.scenarios['REC']!.purchaseQuantity, 6);
      expect(realistic.scenarios['REC']!.exactNeed, 6.36);
      expect(realistic.scenarios['REC']!.purchaseQuantity, 7);
      expect(professional.scenarios['REC']!.exactNeed, 7.42);
      expect(professional.scenarios['REC']!.purchaseQuantity, 8);
    });

    test('fastener bits use the accessories multiplier', () {
      double bitsForMode(double mode) =>
          calculateCanonicalFasteners({'sheetCount': 100, 'accuracyMode': mode})
              .materials
              .firstWhere((material) => material.name.contains('бита'))
              .purchaseQty ??
          0;

      expect(bitsForMode(0), 7);
      expect(bitsForMode(1), 8);
      expect(bitsForMode(2), 9);
    });
  });
}
