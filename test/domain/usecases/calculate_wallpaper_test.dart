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
  });
}
