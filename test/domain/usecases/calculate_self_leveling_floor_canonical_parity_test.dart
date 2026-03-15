import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';

import '../../helpers/canonical_parity_harness.dart';

void main() {
  final calculator = CalculateSelfLevelingFloor();

  runCanonicalParitySuite(
    groupName: 'CalculateSelfLevelingFloor canonical parity',
    fixturePath: 'test/fixtures/self_leveling_canonical_parity.json',
    calculate: calculator.calculateCanonical,
    assertCase: (result, expected, _) {
      expect(result.formulaVersion, expected['formulaVersion']);
      expect(result.totals['area'], closeTo((expected['area'] as num).toDouble(), 0.05));
      expect(result.totals['perimeter'], closeTo((expected['perimeter'] as num).toDouble(), 0.05));
      expect(result.warnings.length, expected['warningsCount']);

      final recScenario = result.scenarios['REC']!;
      final recExpected = expected['recScenario'] as Map<String, dynamic>;
      expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
      expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.00001));
      expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.00001));

      final materials = expected['materials'] as Map<String, dynamic>;
      expect(findCanonicalMaterial(result.materials, 'мешки')?.purchaseQty ?? findCanonicalMaterial(result.materials, 'смесь')?.purchaseQty, materials['bags']);
      expect(findCanonicalMaterial(result.materials, 'Грунтовка')?.purchaseQty, materials['primerCans']);
      expect(findCanonicalMaterial(result.materials, 'Демпферная')?.purchaseQty, materials['tapeRolls']);
    },
  );
}
