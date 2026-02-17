import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateLaminate - Расширенные тесты логики', () {
    late CalculateLaminate calculator;

    setUp(() {
      calculator = CalculateLaminate();
    });

    group('Режим ввода "По размерам" (inputMode=0)', () {
      test('Вычисляет площадь и периметр из длины/ширины', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Площадь = 5 * 4 = 20 м²
        expect(result.values['area'], 20.0);

        // Периметр = (5 + 4) * 2 = 18 м
        // Плинтус: raw = 18 - (1 * 0.9) = 17.1 м
        // Pieces = ceil(17.1 / 2.5) = 7
        // plinthLength = 7 * 2.5 = 17.5 м
        expect(result.values['plinthLength'], 17.5);
        expect(result.values['plinthPieces'], 7.0);
      });

      test('Комната 3x3 м', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 3.0,
          'width': 3.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Площадь = 9 м²
        expect(result.values['area'], 9.0);

        // layoutPattern=2 (default) → baseWaste=10%
        // area=9 < 15 → areaAdjustment = (15-9)*0.5 = 3%
        // patternWaste = 10 + 3 = 13%
        // reserve default = 10%, totalWaste = max(13, 10) = 13%
        // packsNeeded = ceil(9 / 2 * 1.13) = ceil(5.085) = 6
        expect(result.values['packsNeeded'], 6.0);
        expect(result.values['wastePercent'], 13.0);
      });
    });

    group('Режим ввода "По площади" (inputMode=1)', () {
      test('20 м² с указанным периметром', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['area'], 20.0);
        // Плинтус: raw = 18 - (1 * 0.9) = 17.1 м
        // Pieces = ceil(17.1 / 2.5) = 7
        // plinthLength = 7 * 2.5 = 17.5 м
        expect(result.values['plinthLength'], 17.5);
      });

      test('20 м² БЕЗ периметра - оценивает как квадрат', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Периметр квадрата 20 м² = 4 * sqrt(20) ≈ 17.89 м
        // plinthLengthRaw = 17.89 - (1 * 0.9) = 16.99
        // plinthPieces = ceil(16.99 / 2.5) = 7
        // plinthLength = 7 * 2.5 = 17.5
        expect(result.values['plinthLength'], 17.5);
      });
    });

    group('Проверка запасов (reserve vs layoutPattern)', () {
      test('Запас reserve=5% при layoutPattern=2 (10%) — используется pattern (10%)', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 5.0,
          'layoutPattern': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 10% (хаотичная), areaAdj = 0 (100 > 15)
        // totalWaste = max(10, 5) = 10%
        // ceil(100 / 2 * 1.10) = ceil(55.0000...01) = 56
        // (IEEE 754: 100 * 1.1 = 110.00000000000001, /2 = 55.00000000000001)
        expect(result.values['packsNeeded'], 56.0);
        expect(result.values['wastePercent'], 10.0);
      });

      test('Запас reserve=15% при layoutPattern=2 (10%) — используется reserve (15%)', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 15.0,
          'layoutPattern': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 10%, areaAdj = 0, reserve = 15%
        // totalWaste = max(10, 15) = 15%
        // ceil(100 / 2 * 1.15) = ceil(57.5) = 58
        expect(result.values['packsNeeded'], 58.0);
        expect(result.values['wastePercent'], 15.0);
      });

      test('Запас reserve=20% (clamped max) — используется reserve', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 25.0, // Превышает max → clamped to 20%
        };

        final result = calculator(inputs, <PriceItem>[]);

        // reserve clamped to 20%, patternWaste = 10% (default pattern=2)
        // totalWaste = max(10, 20) = 20%
        // ceil(100 / 2 * 1.20) = ceil(60) = 60
        expect(result.values['packsNeeded'], 60.0);
        expect(result.values['wastePercent'], 20.0);
      });

      test('Дефолтные значения обратно совместимы (20 м², pattern=2)', () {
        // Ключевой тест обратной совместимости:
        // Без явного layoutPattern, default=2 (10%), reserve default=10%
        // totalWaste = max(10, 10) = 10% — как в старой версии
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // ceil(20 / 2 * 1.10) = ceil(11) = 11
        expect(result.values['packsNeeded'], 11.0);
        expect(result.values['wastePercent'], 10.0);
      });
    });

    group('Способы укладки (layoutPattern)', () {
      test('Со смещением 1/4 (pattern=1) — 7% отходов', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 1.0,
          'reserve': 5.0, // ниже patternWaste, не влияет
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 7%, areaAdj = 0 (20 >= 15)
        // totalWaste = max(7, 5) = 7%
        // ceil(20 / 2 * 1.07) = ceil(10.7) = 11
        expect(result.values['packsNeeded'], 11.0);
        expect(result.values['wastePercent'], 7.0);
      });

      test('Хаотичная (pattern=2) — 10% отходов', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 10%
        // totalWaste = max(10, 5) = 10%
        // ceil(20 / 2 * 1.10) = ceil(11) = 11
        expect(result.values['packsNeeded'], 11.0);
        expect(result.values['wastePercent'], 10.0);
      });

      test('Палубная (pattern=3) — 12% отходов', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 3.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 12%
        // totalWaste = max(12, 5) = 12%
        // ceil(20 / 2 * 1.12) = ceil(11.2) = 12
        expect(result.values['packsNeeded'], 12.0);
        expect(result.values['wastePercent'], 12.0);
      });

      test('Диагональная (pattern=4) — 15% отходов', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 4.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // patternWaste = 15%
        // totalWaste = max(15, 5) = 15%
        // ceil(20 / 2 * 1.15) = ceil(11.5) = 12
        expect(result.values['packsNeeded'], 12.0);
        expect(result.values['wastePercent'], 15.0);
      });

      test('Неизвестный pattern → fallback 10%', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 99.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['wastePercent'], 10.0);
      });
    });

    group('Масштабирование запаса по площади (area scaling)', () {
      test('Комната 5 м² → доп. +5% к отходам', () {
        final inputs = {
          'area': 5.0,
          'packArea': 2.0,
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // baseWaste=10%, areaAdj = (15-5)*0.5 = 5%
        // patternWaste = 15%, totalWaste = max(15, 5) = 15%
        expect(result.values['wastePercent'], 15.0);
        // ceil(5 / 2 * 1.15) = ceil(2.875) = 3
        expect(result.values['packsNeeded'], 3.0);
      });

      test('Комната 10 м² → доп. +2.5% к отходам', () {
        final inputs = {
          'area': 10.0,
          'packArea': 2.0,
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // baseWaste=10%, areaAdj = (15-10)*0.5 = 2.5%
        // patternWaste = 12.5%, totalWaste = max(12.5, 5) = 12.5%
        expect(result.values['wastePercent'], 12.5);
        // ceil(10 / 2 * 1.125) = ceil(5.625) = 6
        expect(result.values['packsNeeded'], 6.0);
      });

      test('Комната 15 м² — порог, без доп. запаса', () {
        final inputs = {
          'area': 15.0,
          'packArea': 2.0,
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // baseWaste=10%, areaAdj = 0 (area >= 15)
        // totalWaste = max(10, 5) = 10%
        expect(result.values['wastePercent'], 10.0);
      });

      test('Комната 20 м² — нет доп. запаса', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['wastePercent'], 10.0);
      });

      test('Маленькая комната с диагональной укладкой → максимум отходов', () {
        final inputs = {
          'area': 5.0,
          'packArea': 2.0,
          'layoutPattern': 4.0, // диагональная — 15%
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // baseWaste=15%, areaAdj = (15-5)*0.5 = 5%
        // patternWaste = 20%, totalWaste = max(20, 5) = 20%
        expect(result.values['wastePercent'], 20.0);
        // ceil(5 / 2 * 1.20) = ceil(3.0) = 3
        expect(result.values['packsNeeded'], 3.0);
      });
    });

    group('Плинтус: отрезки, углы и соединители', () {
      test('Комната 5x4 (периметр=18) — стандартный расчёт', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'packArea': 2.0,
          'doorThresholds': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // plinthRaw = 18 - (1 * 0.9) = 17.1
        // plinthPieces = ceil(17.1 / 2.5) = 7
        // plinthLength = 7 * 2.5 = 17.5
        expect(result.values['plinthPieces'], 7.0);
        expect(result.values['plinthLength'], 17.5);
        // innerCorners = 4 (прямоугольная комната)
        expect(result.values['innerCorners'], 4.0);
        // plinthConnectors = max(0, 7 - 4) = 3
        expect(result.values['plinthConnectors'], 3.0);
      });

      test('Маленькая комната 2x2 (периметр=8) — мало отрезков', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 2.0,
          'width': 2.0,
          'packArea': 2.0,
          'doorThresholds': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // plinthRaw = 8 - 0.9 = 7.1
        // plinthPieces = ceil(7.1 / 2.5) = 3
        // plinthLength = 3 * 2.5 = 7.5
        expect(result.values['plinthPieces'], 3.0);
        expect(result.values['plinthLength'], 7.5);
        expect(result.values['innerCorners'], 4.0);
        // plinthConnectors = max(0, 3 - 4) = 0
        expect(result.values['plinthConnectors'], 0.0);
      });

      test('Без дверных проёмов — плинтус по всему периметру', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'packArea': 2.0,
          'doorThresholds': 0.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // plinthRaw = 18 - 0 = 18
        // plinthPieces = ceil(18 / 2.5) = 8
        // plinthLength = 8 * 2.5 = 20.0
        expect(result.values['plinthPieces'], 8.0);
        expect(result.values['plinthLength'], 20.0);
        // plinthConnectors = max(0, 8 - 4) = 4
        expect(result.values['plinthConnectors'], 4.0);
      });

      test('3 дверных проёма — больше вычитается', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'packArea': 2.0,
          'doorThresholds': 3.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // plinthRaw = 18 - (3 * 0.9) = 18 - 2.7 = 15.3
        // plinthPieces = ceil(15.3 / 2.5) = 7
        // plinthLength = 7 * 2.5 = 17.5
        expect(result.values['plinthPieces'], 7.0);
        expect(result.values['plinthLength'], 17.5);
        expect(result.values['doorThresholds'], 3.0);
      });
    });

    group('Клинья компенсационные', () {
      test('Клинья рассчитываются по периметру', () {
        final inputs = {
          'area': 20.0,
          'perimeter': 18.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Клинья = ceil(18 / 0.5) = 36 шт
        expect(result.values['wedgesNeeded'], 36.0);
      });

      test('Клинья для большой комнаты', () {
        final inputs = {
          'area': 100.0,
          'perimeter': 40.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Клинья = ceil(40 / 0.5) = 80 шт
        expect(result.values['wedgesNeeded'], 80.0);
      });
    });

    group('Пароизоляция', () {
      test('Пароизоляция = площадь + 10%', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 20 * 1.10 = 22 м²
        expect(result.values['vaporBarrierArea'], closeTo(22.0, 0.1));
      });
    });

    group('Подложка', () {
      test('Подложка = площадь + 5%', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // 20 * 1.05 = 21 м²
        expect(result.values['underlayArea'], closeTo(21.0, 0.1));
      });
    });

    group('Пороги', () {
      test('Пороги по умолчанию = 1', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['doorThresholds'], 1.0);
      });

      test('Можно задать несколько порогов', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'doorThresholds': 3.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['doorThresholds'], 3.0);
      });
    });

    group('Граничные случаи', () {
      test('Минимальная площадь 0.1 м²', () {
        final inputs = {
          'area': 0.1,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Должна работать без ошибок
        expect(result.values['packsNeeded'], greaterThan(0));
        // Для очень маленькой площади отходы высокие
        // areaAdj = (15 - 0.1)*0.5 = 7.45%, patternWaste = 10 + 7.45 = 17.45%
        expect(result.values['wastePercent'], greaterThan(10.0));
      });

      test('Большая площадь 500 м²', () {
        final inputs = {
          'area': 500.0,
          'packArea': 2.5,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // area >= 15, areaAdj = 0, patternWaste = 10%, reserve = 10%
        // totalWaste = 10%
        // ceil(500 / 2.5 * 1.10) = ceil(220) = 220
        expect(result.values['packsNeeded'], 220.0);
      });

      test('Маленькая упаковка 0.5 м²', () {
        final inputs = {
          'area': 10.0,
          'packArea': 0.5,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // area=10 < 15, areaAdj = (15-10)*0.5 = 2.5%
        // patternWaste = 10 + 2.5 = 12.5%, reserve = 10%
        // totalWaste = max(12.5, 10) = 12.5%
        // ceil(10 / 0.5 * 1.125) = ceil(22.5) = 23
        expect(result.values['packsNeeded'], 23.0);
      });
    });

    group('Класс и толщина ламината (информационные)', () {
      test('Класс ламината сохраняется в результате', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'laminateClass': 33.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['laminateClass'], 33.0);
      });

      test('Толщина ламината сохраняется в результате', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
          'laminateThickness': 12.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values['laminateThickness'], 12.0);
      });
    });

    group('Новые выходные значения', () {
      test('wastePercent присутствует в результате', () {
        final inputs = {
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values.containsKey('wastePercent'), isTrue);
        expect(result.values['wastePercent'], 10.0);
      });

      test('plinthPieces, innerCorners, plinthConnectors присутствуют', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 6.0,
          'width': 4.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        expect(result.values.containsKey('plinthPieces'), isTrue);
        expect(result.values.containsKey('innerCorners'), isTrue);
        expect(result.values.containsKey('plinthConnectors'), isTrue);

        // Периметр = (6+4)*2 = 20
        // plinthRaw = 20 - 0.9 = 19.1
        // plinthPieces = ceil(19.1 / 2.5) = 8
        expect(result.values['plinthPieces'], 8.0);
        expect(result.values['innerCorners'], 4.0);
        // plinthConnectors = max(0, 8 - 4) = 4
        expect(result.values['plinthConnectors'], 4.0);
      });
    });

    group('Практические сценарии', () {
      test('Комната 3x4 м, хаотичная укладка — практический расчёт', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 4.0,
          'width': 3.0,
          'packArea': 2.397, // популярный размер упаковки
          'layoutPattern': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // area = 12 м², perimeter = 14 м
        expect(result.values['area'], 12.0);

        // baseWaste=10%, areaAdj = (15-12)*0.5 = 1.5%
        // patternWaste = 11.5%, totalWaste = max(11.5, 5) = 11.5%
        expect(result.values['wastePercent'], 11.5);

        // ceil(12 / 2.397 * 1.115) = ceil(5.583) = 6 упаковок
        expect(result.values['packsNeeded'], 6.0);

        // plinthRaw = 14 - 0.9 = 13.1
        // plinthPieces = ceil(13.1 / 2.5) = 6
        expect(result.values['plinthPieces'], 6.0);
        expect(result.values['plinthLength'], 15.0);
        expect(result.values['innerCorners'], 4.0);
        expect(result.values['plinthConnectors'], 2.0);
      });

      test('Большая комната 6x8 м, палубная укладка', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 8.0,
          'width': 6.0,
          'packArea': 2.0,
          'layoutPattern': 3.0, // палубная — 12%
          'reserve': 5.0,
          'doorThresholds': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // area = 48 м², perimeter = 28 м
        expect(result.values['area'], 48.0);

        // baseWaste=12%, areaAdj = 0 (48 > 15), totalWaste = max(12, 5) = 12%
        expect(result.values['wastePercent'], 12.0);

        // ceil(48 / 2 * 1.12) = ceil(26.88) = 27 упаковок
        expect(result.values['packsNeeded'], 27.0);

        // plinthRaw = 28 - (2*0.9) = 26.2
        // plinthPieces = ceil(26.2 / 2.5) = 11
        expect(result.values['plinthPieces'], 11.0);
        expect(result.values['plinthLength'], 27.5);
        expect(result.values['innerCorners'], 4.0);
        // plinthConnectors = max(0, 11 - 4) = 7
        expect(result.values['plinthConnectors'], 7.0);
      });

      test('Маленький санузел 1.5x1.2 м, со смещением 1/4', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 1.5,
          'width': 1.2,
          'packArea': 2.0,
          'layoutPattern': 1.0, // со смещением 1/4 — 7%
          'reserve': 5.0,
          'doorThresholds': 1.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // area = 1.8 м², perimeter = 5.4 м
        expect(result.values['area'], 1.8);

        // baseWaste=7%, areaAdj = (15-1.8)*0.5 = 6.6%
        // patternWaste = 13.6%, totalWaste = max(13.6, 5) = 13.6%
        expect(result.values['wastePercent'], 13.6);

        // ceil(1.8 / 2 * 1.136) = ceil(1.0224) = 2 упаковки
        expect(result.values['packsNeeded'], 2.0);
      });
    });
  });
}
