import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';

void main() {
  group('CalculateWallpaper canonical parity', () {
    final calculator = CalculateWallpaper();
    final fixtureFile = File('test/fixtures/wallpaper_canonical_parity.json');
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
        expect(result.totals['wallArea'], closeTo((expected['wallArea'] as num).toDouble(), 0.05));
        expect(result.totals['netArea'], closeTo((expected['netArea'] as num).toDouble(), 0.05));
        expect(result.warnings.length, expected['warningsCount']);

        final recScenario = result.scenarios['REC']!;
        final recExpected = expected['recScenario'] as Map<String, dynamic>;
        expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
        expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.00001));
        expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.05));

        final materials = expected['materials'] as Map<String, dynamic>;
        expect(result.materials.firstWhere((material) => material.name == 'Обои').purchaseQty, materials['rolls']);
        expect(result.materials.firstWhere((material) => material.name.contains('Клей')).purchaseQty, materials['pastePacks']);
        expect(result.materials.firstWhere((material) => material.name.contains('Грунтовка')).purchaseQty, materials['primerCans']);
      });
    }
  });
}
