import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_parquet.dart';

import '../../helpers/canonical_parity_harness.dart';

void main() {
  final calculator = CalculateParquet();

  runCanonicalParitySuite(
    groupName: 'CalculateParquet canonical parity',
    fixturePath: 'test/fixtures/parquet_canonical_parity.json',
    calculate: calculator.calculateCanonical,
    assertCase: (result, expected, _) {
      expect(result.formulaVersion, expected['formulaVersion']);
      expect(result.totals['area'], closeTo((expected['area'] as num).toDouble(), 0.05));
      expect(result.totals['perimeter'], closeTo((expected['perimeter'] as num).toDouble(), 0.05));
      expect(result.totals['wastePercent'], closeTo((expected['wastePercent'] as num).toDouble(), 0.00001));
      expect(result.warnings.length, expected['warningsCount']);

      final recScenario = result.scenarios['REC']!;
      final recExpected = expected['recScenario'] as Map<String, dynamic>;
      expect(recScenario.buyPlan.packageSize, (recExpected['packageSize'] as num).toDouble());
      expect(recScenario.exactNeed, closeTo((recExpected['exactNeed'] as num).toDouble(), 0.00001));
      expect(recScenario.purchaseQuantity, closeTo((recExpected['purchaseQuantity'] as num).toDouble(), 0.00001));

      final materials = expected['materials'] as Map<String, dynamic>;
      expect(result.materials.firstWhere((material) => material.name.contains('Паркетная')).purchaseQty, materials['packs']);
      if (materials.containsKey('underlaymentRolls')) {
        expect(findCanonicalMaterial(result.materials, 'Подложка')?.purchaseQty, materials['underlaymentRolls']);
      }
      if (materials.containsKey('plinthPieces')) {
        expect(findCanonicalMaterial(result.materials, 'Плинтус')?.purchaseQty, materials['plinthPieces']);
      }
      if (materials.containsKey('glueBuckets')) {
        expect(findCanonicalMaterial(result.materials, 'Клей')?.purchaseQty, materials['glueBuckets']);
      }
      expect(findCanonicalMaterial(result.materials, 'Порожек')?.purchaseQty, materials['thresholds']);
    },
  );
}
