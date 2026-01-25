import 'package:flutter_test/flutter_test.dart';

import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';

void main() {
  group('CalculateWallpaper', () {
    test('рассчитывает рулоны и полосы без ошибок', () {
      final calculator = CalculateWallpaper();

      final result = calculator(
        {
          'inputMode': 1.0, // Режим "По площади"
          'area': 50.0,
          'rollWidth': 0.53,
          'rollLength': 10.05,
          'wallHeight': 2.7,
        },
        const [],
      );

      expect(result.values['rollsNeeded'], isNotNull);
      expect(result.values['rollsNeeded'], greaterThan(0));
      expect(result.values['stripsNeeded'], isNotNull);
      expect(result.values['stripsNeeded'], greaterThan(0));
    });
  });
}
