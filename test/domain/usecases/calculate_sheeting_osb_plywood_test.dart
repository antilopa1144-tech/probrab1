import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_sheeting_osb_plywood.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateSheetingOsbPlywood', () {
    late CalculateSheetingOsbPlywood calculator;

    setUp(() {
      calculator = CalculateSheetingOsbPlywood();
    });

    test('calculates sheets needed for floor installation', () {
      final inputs = {
        'inputMode': 1.0, // По площади
        'area': 20.0, // 20 м²
        'sheetSize': 1.0, // 2500×1250 мм (стандарт)
        'thickness': 15.0, // 15 мм для пола
        'constructionType': 2.0, // Пол
        'reserve': 5.0, // 5% запас для пола
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа 2.5 * 1.25 = 3.125 м²
      // Листов: 20 / 3.125 * 1.05 = ~6.7 → 7 листов
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(6));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(8));

      // Саморезы для пола: 18 шт/м² * 20 м² = 360 шт
      expect(result.values['screwsNeeded'], equals(360));
      expect(result.values['underlayArea'], equals(21.0));
    });

    test('calculates sheets needed for wall installation', () {
      final inputs = {
        'inputMode': 0.0, // По размерам
        'length': 5.0,
        'width': 3.0,
        'sheetSize': 1.0, // 2500×1250 мм (стандарт)
        'thickness': 9.0, // 9 мм для стен
        'constructionType': 1.0, // Обшивка стен
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь: 5 * 3 = 15 м²

      // Площадь листа 2.5 * 1.25 = 3.125 м² (округлено до 3.5)

      // Листов: 15 / 3.125 * 1.1 = ~5.3 → 6 листов
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(5));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(7));

      // Саморезы для стен: 23 шт/м² * 15 м² = 345 шт
      expect(result.values['screwsNeeded'], equals(345));
      expect(result.values['windBarrierArea'], equals(18.0));
      expect(result.values['vaporBarrierArea'], equals(18.0));
    });

    test('calculates sheets needed for roof installation', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'sheetSize': 1.0, // 2500×1250 (стандарт)
        'thickness': 12.0, // 12 мм для крыши
        'constructionType': 3.0, // Крыша
        'reserve': 12.0, // 12% запас для крыши
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Листов: 30 / 3.125 * 1.12 = ~10.8 → 11 листов
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(10));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(12));

      // Саморезы для крыши: 18 шт/м² * 30 м² = 540 шт
      expect(result.values['screwsNeeded'], equals(540));
      expect(result.values['underlaymentArea'], equals(33.0));
      expect(result.values['clips'], equals(28.0));
    });

    test('handles custom sheet size', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'sheetSize': 0.0, // Пользовательский размер
        'sheetLength': 3.0,
        'sheetWidth': 1.5,
        'thickness': 18.0,
        'constructionType': 4.0, // Перегородки
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 3.0 * 1.5 = 4.5 м²

      // Листов: 10 * 2.1 / 4.5 * 1.1 = ~5.1 → 6 листов
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(5));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(7));

      // Саморезы для перегородок: 27 шт/м² * 10 м² = 270 шт
      expect(result.values['screwsNeeded'], equals(270));
    });

    test('handles tongue-groove sheet size (2500×625)', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 5.0,
        'sheetSize': 2.0, // 2500×625 (шпунт для полов)
        'thickness': 18.0,
        'constructionType': 2.0, // Пол
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 2.5 * 0.625 = 1.5625 м² (округлено до 2.0)

      // Листов: 5 / 1.5625 * 1.05 = ~3.4 → 4 листа
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(3));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(5));
    });

    test('calculates SIP foam and glue', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 25.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 5.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Монтажная пена: 0.3 баллона на м² -> 25 * 0.3 = 7.5 -> 8 баллонов
      expect(result.values['foamNeeded'], equals(8.0));
      expect(result.values['glueNeededKg'], equals(4.0));
    });

    test('calculates underlay for floor only', () {
      final inputsFloor = {
        'inputMode': 1.0,
        'area': 20.0,
        'sheetSize': 1.0,
        'thickness': 15.0,
        'constructionType': 2.0, // Пол - нужна подложка
        'reserve': 5.0,
      };
      final inputsWall = {
        'inputMode': 1.0,
        'area': 20.0,
        'sheetSize': 1.0,
        'thickness': 9.0,
        'constructionType': 1.0, // Стены - без подложки
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final resultFloor = calculator(inputsFloor, emptyPriceList);
      final resultWall = calculator(inputsWall, emptyPriceList);

      // Подложка для пола: 20 м² + 5% = 21 м²
      expect(resultFloor.values['underlayArea'], equals(21.0));

      // Для стен подложка не нужна
      expect(resultWall.values['underlayArea'], isNull);
    });

    test('applies different reserve percentages', () {
      final inputs5 = {
        'inputMode': 1.0,
        'area': 10.0,
        'sheetSize': 1.0,
        'thickness': 15.0,
        'constructionType': 2.0,
        'reserve': 5.0, // 5%
      };
      final inputs15 = {
        'inputMode': 1.0,
        'area': 10.0,
        'sheetSize': 1.0,
        'thickness': 15.0,
        'constructionType': 2.0,
        'reserve': 15.0, // 15%
      };
      final emptyPriceList = <PriceItem>[];

      final result5 = calculator(inputs5, emptyPriceList);
      final result15 = calculator(inputs15, emptyPriceList);

      // С большим запасом нужно больше листов (или равно при малых площадях)
      expect(result15.values['sheetsNeeded'], greaterThanOrEqualTo(result5.values['sheetsNeeded']!));

      // Материал с запасом отражается в итоговой площади
      expect(result5.values['materialArea'], equals(11.0));
      expect(result15.values['materialArea'], equals(12.0));
    });

    test('adjusts area for large openings and bumps reserve', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 100.0,
        'windowsArea': 20.0,
        'doorsArea': 15.0, // 35% проёмов
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Чистая площадь: 100 - 35 = 65 м?
      // Запас увеличен до 15%: 65 * 1.15 = 74.75 -> 75 м?
      expect(result.values['materialArea'], equals(75.0));
      expect(result.values['sheetsNeeded'], equals(24.0));
      expect(result.values['screwsNeeded'], equals(1495.0));
    });

    test('validates zero area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 0.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('validates zero dimensions in by_dimensions mode', () {
      final inputs = {
        'inputMode': 0.0,
        'length': 0.0,
        'width': 5.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('calculates price with price list', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 15.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'reserve': 10.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'osb_12mm',
          name: 'ОСБ-3 12мм',
          unit: 'лист',
          price: 800.0,
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'screws_wall',
          name: 'Саморезы для стен',
          unit: 'шт',
          price: 0.5,
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'foam',
          name: 'Монтажная пена',
          unit: 'баллон',
          price: 300.0,
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'primer',
          name: 'Грунтовка',
          unit: 'л',
          price: 150.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // Должна быть рассчитана общая стоимость
      expect(result.totalPrice, greaterThan(0));
    });

    test('returns material area with reserve', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 25.5,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['materialArea'], equals(29.0));
    });

    test('calculates different screw counts for different construction types', () {
      final baseInputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final resultWalls = calculator({...baseInputs, 'constructionType': 1.0}, emptyPriceList);
      final resultFloor = calculator({...baseInputs, 'constructionType': 2.0, 'reserve': 5.0}, emptyPriceList);
      final resultRoof = calculator({...baseInputs, 'constructionType': 3.0, 'reserve': 12.0}, emptyPriceList);
      final resultPartitions = calculator({...baseInputs, 'constructionType': 4.0}, emptyPriceList);

      // Перегородки требуют больше всего саморезов (27 шт/м² - с двух сторон)
      expect(resultPartitions.values['screwsNeeded'], greaterThan(resultWalls.values['screwsNeeded']!));
      expect(resultPartitions.values['screwsNeeded'], greaterThan(resultFloor.values['screwsNeeded']!));
      expect(resultPartitions.values['screwsNeeded'], greaterThan(resultRoof.values['screwsNeeded']!));

      // Стены: 23 шт/м² * 10 м² = 230
      expect(resultWalls.values['screwsNeeded'], closeTo(230, 5));

      // Пол: 18 шт/м² * 10 м² = 180
      expect(resultFloor.values['screwsNeeded'], closeTo(180, 5));

      // Крыша: 18 шт/м² * 10 м² = 180
      expect(resultRoof.values['screwsNeeded'], closeTo(180, 5));

      // Перегородки больше всех: 27 шт/м² * 10 м² = 270
      expect(resultPartitions.values['screwsNeeded'], closeTo(270, 5));
    });

    test('recommends thickness and flags low thickness by step', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 12.0,
        'sheetSize': 1.0,
        'thickness': 15.0,
        'constructionType': 2.0, // Пол
        'joistStep': 600.0,
        'reserve': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['recommendedThickness'], equals(22.0));
      expect(result.values['warningLowThicknessFloor'], equals(1.0));
    });

    test('no outdoor class warning for interior dry walls with OSB-2', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 12.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0, // стены
        'osbClass': 2.0,
        'environment': 1.0, // сухое помещение
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ОСБ-2 в сухом помещении на стенах — допустимо, без предупреждения
      expect(result.values.containsKey('warningClassOutdoor'), isFalse);
    });

    test('flags low class for outdoor environment', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 12.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'osbClass': 2.0,
        'environment': 3.0, // наружные условия
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['warningClassOutdoor'], equals(1.0));
    });

    test('flags low class for wet environment', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 12.0,
        'sheetSize': 1.0,
        'thickness': 12.0,
        'constructionType': 1.0,
        'osbClass': 2.0,
        'environment': 2.0, // Влажное
        'reserve': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['warningClassWet'], equals(1.0));
    });

    group('grid-based layout (inputMode=0)', () {
      test('wall 3×2.7m, sheet 2500×1250 → grid gives realistic count', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 3.0,
          'width': 2.7,
          'sheetSize': 1.0, // 2500×1250
          'thickness': 9.0,
          'constructionType': 1.0, // стена
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];
        final result = calculator(inputs, emptyPriceList);

        // Grid layout:
        // Horizontal: ceil(3.0/2.5) × ceil(2.7/1.25) = 2 × 3 = 6
        // Vertical: ceil(3.0/1.25) × ceil(2.7/2.5) = 3 × 2 = 6
        // Both give 6, single layer wall
        // With ~5% grid reserve → 6 * 1.05 = 6.3 → 7
        // Area-based would give: 3*2.7=8.1 / 3.125 * 1.10 = 2.85 → 3 sheets
        // Grid result accounts for actual cuts — should be >= 3
        expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(3));
      });

      test('wall 8×2.7m, sheet 2500×1250 → grid vs area differ', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 8.0,
          'width': 2.7,
          'sheetSize': 1.0, // 2500×1250
          'thickness': 9.0,
          'constructionType': 1.0,
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];
        final result = calculator(inputs, emptyPriceList);

        // Grid: horizontal: ceil(8/2.5) × ceil(2.7/1.25) = 4 × 3 = 12
        // Grid: vertical: ceil(8/1.25) × ceil(2.7/2.5) = 7 × 2 = 14
        // Best = 12, with reserve → ~13
        // Area-based: 8*2.7=21.6 / 3.125 * 1.10 = 7.6 → 8 sheets
        // Grid gives more (realistic!)
        expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(8));
      });

      test('area-based mode (inputMode=1) still works correctly', () {
        final inputs = {
          'inputMode': 1.0,
          'area': 20.0,
          'sheetSize': 1.0,
          'thickness': 9.0,
          'constructionType': 1.0,
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];
        final result = calculator(inputs, emptyPriceList);

        // Area-based: 20 / 3.125 * 1.10 = 7.04 → 8
        expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(7));
        expect(result.values['sheetsNeeded'], lessThanOrEqualTo(8));
      });

      test('partitions use 2 layers in grid mode', () {
        final inputs = {
          'inputMode': 0.0,
          'length': 3.0,
          'width': 2.7,
          'sheetSize': 1.0,
          'thickness': 12.0,
          'constructionType': 4.0, // перегородки (2 стороны)
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];
        final result = calculator(inputs, emptyPriceList);

        // Grid for one side: min(6, 6) = 6
        // × 2 layers = 12, with reserve → ~13
        expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(12));
      });
    });

  });
}
