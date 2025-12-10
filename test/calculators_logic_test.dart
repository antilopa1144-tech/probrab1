import 'package:flutter_test/flutter_test.dart';

import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';

void main() {
  group('CalculateWallPaint', () {
    test('не требует периметр и считает краску по площади', () {
      final calculator = CalculateWallPaint();

      final result = calculator(
        {
          'area': 100.0,
          'layers': 2,
          // периметр намеренно не передаём, должен считаться автоматически
        },
        const [],
      );

      expect(result.values['paintNeeded'], isNotNull);
      expect(result.values['paintNeeded'], greaterThan(0));
      expect(result.values['tapeNeeded'], isNotNull);
      expect(result.values['tapeNeeded'], greaterThan(0));
    });
  });

  group('CalculateWallpaper', () {
    test('рассчитывает рулоны и полосы без ошибок', () {
      final calculator = CalculateWallpaper();

      final result = calculator(
        {
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
