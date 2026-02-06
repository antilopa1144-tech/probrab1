import 'package:flutter_test/flutter_test.dart';

import 'package:probrab_ai/domain/usecases/calculate_tile_grout.dart';

void main() {
  late CalculateTileGrout useCase;

  setUp(() {
    useCase = CalculateTileGrout();
  });

  group('CalculateTileGrout', () {
    group('Базовый расчёт (по площади)', () {
      test('20 м², плитка 60×60, шов 3×2 мм, цементная → расход > 0', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        final consumption = result.values['consumptionPerM2'] ?? 0;
        final groutNeeded = result.values['groutNeeded'] ?? 0;

        // Для 60×60 шов 3×2 мм: ~0.032 кг/м²
        // 20 м² × 0.032 × 1.1 ≈ 0.7 кг
        expect(consumption, greaterThan(0));
        expect(consumption, lessThan(1.0)); // < 1 кг/м² для крупной плитки
        expect(groutNeeded, greaterThan(0));
        expect(groutNeeded, lessThan(5.0)); // < 5 кг для 20 м² крупной плитки
      });

      test('мешки рассчитаны: минимум 1', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 5.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['bagsNeeded'], greaterThanOrEqualTo(1));
      });

      test('сопутствующие: шпатель и губки рассчитаны', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 25.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        // 25 м² → шпатели: ceil(25/10) = 3
        expect(result.values['spatulaCount'], equals(3.0));
        // губки: ceil(25/5) = 5
        expect(result.values['spongePackCount'], equals(5.0));
      });
    });

    group('Режим ввода по размерам', () {
      test('inputMode=0: area = length × width', () {
        final result = useCase.calculate({
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['area'], closeTo(20.0, 0.01));
      });

      test('по размерам и по площади дают одинаковый результат', () {
        final resultDims = useCase.calculate({
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'tileSize': 30.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);
        final resultArea = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 30.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(resultDims.values['groutNeeded'],
            closeTo(resultArea.values['groutNeeded']!, 0.01));
      });
    });

    group('Размеры плитки', () {
      test('мозаика 20×20: расход выше чем 60×60', () {
        final result20 = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 20.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);
        final result60 = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result20.values['consumptionPerM2'],
            greaterThan(result60.values['consumptionPerM2']!));
      });

      test('пользовательский размер tileSize=0: берётся tileWidth/tileHeight', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 10.0,
          'tileSize': 0.0,
          'tileWidth': 40.0,
          'tileHeight': 80.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['tileWidth'], equals(40.0));
        expect(result.values['tileHeight'], equals(80.0));
      });

      test('прямоугольная плитка tileSize=120 → 120×60', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 10.0,
          'tileSize': 120.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['tileWidth'], equals(120.0));
        expect(result.values['tileHeight'], equals(60.0));
      });
    });

    group('Тип затирки', () {
      test('эпоксидная (тип 1): расход меньше цементной (плотность ниже)', () {
        final resultCement = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);
        final resultEpoxy = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 1.0,
        }, []);

        expect(resultCement.values['groutNeeded'],
            greaterThan(resultEpoxy.values['groutNeeded']!));
      });

      test('эпоксидная: вес мешка 2.5 кг', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 1.0,
        }, []);

        expect(result.values['bagWeight'], equals(2.5));
      });

      test('цементная: вес мешка 2.0 кг', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['bagWeight'], equals(2.0));
      });

      test('полиуретановая (тип 2): расход меньше эпоксидной', () {
        final resultEpoxy = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 1.0,
        }, []);
        final resultPU = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 2.0,
        }, []);

        expect(resultEpoxy.values['groutNeeded'],
            greaterThan(resultPU.values['groutNeeded']!));
      });

      test('полиуретановая: вес упаковки 2.0 кг', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 2.0,
        }, []);

        expect(result.values['bagWeight'], equals(2.0));
      });

      test('порядок расхода: цементная > эпоксидная > полиуретановая', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 50.0,
          'tileSize': 30.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
        };

        final cement = useCase.calculate({...inputs, 'groutType': 0.0}, []);
        final epoxy = useCase.calculate({...inputs, 'groutType': 1.0}, []);
        final pu = useCase.calculate({...inputs, 'groutType': 2.0}, []);

        expect(cement.values['groutNeeded'],
            greaterThan(epoxy.values['groutNeeded']!));
        expect(epoxy.values['groutNeeded'],
            greaterThan(pu.values['groutNeeded']!));
      });
    });

    group('Влияние параметров шва', () {
      test('широкий шов 10 мм: расход выше узкого 2 мм', () {
        final resultNarrow = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 2.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);
        final resultWide = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 10.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(resultWide.values['consumptionPerM2'],
            greaterThan(resultNarrow.values['consumptionPerM2']!));
      });

      test('глубокий шов 4 мм: расход выше мелкого 1 мм', () {
        final resultShallow = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 1.0,
          'groutType': 0.0,
        }, []);
        final resultDeep = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 4.0,
          'groutType': 0.0,
        }, []);

        expect(resultDeep.values['consumptionPerM2'],
            greaterThan(resultShallow.values['consumptionPerM2']!));
      });

      test('расход линейно пропорционален площади', () {
        final result10 = useCase.calculate({
          'inputMode': 1.0,
          'area': 10.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);
        final result20 = useCase.calculate({
          'inputMode': 1.0,
          'area': 20.0,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result20.values['groutNeeded'],
            closeTo(result10.values['groutNeeded']! * 2, 0.01));
      });
    });

    group('Граничные условия', () {
      test('минимальная площадь 0.1 м² — без ошибок, bags ≥ 1', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 0.1,
          'tileSize': 60.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        // При 0.1 м² расход очень мал (~0.004 кг) и округляется до 0.00
        // Но мешков всегда минимум 1
        expect(result.values['groutNeeded'], greaterThanOrEqualTo(0));
        expect(result.values['bagsNeeded'], greaterThanOrEqualTo(1));
      });

      test('большая площадь 500 м² — результат корректен', () {
        final result = useCase.calculate({
          'inputMode': 1.0,
          'area': 500.0,
          'tileSize': 30.0,
          'jointWidth': 3.0,
          'jointDepth': 2.0,
          'groutType': 0.0,
        }, []);

        expect(result.values['groutNeeded'], greaterThan(0));
        expect(result.values['bagsNeeded'], greaterThanOrEqualTo(1));
      });

      test('validateInputs: inputMode=1, area=0 → ошибка', () {
        final error = useCase.validateInputs({
          'inputMode': 1.0,
          'area': 0.0,
        });
        expect(error, isNotNull);
      });

      test('validateInputs: inputMode=0, length=0 → ошибка', () {
        final error = useCase.validateInputs({
          'inputMode': 0.0,
          'length': 0.0,
          'width': 5.0,
        });
        expect(error, isNotNull);
      });

      test('validateInputs: корректные данные → null', () {
        final error = useCase.validateInputs({
          'inputMode': 1.0,
          'area': 10.0,
        });
        expect(error, isNull);
      });
    });
  });
}
