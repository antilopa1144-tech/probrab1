import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/calculate_primer.dart';

void main() {
  group('CalculatePrimer canonical parity', () {
    final calculator = CalculatePrimer();
    final fixtureFile = File('test/fixtures/primer_canonical_parity.json');
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
        expect(result.totals['area'], closeTo((expected['area'] as num).toDouble(), 0.05));
        expect(result.warnings.length, expected['warningsCount']);

        final recScenario = result.scenarios['REC']!;
        final recExpected = expected['recScenario'] as Map<String, dynamic>;
        expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
        expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.1));
        expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.05));

        final materials = expected['materials'] as Map<String, dynamic>;
        expect(result.materials.firstWhere((material) => material.category == 'Основное').purchaseQty, materials['primerCans']);
        expect(findMaterial(result.materials, 'Валик')?.purchaseQty, materials['rollers']);
        expect(findMaterial(result.materials, 'Кисть')?.purchaseQty, materials['brushes']);
        expect(findMaterial(result.materials, 'Кювета')?.purchaseQty, materials['trays']);
      });
    }

    test('adapts canonical primer inputs to legacy CalculatorResult', () {
      final result = calculator({
        'area': 50.0,
        'surfaceType': 0.0,
        'primerType': 0.0,
        'coats': 1.0,
        'canSize': 5.0,
      }, const []);

      expect(result.values['primerNeeded'], closeTo(8.19009, 0.05));
      expect(result.values['totalCans'], 2);
      expect(result.norms, contains('primer-canonical-v1'));
    });
  });
}

