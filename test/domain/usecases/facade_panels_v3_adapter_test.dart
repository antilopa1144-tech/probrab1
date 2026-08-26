import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/facade_panels_v3_adapter.dart';

void main() {
  group('facade panels canonical v3', () {
    test('subtracts openings and applies reserve once', () {
      final result = calculateCanonicalFacadePanelsV3({
        'inputMode': 0,
        'wallLength': 36,
        'wallHeight': 3,
        'openingsArea': 12,
        'panelUsefulArea': 1,
        'reservePercent': 10,
      });

      expect(result.totals['grossArea'], 108);
      expect(result.totals['wallArea'], 96);
      expect(result.scenarios['MIN']!.exactNeed, 96);
      expect(result.scenarios['REC']!.exactNeed, closeTo(105.6, 0.000001));
      expect(result.scenarios['REC']!.purchaseQuantity, 106);
    });

    test('uses passport packaging and does not invent fasteners', () {
      final result = calculateCanonicalFacadePanelsV3({
        'inputMode': 1,
        'area': 20,
        'panelUsefulArea': 1,
        'reservePercent': 0,
        'needProfile': 1,
        'profileStep': 0.5,
        'profilePieceLength': 3,
        'needInsulation': 1,
        'insulationPackArea': 6,
        'fastenersPerPanel': 0,
      });

      expect(result.totals['panelsCount'], 20);
      expect(result.totals['insulationPacks'], 4);
      expect(result.totals['fasteners'], 0);
      expect(
        result.materials.any((item) => item.name == 'Крепёж панелей'),
        isFalse,
      );
    });
  });
}
