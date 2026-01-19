import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed_unified.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateScreedUnified', () {
    late CalculateScreedUnified calculator;

    setUp(() {
      calculator = CalculateScreedUnified();
    });

    group('Базовые расчёты', () {
      test('calculates volume correctly', () {
        final inputs = {
          'inputMode': 0.0, // По площади
          'area': 20.0, // 20 м²
          'thickness': 50.0, // 50 мм
          'screedType': 0.0, // ЦПС
          'materialType': 1.0, // Самозамес
        };

        final result = calculator(inputs, []);

        // Объём = 20 * 0.05 = 1.0 м³
        expect(result.values['volume'], equals(1.0));
        expect(result.values['area'], equals(20.0));
        expect(result.values['thickness'], equals(50.0));
      });

      test('calculates area from room dimensions', () {
        final inputs = {
          'inputMode': 1.0, // По комнате
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(20.0));
        expect(result.values['perimeter'], equals(18.0));
      });
    });

    group('Готовая смесь (ЦПС)', () {
      test('calculates ready mix M300 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0, // 50 мм = 5 см
          'screedType': 0.0,
          'materialType': 0.0, // Готовая смесь
          'mixGrade': 0.0, // М300
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М300 = 2.0 кг/м²/мм
        // Вес = 20 * 50 * 2.0 = 2000 кг
        // Мешки = ceil(2000 / 40) = 50 мешков
        expect(result.values['mixWeightKg'], equals(2000.0));
        expect(result.values['mixBags'], equals(50.0));
      });

      test('calculates ready mix M150 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 0.0,
          'mixGrade': 1.0, // М150
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М150 = 1.8 кг/м²/мм
        // Вес = 20 * 50 * 1.8 = 1800 кг
        // Мешки = ceil(1800 / 40) = 45 мешков
        expect(result.values['mixWeightKg'], equals(1800.0));
        expect(result.values['mixBags'], equals(45.0));
      });

      test('respects bag weight parameter', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 0.0,
          'mixGrade': 0.0,
          'bagWeight': 50.0, // 50 кг вместо 40
        };

        final result = calculator(inputs, []);

        // Вес = 2000 кг
        // Мешки = ceil(2000 / 50) = 40 мешков
        expect(result.values['mixBags'], equals(40.0));
      });
    });

    group('Самозамес (цемент + песок)', () {
      test('calculates cement and sand for ЦПС correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0, // ЦПС
          'materialType': 1.0, // Самозамес
        };

        final result = calculator(inputs, []);

        // Объём = 1 м³
        // Цемент = 1 * 400 = 400 кг → ceil(400/50) = 8 мешков
        // Песок = 1 * 1200 = 1200 кг → 1200/1500 = 0.8 м³
        expect(result.values['cementKg'], equals(400.0));
        expect(result.values['cementBags'], equals(8.0));
        expect(result.values['sandKg'], equals(1200.0));
        expect(result.values['sandCbm'], equals(0.8));
      });

      test('calculates materials for polysuhaya screed correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 1.0, // Полусухая
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        // Объём = 1 м³
        // Цемент = 1 * 350 = 350 кг
        // Песок = 1 * 1050 = 1050 кг
        expect(result.values['cementKg'], equals(350.0));
        expect(result.values['sandKg'], equals(1050.0));
      });

      test('calculates materials for concrete screed with gravel', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 2.0, // Бетонная
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        // Объём = 1 м³
        // Цемент = 1 * 300 = 300 кг
        // Песок = 1 * 900 = 900 кг
        // Щебень = 1 * 900 = 900 кг
        expect(result.values['cementKg'], equals(300.0));
        expect(result.values['sandKg'], equals(900.0));
        expect(result.values['gravelKg'], equals(900.0));
        expect(result.values['gravelCbm'], closeTo(0.64, 0.01));
      });
    });

    group('Дополнительные материалы', () {
      test('calculates mesh area with margin', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needMesh': 1.0,
        };

        final result = calculator(inputs, []);

        // Сетка = 20 * 1.1 = 22 м²
        expect(result.values['meshArea'], equals(22.0));
      });

      test('calculates film area with margin', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needFilm': 1.0,
        };

        final result = calculator(inputs, []);

        // Плёнка = 20 * 1.15 = 23 м²
        expect(result.values['filmArea'], equals(23.0));
      });

      test('calculates tape length from perimeter', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needTape': 1.0,
        };

        final result = calculator(inputs, []);

        // Периметр = (4 + 5) * 2 = 18 м
        expect(result.values['tapeMeters'], equals(18.0));
      });

      test('calculates beacons count', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needBeacons': 1.0,
        };

        final result = calculator(inputs, []);

        // Маяки = ceil(20 / 1.5) = 14 шт
        expect(result.values['beaconsNeeded'], equals(14.0));
      });

      test('excludes materials when options are off', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
          'needTape': 0.0,
          'needBeacons': 0.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['meshArea'], equals(0.0));
        expect(result.values['filmArea'], equals(0.0));
        expect(result.values['tapeMeters'], equals(0.0));
        expect(result.values['beaconsNeeded'], equals(0.0));
      });
    });

    group('Предупреждения', () {
      test('shows warning for thin screed', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 25.0, // Менее 30 мм
          'screedType': 0.0,
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['thicknessWarning'], equals(1.0));
      });

      test('no warning for normal thickness', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0, // Более 30 мм
          'screedType': 0.0,
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['thicknessWarning'], equals(0.0));
      });
    });

    group('Ценообразование', () {
      test('calculates total price for ready mix', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 0.0,
          'mixGrade': 0.0,
          'bagWeight': 40.0,
          'needMesh': 1.0,
          'needFilm': 0.0,
          'needTape': 0.0,
          'needBeacons': 0.0,
        };

        final priceList = [
          const PriceItem(sku: 'dsp_m300', name: 'Пескобетон М300', price: 200, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'mesh', name: 'Сетка', price: 50, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        // Смесь: 25 мешков × 200 = 5000
        // Сетка: 11 м² × 50 = 550
        // Итого: 5550
        expect(result.totalPrice, equals(5550.0));
      });

      test('calculates total price for self mix', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
          'needTape': 0.0,
          'needBeacons': 0.0,
        };

        final priceList = [
          const PriceItem(sku: 'cement', name: 'Цемент', price: 350, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 500, unit: 'м³', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        // Объём = 0.5 м³
        // Цемент: 4 мешка × 350 = 1400
        // Песок: 0.4 м³ × 500 = 200
        // Итого: 1600
        expect(result.totalPrice, equals(1600.0));
      });
    });

    group('Граничные случаи', () {
      test('handles minimum area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 0.0,
          'mixGrade': 0.0,
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(1.0));
        expect(result.values['mixBags'], greaterThan(0));
      });

      test('handles maximum area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 500.0,
          'thickness': 50.0,
          'screedType': 0.0,
          'materialType': 1.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(500.0));
        expect(result.values['volume'], equals(25.0));
      });

      test('handles default values correctly with room mode', () {
        // В режиме комнаты площадь вычисляется из размеров
        final inputs = {
          'inputMode': 1.0, // По комнате
          'roomWidth': 4.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, []);

        // 4x5 = 20 м²
        expect(result.values['area'], equals(20.0));
        // Толщина по умолчанию 50 мм
        expect(result.values['thickness'], equals(50.0));
      });
    });
  });
}
