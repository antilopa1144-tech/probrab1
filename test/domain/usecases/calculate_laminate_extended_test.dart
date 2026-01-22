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
        // Плинтус = 18 * 1.05 = 18.9 м
        expect(result.values['plinthLength'], closeTo(18.9, 0.1));
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

        // Упаковки: ceil(9 / 2 * 1.07) = ceil(4.815) = 5
        expect(result.values['packsNeeded'], 5.0);
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
        // Плинтус = 18 * 1.05 = 18.9 м
        expect(result.values['plinthLength'], closeTo(18.9, 0.1));
      });

      test('20 м² БЕЗ периметра - оценивает как квадрат', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'packArea': 2.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Периметр квадрата 20 м² = 4 * sqrt(20) ≈ 17.89 м
        // С запасом 5% ≈ 18.78 м
        expect(result.values['plinthLength'], closeTo(18.78, 0.5));
      });
    });

    group('Проверка запасов', () {
      test('Запас 5% (минимум)', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 5.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // ceil(100 / 2 * 1.05) = ceil(52.5) = 53 упаковки
        expect(result.values['packsNeeded'], 53.0);
      });

      test('Запас 15% (максимум)', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 15.0,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // ceil(100 / 2 * 1.15) = ceil(57.5) = 58 упаковок
        expect(result.values['packsNeeded'], 58.0);
      });

      test('Запас больше 15% ограничивается', () {
        final inputs = {
          'area': 100.0,
          'packArea': 2.0,
          'reserve': 25.0, // Превышает max
        };

        final result = calculator(inputs, <PriceItem>[]);

        // Должен ограничиться 15%
        // ceil(100 / 2 * 1.15) = ceil(57.5) = 58 упаковок
        expect(result.values['packsNeeded'], 58.0);
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
      });

      test('Большая площадь 500 м²', () {
        final inputs = {
          'area': 500.0,
          'packArea': 2.5,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // ceil(500 / 2.5 * 1.07) = ceil(214) = 214 упаковок
        expect(result.values['packsNeeded'], closeTo(214.0, 5.0));
      });

      test('Маленькая упаковка 0.5 м²', () {
        final inputs = {
          'area': 10.0,
          'packArea': 0.5,
        };

        final result = calculator(inputs, <PriceItem>[]);

        // ceil(10 / 0.5 * 1.07) = ceil(21.4) = 22 упаковки
        expect(result.values['packsNeeded'], 22.0);
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
  });
}
