import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateTile - Расширенные тесты логики', () {
    late CalculateTile calculator;

    setUp(() {
      calculator = CalculateTile();
    });

    group('Режим ввода "По размерам" (inputMode=0)', () {
      test('Вычисляет площадь из длины и ширины', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'tileSize': 60.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Площадь = 5 * 4 = 20 м²
        expect(result.values['area'], 20.0);
      });

      test('Комната 3x3 м с плиткой 30x30', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 3.0,
          'width': 3.0,
          'tileSize': 30.0,
          'reserve': 10.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Площадь = 9 м²
        expect(result.values['area'], 9.0);

        // Плитка 30x30 см = 0.09 м²
        // Плиток: ceil(9 / 0.09 * 1.10) = ceil(110) = 110 или 111 (из-за округления float)
        expect(result.values['tilesNeeded'], closeTo(110.0, 1.0));
      });
    });

    group('Режим ввода "По площади" (inputMode=1)', () {
      test('20 м² с плиткой 60x60', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'reserve': 10.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['area'], 20.0);

        // Плитка 60x60 см = 0.36 м²
        // Плиток: ceil(20 / 0.36 * 1.10) = ceil(61.1) = 62
        expect(result.values['tilesNeeded'], 62.0);
      });
    });

    group('Разные размеры плитки', () {
      test('Мозаика 20x20 см', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 20.0,
          'reserve': 10.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Плитка 20x20 см = 0.04 м²
        // Плиток: ceil(10 / 0.04 * 1.10) = ceil(275) = 275
        expect(result.values['tilesNeeded'], 275.0);
      });

      test('Крупноформат 80x80 см (+5% доп. за размер)', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 80.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Плитка 80x80 см = 0.64 м², avgSize=80>60 → +5% за размер
        // layoutPattern=1 (default) = 10% + 5% = 15%
        // ceil(20 / 0.64 * 1.15) = ceil(35.94) = 36
        expect(result.values['tilesNeeded'], 36.0);
      });

      test('Прямоугольная плитка 120x60 см (+5% доп. за размер)', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 120.0, // Означает 120x60
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Плитка 120x60 см = 0.72 м², avgSize=90>60 → +5% за размер
        // layoutPattern=1 (default) = 10% + 5% = 15%
        // ceil(20 / 0.72 * 1.15) = ceil(31.94) = 32
        expect(result.values['tilesNeeded'], 32.0);
      });

      test('Пользовательский размер 45x45 см', () {
        final inputs = {
          'area': 15.0,
          'tileSize': 0.0, // Custom
          'tileWidth': 45.0,
          'tileHeight': 45.0,
          'reserve': 10.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Плитка 45x45 см = 0.2025 м²
        // Плиток: ceil(15 / 0.2025 * 1.10) = ceil(81.5) = 82
        expect(result.values['tilesNeeded'], 82.0);
      });
    });

    group('Затирка', () {
      test('Затирка зависит от ширины шва', () {
        final inputs1 = {
          'area': 10.0,
          'tileSize': 60.0,
          'jointWidth': 3.0, // 3 мм
        };
        final inputs2 = {
          'area': 10.0,
          'tileSize': 60.0,
          'jointWidth': 6.0, // 6 мм
        };

        final result1 = calculator(inputs1, <PriceItem>[]);
        final result2 = calculator(inputs2, <PriceItem>[]);

        // Затирка при 6мм должна быть в 2 раза больше чем при 3мм
        expect(result2.values['groutNeeded']! / result1.values['groutNeeded']!,
            closeTo(2.0, 0.01));
      });

      test('Формула затирки через длину швов: jointsLength × jointWidth × depth × density', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 5.0, // 5 мм
        };

        final result = calculator(inputs, <PriceItem>[]);

        // tileW=0.6м, tileH=0.6м → jointsLength = 1/0.6 + 1/0.6 = 3.333 м/м²
        // avgSize=60 → groutDepth=8мм (40-60 см)
        // grout = 20 × 3.333 × (5/1000) × (8/1000) × 1600 × 1.1 ≈ 4.69 кг
        expect(result.values['groutNeeded'], closeTo(4.69, 0.2));
      });
    });

    group('Клей', () {
      test('Клей для мелкой плитки (< 20 см): 3.5 кг/м²', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 0.0,
          'tileWidth': 15.0,
          'tileHeight': 15.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 10 × 3.5 = 35 кг
        expect(result.values['glueNeeded'], closeTo(35.0, 1.0));
      });

      test('Клей для средней плитки (20-40 см): 4.0 кг/м²', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 30.0, // 30x30
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 10 × 4.0 = 40 кг
        expect(result.values['glueNeeded'], closeTo(40.0, 1.0));
      });

      test('Клей для крупной плитки (> 40 см): 5.5 кг/м²', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 60.0, // 60x60
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 10 × 5.5 = 55 кг
        expect(result.values['glueNeeded'], closeTo(55.0, 1.0));
      });
    });

    group('Крестики', () {
      test('Крестиков ~1.2 на плитку (1 на пересечение + 20% запас)', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 60.0, // 0.36 м²
          'reserve': 10.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        final tiles = result.values['tilesNeeded']!;
        final crosses = result.values['crossesNeeded']!;

        expect(crosses, (tiles * 1.2).ceil().toDouble());
      });
    });

    group('Грунтовка', () {
      test('Грунтовка 0.15 л/м²', () {
        final inputs = {
          'area': 20.0,
          'tileSize': 60.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 20 × 0.15 = 3 л
        expect(result.values['primerNeeded'], closeTo(3.0, 0.1));
      });
    });

    group('Отходы по паттерну укладки', () {
      test('Прямая укладка (10%)', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 60.0, // 0.36 м²
          'layoutPattern': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // totalWaste = 10% (прямая) × 1.0 (простая) + 0 (avgSize=60, не >60)
        // ceil(10 / 0.36 * 1.10) = ceil(30.56) = 31
        expect(result.values['tilesNeeded'], 31.0);
        expect(result.values['wastePercent'], 10.0);
      });

      test('Диагональная укладка (15%)', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 60.0, // 0.36 м²
          'layoutPattern': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // totalWaste = 15% (диагональ) × 1.0 (простая) + 0
        // ceil(10 / 0.36 * 1.15) = ceil(31.94) = 32
        expect(result.values['tilesNeeded'], 32.0);
        expect(result.values['wastePercent'], 15.0);
      });
    });

    group('Валидация', () {
      test('Режим "По размерам" - нулевая длина', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 0.0,
          'width': 4.0,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });

      test('Режим "По площади" - нулевая площадь', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });

      test('Пользовательский размер - слишком большая плитка', () {
        final inputs = {
          'area': 10.0,
          'tileSize': 0.0,
          'tileWidth': 250.0, // > 200
          'tileHeight': 60.0,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
