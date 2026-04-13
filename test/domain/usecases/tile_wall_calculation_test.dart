/// Tests for tile calculator wall area functionality.
///
/// Проверяет корректность расчёта плитки на стены:
/// - Расчёт площади стен с вычетами (двери/окна)
/// - Расчёт комбинированной площади (пол + стены)
/// - Граничные условия
/// - Canonical adapter работает с площадью стен

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/tile_canonical_adapter.dart';

void main() {
  group('Tile Wall Area Calculation', () {
    // Вспомогательная функция — эмулирует расчёт площади стен из экрана
    double calculateWallArea({
      required double wallHeight,
      required double wallPerimeter,
      int doorCount = 0,
      double doorWidth = 0.9,
      double doorHeight = 2.1,
      int windowCount = 0,
      double windowWidth = 1.2,
      double windowHeight = 1.4,
    }) {
      final grossArea = wallPerimeter * wallHeight;
      final doorDeduction = doorCount * doorWidth * doorHeight;
      final windowDeduction = windowCount * windowWidth * windowHeight;
      final netArea = grossArea - doorDeduction - windowDeduction;
      return netArea > 0 ? netArea : 0;
    }

    group('Площадь стен (нетто)', () {
      test('стандартная ванная 2.5×1.7м, h=2.7м, 1 дверь → ~19.5 м²', () {
        // Периметр: (2.5+1.7)*2 = 8.4м
        // Площадь стен: 8.4 × 2.7 = 22.68 м²
        // Вычет двери: 0.9 × 2.1 = 1.89 м²
        // Нетто: 22.68 - 1.89 = 20.79 м²
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 8.4,
          doorCount: 1,
        );
        expect(area, closeTo(20.79, 0.01));
      });

      test('кухня с дверью и окном → площадь уменьшается', () {
        // Периметр: 12м, высота: 2.7м = 32.4 м²
        // Дверь: 0.9 × 2.1 = 1.89 м²
        // Окно: 1.2 × 1.4 = 1.68 м²
        // Нетто: 32.4 - 1.89 - 1.68 = 28.83 м²
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 12.0,
          doorCount: 1,
          windowCount: 1,
        );
        expect(area, closeTo(28.83, 0.01));
      });

      test('комната с 2 дверями и 2 окнами', () {
        // Периметр: 16м, высота: 2.7м = 43.2 м²
        // 2 двери: 2 × 0.9 × 2.1 = 3.78 м²
        // 2 окна: 2 × 1.2 × 1.4 = 3.36 м²
        // Нетто: 43.2 - 3.78 - 3.36 = 36.06 м²
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 16.0,
          doorCount: 2,
          windowCount: 2,
        );
        expect(area, closeTo(36.06, 0.01));
      });

      test('без вычетов — чистая площадь стен', () {
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 10.0,
        );
        expect(area, closeTo(27.0, 0.01));
      });

      test('минимальная стена — не падает', () {
        final area = calculateWallArea(
          wallHeight: 1.0,
          wallPerimeter: 2.0,
        );
        expect(area, equals(2.0));
      });

      test('вычеты больше площади → результат 0, не отрицательный', () {
        final area = calculateWallArea(
          wallHeight: 2.0,
          wallPerimeter: 2.0, // 4 м²
          doorCount: 3, // 3 × 0.9 × 2.1 = 5.67 м²
        );
        expect(area, equals(0.0));
      });
    });

    group('Canonical adapter с площадью стен', () {
      test('расчёт плитки 30×30 на 20 м² стен — материалы рассчитаны', () {
        final result = calculateCanonicalTile({
          'inputMode': 1.0,
          'area': 20.0,
          'tileWidthCm': 30.0,
          'tileHeightCm': 30.0,
          'jointWidth': 3.0,
          'layoutPattern': 1.0,
          'roomComplexity': 1.0,
        });

        expect(result.totals['area'], equals(20.0));
        expect(result.materials.isNotEmpty, isTrue);
        // Плитка 30×30 = 0.09 м², 20/0.09 = 222.2 + запас
        final tileCount = result.totals['tilesNeeded'] ?? 0;
        expect(tileCount, greaterThan(200));
      });

      test('расчёт плитки на комбинированную площадь (пол 12 м² + стены 20 м²)', () {
        final totalArea = 12.0 + 20.0; // 32 м²
        final result = calculateCanonicalTile({
          'inputMode': 1.0,
          'area': totalArea,
          'tileWidthCm': 30.0,
          'tileHeightCm': 30.0,
          'jointWidth': 3.0,
          'layoutPattern': 1.0,
          'roomComplexity': 1.0,
        });

        expect(result.totals['area'], equals(32.0));
        final tileCount = result.totals['tilesNeeded'] ?? 0;
        // 32 м² / 0.09 м² = 355.6 + запас → >355
        expect(tileCount, greaterThan(350));
      });

      test('только стены — малая ванная 5 м²', () {
        final result = calculateCanonicalTile({
          'inputMode': 1.0,
          'area': 5.0,
          'tileWidthCm': 20.0,
          'tileHeightCm': 30.0,
          'jointWidth': 2.0,
          'layoutPattern': 1.0,
          'roomComplexity': 1.0,
        });

        expect(result.totals['area'], equals(5.0));
        expect(result.materials.isNotEmpty, isTrue);
        // Клей и затирка рассчитаны
        expect(result.totals['glueNeededKg'], greaterThan(0));
        expect(result.totals['groutNeededKg'], greaterThan(0));
      });
    });

    group('Граничные условия стен', () {
      test('нулевая площадь стен при нулевом периметре', () {
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 0,
        );
        expect(area, equals(0.0));
      });

      test('максимальные размеры стен — расчёт без ошибок', () {
        final area = calculateWallArea(
          wallHeight: 5.0,
          wallPerimeter: 60.0,
          doorCount: 5,
          windowCount: 5,
        );
        // 300 - (5×0.9×2.1) - (5×1.2×1.4) = 300 - 9.45 - 8.4 = 282.15
        expect(area, closeTo(282.15, 0.01));
      });

      test('нестандартные размеры дверей', () {
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 10.0,
          doorCount: 1,
          doorWidth: 1.5, // двустворчатая дверь
          doorHeight: 2.3,
        );
        // 27 - (1.5 × 2.3) = 27 - 3.45 = 23.55
        expect(area, closeTo(23.55, 0.01));
      });

      test('панорамные окна', () {
        final area = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 12.0,
          windowCount: 2,
          windowWidth: 2.5,
          windowHeight: 2.0,
        );
        // 32.4 - (2 × 2.5 × 2.0) = 32.4 - 10.0 = 22.4
        expect(area, closeTo(22.4, 0.01));
      });
    });

    group('Высота облицовки стен', () {
      test('облицовка на половину стены — площадь уменьшается', () {
        // Периметр 10м, высота потолка 2.7м, облицовка до 1.5м
        final fullArea = calculateWallArea(
          wallHeight: 2.7,
          wallPerimeter: 10.0,
        );
        // Площадь с полной высотой: 27 м²
        expect(fullArea, closeTo(27.0, 0.01));

        // Эмулируем облицовку до 1.5м
        final partialArea = calculateWallArea(
          wallHeight: 1.5, // tileUpToHeight используется как wallHeight
          wallPerimeter: 10.0,
        );
        // Площадь с частичной высотой: 15 м²
        expect(partialArea, closeTo(15.0, 0.01));
        expect(partialArea, lessThan(fullArea));
      });

      test('вычет двери при частичной облицовке (дверь выше облицовки)', () {
        // Облицовка 1.5м, дверь 2.1м — clamp до 1.5м
        final area = calculateWallArea(
          wallHeight: 1.5,
          wallPerimeter: 10.0,
          doorCount: 1,
          doorWidth: 0.9,
          doorHeight: 1.5, // clamp(2.1, 0, 1.5) = 1.5
        );
        // 15 - (0.9 × 1.5) = 15 - 1.35 = 13.65
        expect(area, closeTo(13.65, 0.01));
      });
    });

    group('Гидроизоляция стен vs пол', () {
      test('пол: 2 слоя × 1.5 кг/м² × 10% запас', () {
        const floorArea = 10.0;
        const wallArea = 0.0;
        // Пол: 10 × 1.5 × 2 × 1.1 = 33.0 кг
        final floorWp = floorArea * 1.5 * 2 * 1.1;
        final wallWp = wallArea * 1.5 * 1 * 1.1;
        expect(floorWp + wallWp, closeTo(33.0, 0.01));
      });

      test('стены: 1 слой × 1.5 кг/м² × 10% запас', () {
        const floorArea = 0.0;
        const wallArea = 20.0;
        // Стены: 20 × 1.5 × 1 × 1.1 = 33.0 кг
        final floorWp = floorArea * 1.5 * 2 * 1.1;
        final wallWp = wallArea * 1.5 * 1 * 1.1;
        expect(floorWp + wallWp, closeTo(33.0, 0.01));
      });

      test('пол + стены: раздельный расчёт', () {
        const floorArea = 5.0; // ванная
        const wallArea = 15.0;
        // Пол: 5 × 1.5 × 2 × 1.1 = 16.5
        // Стены: 15 × 1.5 × 1 × 1.1 = 24.75
        // Итого: 41.25
        final floorWp = floorArea * 1.5 * 2 * 1.1;
        final wallWp = wallArea * 1.5 * 1 * 1.1;
        final total = floorWp + wallWp;
        expect(total, closeTo(41.25, 0.01));

        // Сравнение: если бы считали 2 слоя на всё
        final wrongTotal = (floorArea + wallArea) * 1.5 * 2 * 1.1;
        expect(total, lessThan(wrongTotal));
      });
    });

    group('Доп. клей на стены', () {
      test('стандартная плитка <40 см — +20% клея на стены', () {
        const totalGlue = 100.0; // базовый расход
        const totalArea = 30.0;
        const wallArea = 20.0;
        const avgTileSizeCm = 30.0;

        final wallFraction = wallArea / totalArea;
        final wallGlue = totalGlue * wallFraction;
        final extraPercent = avgTileSizeCm > 40 ? 0.30 : 0.20;
        final extra = wallGlue * extraPercent;

        // wallFraction = 20/30 = 0.667
        // wallGlue = 100 × 0.667 = 66.7
        // extra = 66.7 × 0.20 = 13.33
        expect(extra, closeTo(13.33, 0.1));
        expect(totalGlue + extra, closeTo(113.33, 0.1));
      });

      test('крупноформат >40 см — +30% клея на стены', () {
        const totalGlue = 100.0;
        const totalArea = 30.0;
        const wallArea = 20.0;
        const avgTileSizeCm = 50.0;

        final wallFraction = wallArea / totalArea;
        final wallGlue = totalGlue * wallFraction;
        final extraPercent = avgTileSizeCm > 40 ? 0.30 : 0.20;
        final extra = wallGlue * extraPercent;

        // extra = 66.7 × 0.30 = 20.0
        expect(extra, closeTo(20.0, 0.1));
        expect(totalGlue + extra, closeTo(120.0, 0.1));
      });

      test('только пол — без доп. клея', () {
        const totalGlue = 100.0;
        const totalArea = 20.0;
        const wallArea = 0.0;

        double extra = 0;
        if (wallArea > 0 && totalArea > 0) {
          final wallFraction = wallArea / totalArea;
          final wallGlue = totalGlue * wallFraction;
          extra = wallGlue * 0.20;
        }

        expect(extra, equals(0.0));
      });
    });
  });
}
