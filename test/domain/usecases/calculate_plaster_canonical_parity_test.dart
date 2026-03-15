import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';

void main() {
  group('CalculatePlaster canonical parity', () {
    final calculator = CalculatePlaster();
    final fixtureFile = File('test/fixtures/plaster_canonical_parity.json');
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
        expect(result.totals['netArea'], closeTo((expected['netArea'] as num).toDouble(), 0.05));
        expect(result.totals['totalKg'], closeTo((expected['totalKg'] as num).toDouble(), 0.1));
        expect(result.warnings.length, expected['warningsCount']);

        final recScenario = result.scenarios['REC']!;
        final recExpected = expected['recScenario'] as Map<String, dynamic>;
        expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
        expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.1));
        expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.1));

        final materials = expected['materials'] as Map<String, dynamic>;
        expect(result.materials.firstWhere((material) => material.category == 'Основное').purchaseQty, materials['plasterBags']);
        expect(result.materials.firstWhere((material) => material.name.contains('Грунтовка')).purchaseQty, materials['primerPackages']);
        expect(result.materials.firstWhere((material) => material.name.contains('Маяки')).purchaseQty, materials['beacons']);
        expect(result.materials.any((material) => material.name.contains('Стеклосетка')), materials['hasMesh'] == 1);
      });
    }
  });
}
