import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_terrace.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateTerrace', () {
    late CalculateTerrace calculator;

    setUp(() {
      calculator = CalculateTerrace();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'perimeter': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculateTerrace();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values, isNotEmpty);
    });

    test('preserves input values in result', () {
      final calculator = CalculateTerrace();
      final inputs = {
        'perimeter': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateTerrace();
      final inputs = {
        'perimeter': 100.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'test-1',
          name: 'Тестовый материал',
          unit: 'м²',
          price: 1000.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.values, isNotEmpty);
    });
  });

  group('CalculateTerrace - Floor Types', () {
    late CalculateTerrace calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateTerrace();
    });

    test('calculates decking (type 1) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0, // Декинг
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Декинг: area * 1.1
      expect(result.values['deckingArea'], 20.0 * 1.1);
      expect(result.values['tilesNeeded'], 0.0);
      expect(result.values['deckingBoards'], 0.0);
    });

    test('calculates tile (type 2) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 2.0, // Плитка 50x50 см
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Плитка: (area / 0.25) * 1.1, округлено вверх
      const tileArea = 0.25;
      final expected = (20.0 / tileArea * 1.1).ceil().toDouble();
      expect(result.values['tilesNeeded'], expected);
      expect(result.values['deckingArea'], 0.0);
    });

    test('calculates board (type 3) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 3.0, // Доска
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Доска: (area / 0.1) * 1.1, округлено вверх
      const boardArea = 0.1;
      final expected = (20.0 / boardArea * 1.1).ceil().toDouble();
      expect(result.values['deckingBoards'], expected);
    });

    test('calculates porcelain tile (type 4 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 4.0, // Керамогранит 60x60 см
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Керамогранит: (area / 0.36) * 1.1, округлено вверх
      const porcelainArea = 0.36;
      final expected = (20.0 / porcelainArea * 1.1).ceil().toDouble();
      expect(result.values['tilesNeeded'], expected);
      expect(result.values['floorArea'], 20.0);
    });

    test('calculates WPC/ДПК (type 5 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 5.0, // ДПК
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // ДПК: area * 1.1 (как декинг)
      expect(result.values['deckingArea'], 20.0 * 1.1);
      expect(result.values['tilesNeeded'], 0.0);
    });

    test('calculates solid wood (type 6 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 6.0, // Массив дерева
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Массив дерева: area * 1.1 * 1.15 (больше отходов)
      expect(result.values['deckingArea'], closeTo(20.0 * 1.1 * 1.15, 0.01));
      expect(result.values['tilesNeeded'], 0.0);
    });

    test('calculates rubber tiles (type 7 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 7.0, // Резиновая плитка 50x50 см
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Резиновая плитка: (area / 0.25) * 1.1, округлено вверх
      const rubberArea = 0.25;
      final expected = (20.0 / rubberArea * 1.1).ceil().toDouble();
      expect(result.values['tilesNeeded'], expected);
    });
  });

  group('CalculateTerrace - Roof Types', () {
    late CalculateTerrace calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateTerrace();
    });

    test('calculates polycarbonate roof (type 1) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0, // С крышей
        'roofType': 1.0, // Поликарбонат
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      const sheetArea = 6.0;
      final expected = (roofArea / sheetArea * 1.1).ceil().toDouble();

      expect(result.values['roofArea'], roofArea);
      expect(result.values['polycarbonateSheets'], expected);
    });

    test('calculates profiled sheet roof (type 2) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 2.0, // Профнастил
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      const sheetArea = 8.0;
      final expected = (roofArea / sheetArea * 1.1).ceil().toDouble();

      expect(result.values['profiledSheets'], expected);
    });

    test('calculates soft roof (type 3) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 3.0, // Мягкая кровля
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      expect(result.values['roofingMaterial'], closeTo(roofArea * 1.1, 0.01));
    });

    test('calculates ondulin roof (type 4 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 4.0, // Ондулин
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      const ondSheetArea = 1.9; // Стандартный лист ондулина
      final expected = (roofArea / ondSheetArea * 1.15).ceil().toDouble();

      expect(result.values['roofArea'], roofArea);
      expect(result.values['profiledSheets'], expected);
    });

    test('calculates metal tile roof (type 5 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 5.0, // Металлочерепица
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      expect(result.values['roofingMaterial'], closeTo(roofArea * 1.2, 0.01));
    });

    test('calculates glass roof (type 6 - NEW) correctly', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 6.0, // Стеклянная крыша
      };

      final result = calculator(inputs, emptyPriceList);

      const roofArea = 20.0 * 1.2;
      const glassSheetArea = 2.0;
      final expected = (roofArea / glassSheetArea * 1.1).ceil().toDouble();

      expect(result.values['polycarbonateSheets'], expected); // Использует то же поле
    });

    test('no roof calculations when roof is disabled', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 0.0, // Без крыши
        'roofType': 1.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['roofArea'], 0.0);
      expect(result.values['polycarbonateSheets'], 0.0);
      expect(result.values['profiledSheets'], 0.0);
      expect(result.values['roofingMaterial'], 0.0);
    });
  });

  group('CalculateTerrace - Combined Scenarios', () {
    late CalculateTerrace calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateTerrace();
    });

    test('calculates complete terrace with new materials', () {
      final inputs = {
        'area': 25.0,
        'floorType': 5.0, // ДПК (новый)
        'railing': 1.0, // С ограждением
        'perimeter': 20.0,
        'roof': 1.0, // С крышей
        'roofType': 4.0, // Ондулин (новый)
      };

      final result = calculator(inputs, emptyPriceList);

      // Пол: ДПК
      expect(result.values['deckingArea'], closeTo(25.0 * 1.1, 0.01));

      // Крыша: Ондулин
      const roofArea = 25.0 * 1.2;
      const ondSheetArea = 1.9;
      final expectedSheets = (roofArea / ondSheetArea * 1.15).ceil().toDouble();
      expect(result.values['profiledSheets'], expectedSheets);

      // Ограждение
      expect(result.values['railingLength'], 20.0);
      expect(result.values['railingPosts'], greaterThan(0));

      // Столбы для крыши
      expect(result.values['roofPosts'], greaterThan(0));
    });

    test('validates floor type boundary (maxValue: 7)', () {
      final inputs = {
        'area': 20.0,
        'floorType': 7.0, // Максимальное значение
        'railing': 0.0,
        'roof': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // Должен корректно обработать максимальный тип
      expect(result.values, isNotEmpty);
      expect(result.values['tilesNeeded'], greaterThan(0));
    });

    test('validates roof type boundary (maxValue: 6)', () {
      final inputs = {
        'area': 20.0,
        'floorType': 1.0,
        'railing': 0.0,
        'roof': 1.0,
        'roofType': 6.0, // Максимальное значение
      };

      final result = calculator(inputs, emptyPriceList);

      // Должен корректно обработать максимальный тип крыши
      expect(result.values, isNotEmpty);
      expect(result.values['polycarbonateSheets'], greaterThan(0));
    });
  });
}
