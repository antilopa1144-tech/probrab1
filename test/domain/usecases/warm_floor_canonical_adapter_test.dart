import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_canonical_adapter.dart';

void main() {
  group('calculateCanonicalWarmFloor legacy input aliases', () {
    test('area → roomArea for mat calculation', () {
      final result = calculateCanonicalWarmFloor({
        'area': 20,
        'type': 2,
        'power': 150,
        'usefulAreaPercent': 70,
      });

      expect(result.totals['roomArea'], 20);
      expect(result.totals['furnitureArea'], closeTo(6, 0.01));
      expect(result.totals['heatingArea'], closeTo(14, 0.01));
      expect(result.totals['heatingType'], 0);
    });

    test('length × width → roomArea', () {
      final result = calculateCanonicalWarmFloor({
        'length': 5,
        'width': 4,
        'type': 1,
        'power': 150,
      });

      expect(result.totals['roomArea'], 20);
      expect(result.totals['heatingType'], 1);
    });
  });
}
