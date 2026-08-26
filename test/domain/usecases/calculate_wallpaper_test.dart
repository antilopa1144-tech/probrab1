import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/domain/usecases/wallpaper_canonical_adapter.dart';

void main() {
  group('CalculateWallpaper', () {
    test('calculateCanonical совпадает с calculateCanonicalWallpaper', () {
      const inputs = <String, double>{
        'inputMode': 0,
        'perimeter': 14,
        'wallHeight': 2.7,
        'rollLength': 10.05,
        'rollWidth': 0.53,
        'rapport': 0,
        'wallpaperType': 1,
        'reserveRolls': 0,
        'reservePercent': 0,
      };

      final legacy = CalculateWallpaper().calculateCanonical(inputs);
      final canonical = calculateCanonicalWallpaper(inputs);

      expect(legacy.formulaVersion, canonical.formulaVersion);
      expect(legacy.totals['rollsNeeded'], canonical.totals['rollsNeeded']);
      expect(legacy.totals['netArea'], canonical.totals['netArea']);
      expect(legacy.materials.length, canonical.materials.length);
    });

    test('validateInputs отклоняет нулевую площадь в режиме area', () {
      final calculator = CalculateWallpaper();
      final error = calculator.validateInputs({
        'inputMode': 1,
        'area': 0,
        'wallHeight': 2.5,
      });
      expect(error, isNotNull);
    });

    test('MIN не ниже чистой потребности, запас применяется один раз', () {
      final result = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'rollLength': 10.05,
        'rollWidth': 0.53,
        'rapport': 0,
        'reservePercent': 15,
        'reserveRolls': 0,
        'accuracyMode': 0,
      });

      expect(result.totals['baseExactRolls'], 9);
      expect(result.scenarios['MIN']!.exactNeed, 9);
      expect(result.scenarios['REC']!.exactNeed, 10.35);
      expect(result.scenarios['REC']!.purchaseQuantity, 11);
      expect(result.scenarios['MAX']!.exactNeed, 11.35);
      expect(result.scenarios['MAX']!.purchaseQuantity, 12);
    });

    test('разделяет точный расход, запас и покупаемую упаковку', () {
      final result = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'rollLength': 10.05,
        'rollWidth': 0.53,
        'rapport': 0,
        'reservePercent': 0,
        'reserveRolls': 0,
        'accuracyMode': 0,
      });

      final wallpaper = result.materials.first;
      final paste = result.materials[1];
      final primer = result.materials[2];

      expect(wallpaper.quantity, 9);
      expect(wallpaper.withReserve, 9);
      expect(wallpaper.purchaseQty, 9);
      expect(paste.quantity, closeTo(0.315, 0.000001));
      expect(paste.withReserve, closeTo(0.315, 0.000001));
      expect(paste.purchaseQty, 0.5);
      expect(primer.quantity, closeTo(5.67, 0.000001));
      expect(primer.withReserve, closeTo(5.67, 0.000001));
      expect(primer.purchaseQty, 10);
    });

    test('безопасный режим не вычитает проёмы из целых полос', () {
      final safe = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'openingsArea': 10,
        'rollLength': 10.05,
        'rollWidth': 0.53,
      });
      final optimistic = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'openingsArea': 10,
        'openingDeductionMode': 1,
        'rollLength': 10.05,
        'rollWidth': 0.53,
      });

      expect(safe.totals['stripsNeeded'], 27);
      expect(optimistic.totals['stripsNeeded'], 20);
      expect(safe.totals['rollsNeeded'], greaterThan(optimistic.totals['rollsNeeded']!));
    });

    test('смещение рисунка входит в раскрой до округления по раппорту', () {
      final straight = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'rapport': 64,
        'patternShift': 0,
        'rollLength': 10.05,
        'rollWidth': 0.53,
      });
      final shifted = calculateCanonicalWallpaper({
        'perimeter': 14,
        'wallHeight': 2.7,
        'rapport': 64,
        'patternShift': 48,
        'rollLength': 10.05,
        'rollWidth': 0.53,
      });

      expect(straight.totals['stripLength'], closeTo(3.2, 0.001));
      expect(shifted.totals['stripLength'], closeTo(3.84, 0.001));
      expect(shifted.totals['rollsNeeded'], greaterThan(straight.totals['rollsNeeded']!));
    });
  });
}
