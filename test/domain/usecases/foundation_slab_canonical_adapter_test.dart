import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/foundation_slab_canonical_adapter.dart';

void main() {
  group('calculateCanonicalFoundationSlab v3', () {
    test('считает плиту только по реальным длине и ширине', () {
      final result = calculateCanonicalFoundationSlab({
        'area': 100,
        'length': 10,
        'width': 6,
        'thickness': 200,
      });

      expect(result.formulaVersion, 'foundation-slab-canonical-v3');
      expect(result.totals['area'], 60);
      expect(result.totals['perimeter'], 32);
      expect(result.totals['concreteM3'], 12);
    });

    test('разделяет геометрию, запас и шаг заказа бетона', () {
      final result = calculateCanonicalFoundationSlab({
        'length': 10,
        'width': 6,
        'thickness': 200,
        'concreteReservePercent': 7,
        'deliveryAllowanceM3': 0.3,
        'readyMixOrderStepM3': 0.5,
      });

      expect(result.scenarios['MIN']!.exactNeed, 12.3);
      expect(result.scenarios['REC']!.exactNeed, 13.14);
      expect(result.scenarios['REC']!.purchaseQuantity, 13.5);
      expect(result.scenarios['MAX']!.exactNeed, 13.5);
    });

    test('учитывает отступ, слои и округляет арматуру до целых прутков', () {
      final result = calculateCanonicalFoundationSlab({
        'length': 10,
        'width': 6,
        'gridLayers': 2,
        'rebarDiam': 12,
        'rebarStep': 200,
        'edgeCoverMm': 50,
        'rebarReservePercent': 10,
        'rodLengthM': 11.7,
      });

      expect(result.totals['barsAlongLength'], 31);
      expect(result.totals['barsAlongWidth'], 51);
      expect(result.totals['totalBarLen'], 1215.6);
      expect(result.totals['rebarRods'], 115);
      expect(result.totals['rebarPurchaseLengthM'], 1345.5);
    });

    test('считает проволоку по явной доле узлов и фасовке', () {
      final result = calculateCanonicalFoundationSlab({
        'tieSharePercent': 50,
        'wireLengthPerTieM': 0.25,
        'wireReservePercent': 10,
        'wirePackageKg': 1,
      });

      expect(result.totals['tieCount'], 1581);
      expect(result.totals['wireKg'], closeTo(2.372, 0.001));
      expect(result.totals['wirePurchaseKg'], 3);
    });

    test('отделяет уплотнённый слой от надбавки и шага заказа', () {
      final result = calculateCanonicalFoundationSlab({
        'sandLayerMm': 100,
        'sandOrderExtraPercent': 15,
        'gravelLayerMm': 80,
        'gravelOrderExtraPercent': 10,
        'aggregateOrderStepM3': 0.5,
      });

      expect(result.totals['sand'], 6);
      expect(result.totals['sandPlanningM3'], 6.9);
      expect(result.totals['sandPurchaseM3'], 7);
      expect(result.totals['gravel'], 4.8);
      expect(result.totals['gravelPurchaseM3'], 5.5);
    });

    test('округляет геотекстиль до введённой площади рулона', () {
      final result = calculateCanonicalFoundationSlab({
        'includeGeotextile': 1,
        'geotextileReservePercent': 20,
        'geotextileRollAreaM2': 50,
      });

      expect(result.totals['geotextile'], 60);
      expect(result.totals['geotextilePlanningM2'], 72);
      expect(result.totals['geotextileRolls'], 2);
      expect(result.totals['geotextilePurchaseM2'], 100);
    });

    test('может исключить необязательные проектные слои', () {
      final result = calculateCanonicalFoundationSlab({
        'sandLayerMm': 0,
        'gravelLayerMm': 0,
        'includeGeotextile': 0,
        'formworkHeightMm': 0,
      });

      expect(
        result.materials.any((material) => material.name.startsWith('Песок')),
        isFalse,
      );
      expect(
        result.materials.any((material) => material.name.startsWith('Щебень')),
        isFalse,
      );
      expect(
        result.materials.any(
          (material) => material.name.startsWith('Геотекстиль'),
        ),
        isFalse,
      );
      expect(
        result.materials.any(
          (material) => material.name.startsWith('Опалубка'),
        ),
        isFalse,
      );
    });

    test('всегда обозначает границу расчёта конструкции', () {
      final result = calculateCanonicalFoundationSlab({});
      expect(
        result.warnings.any(
          (warning) => warning.contains('не выбирает тип фундамента'),
        ),
        isTrue,
      );
    });
  });
}
