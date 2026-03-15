import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';

void main() {
  group('CalculateTile canonical parity', () {
    final calculator = CalculateTile();
    final fixtureFile = File('test/fixtures/tile_canonical_parity.json');
    final fixture = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final cases = (fixture['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final fixtureCase in cases) {
      test(fixtureCase['id'] as String, () {
        final inputs = (fixtureCase['inputs'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        final expected = fixtureCase['expected'] as Map<String, dynamic>;
        final result = calculator.calculateCanonical(inputs);

        expect(result.formulaVersion, expected['formulaVersion']);
        expect(result.totals['area'], closeTo((expected['area'] as num).toDouble(), 0.05));
        expect(result.totals['wastePercent'], closeTo((expected['wastePercent'] as num).toDouble(), 0.05));
        expect(result.warnings.length, expected['warningsCount']);

        final recScenario = result.scenarios['REC']!;
        final recExpected = expected['recScenario'] as Map<String, dynamic>;
        expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
        expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.00001));
        expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.05));

        final materials = expected['materials'] as Map<String, dynamic>;
        expect(result.materials.firstWhere((material) => material.name.contains('Плитка')).purchaseQty, materials['tiles']);
        expect(result.materials.firstWhere((material) => material.name.contains('Плиточный клей')).purchaseQty, materials['glueBags']);
        expect(result.materials.firstWhere((material) => material.name.contains('Затирка')).purchaseQty, materials['groutBags']);
        expect(result.materials.firstWhere((material) => material.name.contains('Грунтовка')).purchaseQty, materials['primerCans']);
        if (materials.containsKey('crosses')) {
          expect(result.materials.firstWhere((material) => material.name.contains('Крестики')).purchaseQty, materials['crosses']);
        }
        if (materials.containsKey('svpPackages')) {
          expect(result.materials.firstWhere((material) => material.name.contains('СВП')).purchaseQty, materials['svpPackages']);
        }
      });
    }
  });
}
