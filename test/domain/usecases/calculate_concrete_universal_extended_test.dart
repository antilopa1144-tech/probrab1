import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_concrete_universal.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateConcreteUniversal - Расширенные тесты', () {
    late CalculateConcreteUniversal calculator;

    setUp(() {
      calculator = CalculateConcreteUniversal();
    });

    group('Готовый бетон (manualMix = 0)', () {
      test('1 м³ с запасом 5%', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 5.0,
          'manualMix': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 1.0 * 1.05 = 1.05, roundBulk для 1-10 → ceil(1.05*2)/2 = 1.5
        expect(result.values['concreteVolume'], closeTo(1.5, 0.01));
        expect(result.values['reserve'], 5.0);
        // По умолчанию марка М200 (grade=3)
        expect(result.values['concreteGrade'], 3.0);
        // При manualMix = 0 не должно быть материалов для замеса
        expect(result.values.containsKey('cementBags'), false);
        expect(result.values.containsKey('sandVolume'), false);
        expect(result.values.containsKey('gravelVolume'), false);
        expect(result.values.containsKey('waterNeeded'), false);
      });

      test('10 м³ с запасом 0%', () {
        final inputs = {
          'concreteVolume': 10.0,
          'reserve': 0.0,
          'manualMix': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteVolume'], 10.0);
        expect(result.values['concreteGrade'], 3.0);
      });

      test('100 м³ с запасом 10%', () {
        final inputs = {
          'concreteVolume': 100.0,
          'reserve': 10.0,
          'manualMix': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 100 * 1.10 = 110, roundBulk для >100 → ceil(110/5)*5 = 115
        // (из-за floating-point: 100*1.1 ≈ 110.0000…01, ceil(22.000…002) = 23)
        expect(result.values['concreteVolume'], 115.0);
        expect(result.values['concreteGrade'], 3.0);
      });
    });

    group('Ручной замес М200 (manualMix = 1, grade = 3)', () {
      test('1 м³ с запасом 5% - проверка всех компонентов', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 5.0,
          'manualMix': 1.0,
          'concreteGrade': 3.0, // М200
        };

        final result = calculator(inputs, <PriceItem>[]);

        final volume = result.values['concreteVolume']!;
        final cementBags = result.values['cementBags']!;
        final sandVolume = result.values['sandVolume']!;
        final gravelVolume = result.values['gravelVolume']!;
        final waterNeeded = result.values['waterNeeded']!;

        // 1.0 * 1.05 = 1.05, roundBulk → 1.5
        expect(volume, closeTo(1.5, 0.01));

        // Цемент М200: ceil(1.05 * 290 / 50) = ceil(6.09) = 7 мешков
        expect(cementBags, 7.0);

        // Песок: 1.05 * 0.50 = 0.525, roundBulk для <1 → ceil(0.525*10)/10 = 0.6
        expect(sandVolume, closeTo(0.6, 0.01));

        // Щебень: 1.05 * 0.82 = 0.861, roundBulk для <1 → ceil(0.861*10)/10 = 0.9
        expect(gravelVolume, closeTo(0.9, 0.01));

        // Вода: 1.05 * 190 = 199.5, roundBulk для >100 → ceil(199.5/5)*5 = 200
        expect(waterNeeded, closeTo(200.0, 1.0));
      });

      test('10 м³ с запасом 5% - проверка пропорций', () {
        final inputs = {
          'concreteVolume': 10.0,
          'reserve': 5.0,
          'manualMix': 1.0,
          'concreteGrade': 3.0, // М200
        };

        final result = calculator(inputs, <PriceItem>[]);

        final volume = result.values['concreteVolume']!;
        final cementBags = result.values['cementBags']!;
        final sandVolume = result.values['sandVolume']!;
        final gravelVolume = result.values['gravelVolume']!;
        final waterNeeded = result.values['waterNeeded']!;

        // 10 * 1.05 = 10.5, roundBulk для 10-100 → ceil(10.5) = 11
        expect(volume, closeTo(11.0, 0.1));

        // ceil(10.5 * 290/50) = ceil(10.5 * 5.8) = ceil(60.9) = 61 мешков
        expect(cementBags, 61.0);

        // 10.5 * 0.50 = 5.25 м³, roundBulk для 1-10 → ceil(5.25*2)/2 = 5.5
        expect(sandVolume, closeTo(5.5, 0.1));

        // 10.5 * 0.82 = 8.61 м³, roundBulk для 1-10 → ceil(8.61*2)/2 = 9.0
        expect(gravelVolume, closeTo(9.0, 0.1));

        // 10.5 * 190 = 1995 л, roundBulk для >100 → ceil(1995/5)*5 = 1995
        expect(waterNeeded, closeTo(1995.0, 5.0));
      });

      test('Минимальный объём 0.01 м³', () {
        final inputs = {
          'concreteVolume': 0.01,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 3.0, // М200
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteVolume'], greaterThan(0));
        // ceil(0.01 * 290/50) = ceil(0.058) = 1 мешок
        expect(result.values['cementBags'], 1.0);
      });
    });

    group('Выбор марки бетона', () {
      test('М100 (grade=1): минимум цемента', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 1.0, // М100
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 1.0);
        // М100: 170 кг/м³ → ceil(1.0 * 170/50) = ceil(3.4) = 4 мешка
        expect(result.values['cementBags'], 4.0);
        // Песок: 1.0 * 0.56 = 0.56, roundBulk → ceil(5.6)/10 = 0.6
        expect(result.values['sandVolume'], closeTo(0.6, 0.01));
        // Щебень: 1.0 * 0.88 = 0.88, roundBulk → ceil(8.8)/10 = 0.9
        expect(result.values['gravelVolume'], closeTo(0.9, 0.01));
        // Вода: 1.0 * 210 = 210, roundBulk → ceil(210/5)*5 = 210
        expect(result.values['waterNeeded'], closeTo(210.0, 1.0));
      });

      test('М150 (grade=2): лёгкие конструкции', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 2.0, // М150
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 2.0);
        // М150: 215 кг/м³ → ceil(1.0 * 215/50) = ceil(4.3) = 5 мешков
        expect(result.values['cementBags'], 5.0);
      });

      test('М200 (grade=3): по умолчанию, стяжка/отмостка', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 3.0, // М200
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 3.0);
        // М200: 290 кг/м³ → ceil(1.0 * 290/50) = ceil(5.8) = 6 мешков
        expect(result.values['cementBags'], 6.0);
        // Песок: 0.50 → roundBulk(0.50) = ceil(5.0)/10 = 0.5
        expect(result.values['sandVolume'], closeTo(0.5, 0.01));
        // Щебень: 0.82 → roundBulk(0.82) = ceil(8.2)/10 = 0.9
        expect(result.values['gravelVolume'], closeTo(0.9, 0.01));
        // Вода: 190 → roundBulk(190) = ceil(190/5)*5 = 190
        expect(result.values['waterNeeded'], closeTo(190.0, 1.0));
      });

      test('М250 (grade=4): фундаменты', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 4.0, // М250
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 4.0);
        // М250: 340 кг/м³ → ceil(1.0 * 340/50) = ceil(6.8) = 7 мешков
        expect(result.values['cementBags'], 7.0);
      });

      test('М300 (grade=5): несущие конструкции', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 5.0, // М300
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 5.0);
        // М300: 380 кг/м³ → ceil(1.0 * 380/50) = ceil(7.6) = 8 мешков
        expect(result.values['cementBags'], 8.0);
        // Песок: 0.44 → roundBulk(0.44) = ceil(4.4)/10 = 0.5
        expect(result.values['sandVolume'], closeTo(0.5, 0.01));
        // Щебень: 0.78 → roundBulk(0.78) = ceil(7.8)/10 = 0.8
        expect(result.values['gravelVolume'], closeTo(0.8, 0.01));
        // Вода: 180 → roundBulk(180) = ceil(180/5)*5 = 180
        expect(result.values['waterNeeded'], closeTo(180.0, 1.0));
      });

      test('М350 (grade=6): ответственные конструкции', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 6.0, // М350
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 6.0);
        // М350: 420 кг/м³ → ceil(1.0 * 420/50) = ceil(8.4) = 9 мешков
        expect(result.values['cementBags'], 9.0);
      });

      test('М400 (grade=7): максимум цемента', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 7.0, // М400
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 7.0);
        // М400: 480 кг/м³ → ceil(1.0 * 480/50) = ceil(9.6) = 10 мешков
        expect(result.values['cementBags'], 10.0);
        // Песок: 0.38 → roundBulk(0.38) = ceil(3.8)/10 = 0.4
        expect(result.values['sandVolume'], closeTo(0.4, 0.01));
        // Щебень: 0.73 → roundBulk(0.73) = ceil(7.3)/10 = 0.8
        expect(result.values['gravelVolume'], closeTo(0.8, 0.01));
        // Вода: 170 → roundBulk(170) = ceil(170/5)*5 = 170
        expect(result.values['waterNeeded'], closeTo(170.0, 1.0));
      });
    });

    group('М100 vs М400: разница в расходе цемента', () {
      test('На 1 м³ М400 требуется в ~2.8 раза больше цемента, чем М100', () {
        final m100inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 1.0, // М100
        };
        final m400inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 7.0, // М400
        };

        final m100result = calculator(m100inputs, <PriceItem>[]);
        // Сбрасываем кэш, чтобы следующий вызов пересчитался
        calculator.invalidateCache();
        final m400result = calculator(m400inputs, <PriceItem>[]);

        final m100bags = m100result.values['cementBags']!;
        final m400bags = m400result.values['cementBags']!;

        // М100: 4 мешка, М400: 10 мешков
        expect(m400bags, greaterThan(m100bags));
        expect(m400bags / m100bags, greaterThanOrEqualTo(2.0));
      });

      test('М400 использует меньше песка и щебня, чем М100', () {
        final m100inputs = {
          'concreteVolume': 10.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 1.0, // М100
        };
        final m400inputs = {
          'concreteVolume': 10.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 7.0, // М400
        };

        final m100result = calculator(m100inputs, <PriceItem>[]);
        calculator.invalidateCache();
        final m400result = calculator(m400inputs, <PriceItem>[]);

        // Больше цемента = меньше песка и щебня
        expect(
          m400result.values['sandVolume']!,
          lessThan(m100result.values['sandVolume']!),
        );
        expect(
          m400result.values['gravelVolume']!,
          lessThan(m100result.values['gravelVolume']!),
        );
      });
    });

    group('Марка по умолчанию', () {
      test('Без указания concreteGrade используется М200 (grade=3)', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          // concreteGrade НЕ указан
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['concreteGrade'], 3.0);
        // М200: ceil(1.0 * 290/50) = ceil(5.8) = 6 мешков
        expect(result.values['cementBags'], 6.0);
      });
    });

    group('Практический расчёт: фундамент М300', () {
      test('5 м³ для ленточного фундамента М300 с запасом 5%', () {
        final inputs = {
          'concreteVolume': 5.0,
          'reserve': 5.0,
          'manualMix': 1.0,
          'concreteGrade': 5.0, // М300
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Объём: 5.0 * 1.05 = 5.25, roundBulk → ceil(5.25*2)/2 = 5.5
        expect(result.values['concreteVolume'], closeTo(5.5, 0.1));
        expect(result.values['concreteGrade'], 5.0);

        // Цемент М300: ceil(5.25 * 380/50) = ceil(5.25 * 7.6) = ceil(39.9) = 40 мешков
        expect(result.values['cementBags'], 40.0);

        // Песок: 5.25 * 0.44 = 2.31, roundBulk → ceil(2.31*2)/2 = 2.5
        expect(result.values['sandVolume'], closeTo(2.5, 0.1));

        // Щебень: 5.25 * 0.78 = 4.095, roundBulk → ceil(4.095*2)/2 = 4.5
        expect(result.values['gravelVolume'], closeTo(4.5, 0.1));

        // Вода: 5.25 * 180 = 945, roundBulk → ceil(945/5)*5 = 945
        expect(result.values['waterNeeded'], closeTo(945.0, 5.0));
      });
    });

    group('Граничные случаи', () {
      test('Запас ограничен максимумом 30%', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 50.0, // Превышает max
          'manualMix': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Запас должен быть ограничен 30%
        expect(result.values['reserve'], 30.0);
        // 1.0 * 1.30 = 1.3, roundBulk → ceil(1.3*2)/2 = 1.5
        expect(result.values['concreteVolume'], closeTo(1.5, 0.01));
      });

      test('Отрицательный запас вызывает ошибку валидации', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': -10.0, // Отрицательный - валидация в BaseCalculator
          'manualMix': 0.0,
        };

        // BaseCalculator.validateInputs отклоняет отрицательные значения
        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });

      test('Некорректная марка → fallback на М200', () {
        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 99.0, // Некорректная, будет clamped до 7
        };

        final result = calculator(inputs, <PriceItem>[]);

        // getIntInput с maxValue=7 ограничит до 7 (М400)
        expect(result.values['concreteGrade'], 7.0);
      });
    });

    group('Проверка формул для бетона М200', () {
      test('Соответствие СНиП для 1 м³ бетона М200', () {
        // По СНиП для бетона М200 (цемент М400):
        // Цемент: 290 кг → 5.8 мешков по 50 кг
        // Песок: 0.50 м³ (при плотности 1500 кг/м³ ≈ 750 кг)
        // Щебень: 0.82 м³ (при плотности 1400 кг/м³ ≈ 1148 кг)
        // Вода: 190 л

        final inputs = {
          'concreteVolume': 1.0,
          'reserve': 0.0,
          'manualMix': 1.0,
          'concreteGrade': 3.0, // М200
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Цемент: ceil(1.0 * 290/50) = ceil(5.8) = 6 мешков × 50 кг = 300 кг (в пределах ГОСТ для М200: 270-310 кг)
        expect(result.values['cementBags'], 6.0);

        // Песок: 0.5 м³ (в пределах ГОСТ)
        expect(result.values['sandVolume'], closeTo(0.5, 0.1));

        // Щебень: 0.82 м³ → roundBulk → 0.9
        expect(result.values['gravelVolume'], closeTo(0.9, 0.1));

        // Вода: 190 л (в пределах ГОСТ: 170-200 л)
        expect(result.values['waterNeeded'], closeTo(190.0, 10.0));
      });
    });

    group('Валидация', () {
      test('Объём 0 вызывает ошибку', () {
        final inputs = {
          'concreteVolume': 0.0,
          'manualMix': 0.0,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });

      test('Отрицательный объём вызывает ошибку', () {
        final inputs = {
          'concreteVolume': -5.0,
          'manualMix': 0.0,
        };

        expect(
          () => calculator(inputs, <PriceItem>[]),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('concreteGrade всегда в результате', () {
      test('concreteGrade присутствует при готовом бетоне', () {
        final inputs = {
          'concreteVolume': 1.0,
          'manualMix': 0.0,
          'concreteGrade': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values.containsKey('concreteGrade'), true);
        expect(result.values['concreteGrade'], 5.0);
      });

      test('concreteGrade присутствует при ручном замесе', () {
        final inputs = {
          'concreteVolume': 1.0,
          'manualMix': 1.0,
          'concreteGrade': 2.0,
          'reserve': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values.containsKey('concreteGrade'), true);
        expect(result.values['concreteGrade'], 2.0);
      });
    });
  });
}
