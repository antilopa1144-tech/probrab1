import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gkl_wall.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateGklWall', () {
    late CalculateGklWall calculator;

    setUp(() {
      calculator = CalculateGklWall();
    });

    test('calculates materials correctly in dimensions mode', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь: 5 × 2.7 = 13.5 м²
      // roundBulk(13.5) = ceil(13.5) = 14.0 (в диапазоне 10-100)
      expect(result.values['area'], closeTo(14.0, 0.7));

      // Периметр: (5 + 2.7) × 2 = 15.4 м
      // Направляющий профиль: 15.4 × 2 = 30.8 м
      // roundBulk(30.8) = ceil(30.8) = 31.0
      expect(result.values['guideProfileMeters'], closeTo(31.0, 1.6));
      // Штук по 3м: ⌈30.8 / 3⌉ = 11 шт
      expect(result.values['guideProfilePieces'], closeTo(11.0, 0.6));

      // Количество стоек: ⌈5.0 / 0.6⌉ + 1 = ⌈8.33⌉ + 1 = 9 + 1 = 10 стоек
      expect(result.values['racksCount'], equals(10.0));
      // Стоечный профиль: 10 × 2.7 = 27.0 м
      expect(result.values['rackProfileMeters'], closeTo(27.0, 1.4));

      // Листы ГКЛ: ⌈13.5 / 3.0⌉ = 5 шт
      expect(result.values['gklSheets'], equals(5.0));
    });

    test('calculates materials correctly in area mode', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь: 20 м²
      expect(result.values['area'], closeTo(20.0, 1.0));

      // Листы ГКЛ: ⌈20 / 3.0⌉ = 7 шт
      expect(result.values['gklSheets'], equals(7.0));

      // Профили должны быть рассчитаны (с оценкой периметра)
      expect(result.values['guideProfileMeters'], greaterThan(0));
      expect(result.values['rackProfileMeters'], greaterThan(0));
    });

    test('handles 40cm profile step correctly', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 40.0, // 40 см шаг
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // С шагом 40см потребуется больше стоек: ⌈5.0 / 0.4⌉ + 1 = 14 стоек
      expect(result.values['racksCount'], closeTo(14.0, 0.7));
      // Стоечный профиль: 14 × 2.7 = 37.8 м
      // roundBulk(37.8) = ceil(37.8) = 38.0
      expect(result.values['rackProfileMeters'], closeTo(38.0, 1.9));
    });

    test('handles double-sided installation correctly', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 1.0, // Двухсторонняя обшивка
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // При двухсторонней обшивке листов в 2 раза больше
      // Площадь одной стороны: 13.5 м²
      // Двухсторонняя: 13.5 × 2 = 27 м²
      // Листы: ⌈27 / 3.0⌉ = 9 шт
      expect(result.values['gklSheets'], equals(9.0));
    });

    test('handles two layers correctly', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 2.0, // Два слоя ГКЛ
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // При двух слоях листов в 2 раза больше
      // Площадь: 13.5 м²
      // С двумя слоями: 13.5 × 2 = 27 м²
      // Листы: ⌈27 / 3.0⌉ = 9 шт
      expect(result.values['gklSheets'], equals(9.0));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
        'windowsArea': 2.0,
        'doorsArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полная площадь: 13.5 м²
      // roundBulk(13.5) = ceil(13.5) = 14.0
      expect(result.values['area'], closeTo(14.0, 0.7));

      // Полезная площадь: 13.5 - 2 - 2 = 9.5 м²
      // roundBulk(9.5) = ceil(9.5 * 2) / 2 = 19 / 2 = 9.5 (в диапазоне 1-10)
      expect(result.values['usefulArea'], equals(9.5));

      // Листы рассчитываются по полезной площади: ⌈9.5 / 3.0⌉ = 4 шт
      expect(result.values['gklSheets'], equals(4.0));
    });

    test('calculates screws correctly', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы Металл-Металл: guideProfilePieces × 35
      // 11 штук профиля × 35 = 385 шт
      expect(result.values['screwsMetalToMetal'], closeTo(385.0, 19.2));

      // Саморезы ГКЛ-Металл: gklSheets × 27
      // 5 листов × 27 = 135 шт
      expect(result.values['screwsGklToMetal'], closeTo(135.0, 6.8));
    });

    test('calculates additional materials correctly', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь ГКЛ: 13.5 м²
      // Лента-серпянка: 13.5 × 1.2 = 16.2 м
      // roundBulk(16.2) = ceil(16.2) = 17.0
      expect(result.values['seamTapeMeters'], closeTo(17.0, 0.9));

      // Шпаклёвка для швов: 13.5 × 0.3 = 4.05 кг
      // roundBulk(4.05) = ceil(4.05 * 2) / 2 = 4.5 (в диапазоне 1-10)
      expect(result.values['jointCompoundKg'], equals(4.5));

      // Грунтовка: 13.5 × 0.1 = 1.35 л
      // roundBulk(1.35) = ceil(1.35 * 2) / 2 = 1.5
      expect(result.values['primerLiters'], equals(1.5));
    });

    test('throws exception for zero area in area mode', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 0.0,
        'profileStep': 60.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('clamps too small wall length to minimum', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 0.3, // Меньше минимума (0.5 м)
        'wallHeight': 2.7,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // getInput с minValue = 0.5 должен вернуть 0.5
      // Площадь: 0.5 × 2.7 = 1.35 м²
      expect(result.values['area'], greaterThan(0));
    });

    test('clamps invalid wall height to minimum', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 1.5, // Меньше минимума (2.0 м)
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // getInput с minValue = 2.0 должен вернуть 2.0
      // Площадь: 5 × 2.0 = 10 м²
      expect(result.values['area'], equals(10.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
        'profileStep': 60.0,
        'layers': 1.0,
        'doubleSided': 0.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'profile_pn',
          name: 'Профиль направляющий PN 27/28',
          price: 150,
          unit: 'м',
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'profile_ps',
          name: 'Профиль стоечный PS 50/50',
          price: 180,
          unit: 'м',
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'gkl',
          name: 'ГКЛ лист 2500×1200×12.5',
          price: 400,
          unit: 'шт',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // Должна быть рассчитана итоговая стоимость
      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));

      // Примерный расчёт:
      // Направляющий: 30.8 м × 150 = 4620 руб
      // Стоечный: 24.3 м × 180 = 4374 руб
      // Листы: 5 шт × 400 = 2000 руб
      // Итого: ~10994 руб (без доп. материалов)
      expect(result.totalPrice, greaterThanOrEqualTo(10000));
    });

    test('handles complex scenario with all options', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 6.0,
        'wallHeight': 3.0,
        'profileStep': 40.0,
        'layers': 2.0,
        'doubleSided': 1.0,
        'windowsArea': 3.0,
        'doorsArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полная площадь: 6 × 3 = 18 м²
      expect(result.values['area'], closeTo(18.0, 0.9));

      // Полезная площадь: 18 - 3 - 2 = 13 м²
      expect(result.values['usefulArea'], closeTo(13.0, 0.7));

      // Площадь ГКЛ: 13 × 2 (слоя) × 2 (стороны) = 52 м²
      // Листы: ⌈52 / 3.0⌉ = 18 шт
      expect(result.values['gklSheets'], closeTo(18.0, 0.9));

      // Все материалы должны быть рассчитаны
      expect(result.values['guideProfileMeters'], greaterThan(0));
      expect(result.values['rackProfileMeters'], greaterThan(0));
      expect(result.values['screwsMetalToMetal'], greaterThan(0));
      expect(result.values['screwsGklToMetal'], greaterThan(0));
      expect(result.values['seamTapeMeters'], greaterThan(0));
      expect(result.values['jointCompoundKg'], greaterThan(0));
      expect(result.values['primerLiters'], greaterThan(0));
    });

    test('returns correct norms', () {
      final inputs = {
        'inputMode': 0.0,
        'wallLength': 5.0,
        'wallHeight': 2.7,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.norms, contains('СНиП 3.03.01-87'));
      expect(result.norms, contains('ГОСТ 6266-97'));
    });
  });
}
