import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallpaper - Расширенные тесты логики', () {
    late CalculateWallpaper calculator;

    setUp(() {
      calculator = CalculateWallpaper();
    });

    group('Режим ввода "По размерам" (inputMode=0)', () {
      test('Комната 4x5 м, высота 2.5 м', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'wallHeight': 2.5,
          'rollSize': 1.0, // 0.53×10
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Периметр = (5 + 4) * 2 = 18 м
        // Площадь стен = 18 * 2.5 = 45 м²
        expect(result.values['usefulArea'], 45.0);

        // Полос = ceil(18 / 0.53) = 34
        expect(result.values['stripsNeeded'], 34.0);
      });

      test('Комната 3x3 м, высота 2.7 м', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 3.0,
          'width': 3.0,
          'wallHeight': 2.7,
          'rollSize': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Периметр = 12 м
        // Площадь = 12 * 2.7 = 32.4 м²
        expect(result.values['usefulArea'], closeTo(32.4, 0.1));
      });

      test('Валидация - нулевая длина вызывает ошибку', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 0.0,
          'width': 4.0,
          'wallHeight': 2.5,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });

      test('Валидация - нулевая ширина вызывает ошибку', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 0.0,
          'wallHeight': 2.5,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Режим ввода "По площади" (inputMode=1)', () {
      test('45 м² площади стен', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 45.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['usefulArea'], 45.0);
      });
    });

    group('Размеры рулонов', () {
      test('Стандартный рулон 0.53×10 м', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 30.0,
          'wallHeight': 2.5,
          'rollSize': 1.0, // 0.53×10
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Один рулон покрывает 0.53 * 10 = 5.3 м²
        // Полос из рулона при высоте 2.5 = floor(10 / 2.5) = 4
        // Ширина покрытия = 4 * 0.53 = 2.12 м
        expect(result.values['rollsNeeded'], greaterThan(0));
      });

      test('Широкий рулон 1.06×10 м', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 30.0,
          'wallHeight': 2.5,
          'rollSize': 2.0, // 1.06×10
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Широкий рулон экономичнее - меньше швов
        expect(result.values['rollsNeeded'], greaterThan(0));
      });

      test('Метровый рулон 1.06×25 м', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'wallHeight': 2.5,
          'rollSize': 3.0, // 1.06×25
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Длинный рулон - больше полос
        // Полос из рулона = floor(25 / 2.5) = 10
        expect(result.values['rollsNeeded'], greaterThan(0));
      });

      test('Пользовательский размер рулона', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 30.0,
          'wallHeight': 2.5,
          'rollSize': 0.0, // Custom
          'rollWidth': 0.7,
          'rollLength': 15.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['rollsNeeded'], greaterThan(0));
      });
    });

    group('Раппорт (подгонка рисунка)', () {
      test('Без раппорта - минимальный расход', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'rapport': 0.0, // Без раппорта
        };

        final result = calculator(inputs, <PriceItem>[]);
        final rollsWithoutRapport = result.values['rollsNeeded']!;

        // Длина полосы = высота стены
        expect(result.values['stripLength'], 2.5);

        // Сравним с раппортом
        final inputsWithRapport = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'rapport': 50.0, // 50 см раппорт
        };

        final resultWithRapport = calculator(inputsWithRapport, <PriceItem>[]);
        final rollsWithRapport = resultWithRapport.values['rollsNeeded']!;

        // С раппортом нужно больше обоев
        expect(rollsWithRapport, greaterThanOrEqualTo(rollsWithoutRapport));
      });

      test('Раппорт 64 см (стандартный для многих обоев)', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'rapport': 64.0, // 64 см
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Длина полосы должна быть кратна раппорту + запас
        // ceil(2.5 / 0.64) + 1 = 4 + 1 = 5 раппортов
        // 5 * 0.64 = 3.2 м
        expect(result.values['stripLength'], closeTo(3.2, 0.1));
      });
    });

    group('Проёмы (окна и двери)', () {
      test('Вычитание площади окон', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'windowsArea': 5.0, // 5 м² окон
          'doorsArea': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Полезная площадь = 50 - 5 = 45 м²
        expect(result.values['usefulArea'], 45.0);
      });

      test('Вычитание площади дверей', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'windowsArea': 0.0,
          'doorsArea': 4.0, // 4 м² дверей (2 двери по 2 м²)
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Полезная площадь = 50 - 4 = 46 м²
        expect(result.values['usefulArea'], 46.0);
      });

      test('Вычитание окон и дверей вместе', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 60.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'windowsArea': 6.0,
          'doorsArea': 4.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Полезная площадь = 60 - 6 - 4 = 50 м²
        expect(result.values['usefulArea'], 50.0);
      });

      test('Ошибка если проёмы больше площади', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'windowsArea': 15.0,
          'doorsArea': 10.0, // Вместе 25 м² > 20 м²
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Должен вернуть error
        expect(result.values.containsKey('error'), true);
      });
    });

    group('Клей и грунтовка', () {
      test('Клей (бумажные по умолч.): 5 г/м² + 10% запас', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          // wallpaperType не задан → default = 1 (бумажные, 0.005 кг/м²)
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 40 × 0.005 × 1.1 = 0.22 кг
        expect(result.values['glueNeeded'], closeTo(0.22, 0.01));
        // pasteNeeded = glueNeeded (backward compat)
        expect(result.values['pasteNeeded'], result.values['glueNeeded']);
      });

      test('Грунтовка: 0.15 л/м² + 10% запас', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 40 × 0.15 × 1.1 = 6.6 л
        expect(result.values['primerNeeded'], closeTo(6.6, 0.1));
      });
    });

    group('Запас', () {
      test('Запас 0% - минимум', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'reserve': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);
        expect(result.values['rollsNeeded'], greaterThan(0));
      });

      test('Запас 15% - максимум', () {
        final inputs0 = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'reserve': 0.0,
        };
        final inputs15 = {
          'inputMode': 1.0,
          'area': 40.0,
          'wallHeight': 2.5,
          'rollSize': 1.0,
          'reserve': 15.0,
        };

        final result0 = calculator(inputs0, <PriceItem>[]);
        final result15 = calculator(inputs15, <PriceItem>[]);

        // С запасом 15% должно быть больше рулонов
        expect(result15.values['rollsNeeded'],
            greaterThanOrEqualTo(result0.values['rollsNeeded']!));
      });
    });
  });
}
