import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/calculate_putty.dart';

void main() {
  group('CalculatePutty canonical parity', () {
    final calculator = CalculatePutty();
    final fixtureFile = File('test/fixtures/putty_canonical_parity.json');
    final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final cases = (fixture['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

    CanonicalMaterialResult? findMaterial(Iterable<CanonicalMaterialResult> materials, String namePart) {
      for (final material in materials) {
        if (material.name.contains(namePart)) return material;
      }
      return null;
    }

    for (final fixtureCase in cases) {
      test(fixtureCase['id'] as String, () {
        final inputs = ((fixtureCase['inputs'] as Map<String, dynamic>)).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        final expected = fixtureCase['expected'] as Map<String, dynamic>;
        final result = calculator.calculateCanonical(inputs);

        expect(result.formulaVersion, expected['formulaVersion']);
        expect(result.totals['wallArea'], closeTo((expected['wallArea'] as num).toDouble(), 0.05));
        expect(result.warnings.length, expected['warningsCount']);

        final recScenario = result.scenarios['REC']!;
        final recExpected = expected['recScenario'] as Map<String, dynamic>;
        expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
        expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.05));
        expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.05));

        final materials = expected['materials'] as Map<String, dynamic>;
        if (materials.containsKey('finishBags')) {
          expect(findMaterial(result.materials, 'финишная')?.purchaseQty, materials['finishBags']);
        }
        if (materials.containsKey('startBags')) {
          expect(findMaterial(result.materials, 'стартовая')?.purchaseQty, materials['startBags']);
        }
        if (materials.containsKey('primerCans')) {
          expect(findMaterial(result.materials, 'Грунтовка')?.purchaseQty, materials['primerCans']);
        }
        if (materials.containsKey('serpyankaRolls')) {
          expect(findMaterial(result.materials, 'Серпянка')?.purchaseQty, materials['serpyankaRolls']);
        }
        if (materials.containsKey('sandpaperSheets')) {
          expect(findMaterial(result.materials, 'Наждачная')?.purchaseQty, materials['sandpaperSheets']);
        }
      });
    }

    test('adapts canonical inputs to legacy calculator result', () {
      final result = calculator({
        'inputMode': 1,
        'area': 48.6,
        'puttyType': 1,
        'bagWeight': 25,
      }, const []);

      expect(result.values['puttyNeeded'], closeTo(201.673, 0.05));
      expect(result.values['scenarioRecPurchase'], closeTo(225, 0.05));
      expect(result.norms, contains('putty-canonical-v1'));
    });

    test('supports qualityClass in canonical contract', () {
      final result = calculator.calculateCanonical({
        'inputMode': 1,
        'area': 20,
        'puttyType': 2,
        'bagWeight': 20,
        'qualityClass': 2,
      });
      final recScenario = result.scenarios['REC']!;
      final recMultiplier = recScenario.keyFactors.values.fold(1.0, (acc, value) => acc * value);

      expect(result.totals['qualityClass'], 2);
      expect(recScenario.exactNeed, closeTo(20 * 1.5 * 2 * recMultiplier, 0.05));
    });

    test('supports separate startLayers and finishLayers in canonical contract', () {
      final result = calculator.calculateCanonical({
        'inputMode': 1,
        'area': 20,
        'puttyType': 1,
        'bagWeight': 20,
        'qualityClass': 2,
        'startLayers': 3,
        'finishLayers': 1,
      });
      final recScenario = result.scenarios['REC']!;

      expect(result.totals['startLayers'], 3);
      expect(result.totals['finishLayers'], 1);
      expect(recScenario.exactNeed, closeTo(115.753, 0.05));
    });
  });
}


