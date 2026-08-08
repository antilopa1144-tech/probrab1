import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/foundation_slab_canonical_adapter.dart';

void main() {
  group('calculateCanonicalFoundationSlab v2', () {
    test('считает прямоугольную плиту 10 × 6 м по реальной геометрии', () {
      final result = calculateCanonicalFoundationSlab({
        'length': 10,
        'width': 6,
        'thickness': 200,
        'rebarDiam': 12,
        'rebarStep': 200,
        'sandLayerMm': 100,
        'gravelLayerMm': 150,
        'insulationThickness': 0,
      });

      expect(result.formulaVersion, 'foundation-slab-canonical-v2');
      expect(result.totals['area'], 60);
      expect(result.totals['perimeter'], 32);
      expect(result.totals['concreteM3'], 12);
      expect(result.totals['barsAlongLength'], 31);
      expect(result.totals['barsAlongWidth'], 51);
      expect(result.totals['totalBarLen'], 1232);
      expect(result.totals['wireKg'], closeTo(8.443, 0.001));
    });

    test('применяет запас бетона один раз только в сценарии', () {
      final result = calculateCanonicalFoundationSlab({
        'area': 60,
        'thickness': 200,
      });

      expect(result.totals['concreteM3'], 12);
      expect(result.scenarios['REC']!.exactNeed, 12.72);
    });

    test('использует проектные толщины слоёв подготовки', () {
      final result = calculateCanonicalFoundationSlab({
        'area': 60,
        'sandLayerMm': 200,
        'gravelLayerMm': 80,
      });

      expect(result.totals['sand'], 12);
      expect(result.totals['gravel'], 4.8);
    });
  });
}
