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
          'mixType': 0.0, // ЦПС
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
          'mixType': 0.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(20.0));
        expect(result.values['perimeter'], equals(18.0));
      });
    });

    group('ЦПС (цементно-песчаная смесь)', () {
      test('calculates CPS M100 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0, // 50 мм = 5 см
          'mixType': 0.0, // ЦПС
          'cpsMarka': 0.0, // М100
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М100 = 15.0 кг/м²/см
        // Вес = 20 * 5 * 15.0 = 1500 кг
        // Мешки = ceil(1500 / 40) = 38 мешков
        expect(result.values['mixWeightKg'], equals(1500.0));
        expect(result.values['mixBags'], equals(38.0));
        expect(result.values['consumption'], equals(15.0));
      });

      test('calculates CPS M150 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'mixType': 0.0, // ЦПС
          'cpsMarka': 1.0, // М150
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М150 = 17.0 кг/м²/см
        // Вес = 20 * 5 * 17.0 = 1700 кг
        // Мешки = ceil(1700 / 40) = 43 мешка
        expect(result.values['mixWeightKg'], equals(1700.0));
        expect(result.values['mixBags'], equals(43.0));
        expect(result.values['consumption'], equals(17.0));
      });

      test('calculates CPS M200 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'mixType': 0.0, // ЦПС
          'cpsMarka': 2.0, // М200
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М200 = 18.0 кг/м²/см
        // Вес = 20 * 5 * 18.0 = 1800 кг
        // Мешки = ceil(1800 / 40) = 45 мешков
        expect(result.values['mixWeightKg'], equals(1800.0));
        expect(result.values['mixBags'], equals(45.0));
        expect(result.values['consumption'], equals(18.0));
      });
    });

    group('Пескобетон', () {
      test('calculates Peskobeton M200 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0, // 50 мм = 5 см
          'mixType': 1.0, // Пескобетон
          'peskobetonMarka': 0.0, // М200
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М200 = 19.0 кг/м²/см
        // Вес = 20 * 5 * 19.0 = 1900 кг
        // Мешки = ceil(1900 / 40) = 48 мешков
        expect(result.values['mixWeightKg'], equals(1900.0));
        expect(result.values['mixBags'], equals(48.0));
        expect(result.values['consumption'], equals(19.0));
      });

      test('calculates Peskobeton M300 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'mixType': 1.0, // Пескобетон
          'peskobetonMarka': 1.0, // М300
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М300 = 20.0 кг/м²/см
        // Вес = 20 * 5 * 20.0 = 2000 кг
        // Мешки = ceil(2000 / 40) = 50 мешков
        expect(result.values['mixWeightKg'], equals(2000.0));
        expect(result.values['mixBags'], equals(50.0));
        expect(result.values['consumption'], equals(20.0));
      });

      test('calculates Peskobeton M400 bags correctly', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'mixType': 1.0, // Пескобетон
          'peskobetonMarka': 2.0, // М400
          'bagWeight': 40.0,
        };

        final result = calculator(inputs, []);

        // Расход М400 = 22.0 кг/м²/см
        // Вес = 20 * 5 * 22.0 = 2200 кг
        // Мешки = ceil(2200 / 40) = 55 мешков
        expect(result.values['mixWeightKg'], equals(2200.0));
        expect(result.values['mixBags'], equals(55.0));
        expect(result.values['consumption'], equals(22.0));
      });
    });

    group('Вес мешка', () {
      test('respects bag weight 25 kg', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'mixType': 0.0, // ЦПС
          'cpsMarka': 1.0, // М150
          'bagWeight': 25.0,
        };

        final result = calculator(inputs, []);

        // Вес = 10 * 5 * 17.0 = 850 кг
        // Мешки = ceil(850 / 25) = 34 мешка
        expect(result.values['mixWeightKg'], equals(850.0));
        expect(result.values['mixBags'], equals(34.0));
      });

      test('respects bag weight 50 kg', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'mixType': 0.0, // ЦПС
          'cpsMarka': 1.0, // М150
          'bagWeight': 50.0,
        };

        final result = calculator(inputs, []);

        // Вес = 850 кг
        // Мешки = ceil(850 / 50) = 17 мешков
        expect(result.values['mixBags'], equals(17.0));
      });
    });

    group('Дополнительные материалы', () {
      test('calculates mesh area with margin', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0,
          'mixType': 0.0,
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
          'mixType': 0.0,
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
          'mixType': 0.0,
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
          'mixType': 0.0,
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
          'mixType': 0.0,
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
      test('shows warning for thin screed (< 30 mm)', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 25.0, // Менее 30 мм
          'mixType': 0.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['thicknessWarning'], equals(1.0));
      });

      test('no warning for normal thickness', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 50.0, // Более 30 мм
          'mixType': 0.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['thicknessWarning'], equals(0.0));
      });

      test('shows type warning for CPS below 20 mm', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 15.0, // Менее 20 мм для ЦПС
          'mixType': 0.0, // ЦПС
        };

        final result = calculator(inputs, []);

        expect(result.values['typeThicknessWarning'], equals(1.0));
      });

      test('shows type warning for Peskobeton below 30 mm', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 20.0,
          'thickness': 25.0, // Менее 30 мм для Пескобетона
          'mixType': 1.0, // Пескобетон
        };

        final result = calculator(inputs, []);

        expect(result.values['typeThicknessWarning'], equals(1.0));
      });
    });

    group('Рекомендации по маркам', () {
      test('recommends CPS M100 for thickness <= 30 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(0, 30.0), equals('М100'));
        expect(CalculateScreedUnified.getRecommendedMarka(0, 20.0), equals('М100'));
      });

      test('recommends CPS M150 for thickness 31-50 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(0, 40.0), equals('М150'));
        expect(CalculateScreedUnified.getRecommendedMarka(0, 50.0), equals('М150'));
      });

      test('recommends CPS M200 for thickness > 50 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(0, 60.0), equals('М200'));
        expect(CalculateScreedUnified.getRecommendedMarka(0, 100.0), equals('М200'));
      });

      test('recommends Peskobeton M200 for thickness <= 40 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(1, 30.0), equals('М200'));
        expect(CalculateScreedUnified.getRecommendedMarka(1, 40.0), equals('М200'));
      });

      test('recommends Peskobeton M300 for thickness 41-80 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(1, 50.0), equals('М300'));
        expect(CalculateScreedUnified.getRecommendedMarka(1, 80.0), equals('М300'));
      });

      test('recommends Peskobeton M400 for thickness > 80 mm', () {
        expect(CalculateScreedUnified.getRecommendedMarka(1, 90.0), equals('М400'));
        expect(CalculateScreedUnified.getRecommendedMarka(1, 150.0), equals('М400'));
      });
    });

    group('Ценообразование', () {
      test('calculates total price for CPS', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'mixType': 0.0, // ЦПС
          'cpsMarka': 1.0, // М150
          'bagWeight': 40.0,
          'needMesh': 1.0,
          'needFilm': 0.0,
          'needTape': 0.0,
          'needBeacons': 0.0,
        };

        final priceList = [
          const PriceItem(sku: 'cps_m150', name: 'ЦПС М150', price: 180, unit: 'мешок', imageUrl: ''),
          const PriceItem(sku: 'mesh', name: 'Сетка', price: 50, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        // Смесь: 22 мешка × 180 = 3960
        // Сетка: 11 м² × 50 = 550
        // Итого: 4510
        expect(result.totalPrice, equals(4510.0));
      });

      test('calculates total price for Peskobeton', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 10.0,
          'thickness': 50.0,
          'mixType': 1.0, // Пескобетон
          'peskobetonMarka': 1.0, // М300
          'bagWeight': 40.0,
          'needMesh': 0.0,
          'needFilm': 0.0,
          'needTape': 0.0,
          'needBeacons': 0.0,
        };

        final priceList = [
          const PriceItem(sku: 'peskobeton_m300', name: 'Пескобетон М300', price: 200, unit: 'мешок', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        // Смесь: 25 мешков × 200 = 5000
        expect(result.totalPrice, equals(5000.0));
      });
    });

    group('Граничные случаи', () {
      test('handles minimum area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1.0,
          'thickness': 50.0,
          'mixType': 0.0,
          'cpsMarka': 1.0,
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
          'mixType': 0.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(500.0));
        expect(result.values['volume'], equals(25.0));
      });

      test('handles default values correctly', () {
        // Минимальные входные данные с площадью
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, []);

        // Дефолты: площадь 20, толщина 50, ЦПС М150
        expect(result.values['area'], equals(20.0));
        expect(result.values['thickness'], equals(50.0));
        expect(result.values['mixType'], equals(0.0)); // ЦПС
        expect(result.values['consumption'], equals(17.0)); // М150
      });

      test('handles room mode with default values', () {
        final inputs = {
          'inputMode': 1.0, // По комнате
          'roomWidth': 4.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, []);

        expect(result.values['area'], equals(20.0));
        expect(result.values['thickness'], equals(50.0));
      });
    });

    group('Формулы по СП 29.13330.2011', () {
      test('consumption formula: area × thickness(cm) × consumption rate', () {
        // Проверяем формулу: площадь × толщина(см) × расход
        final inputs = {
          'inputMode': 0.0,
          'area': 15.0, // 15 м²
          'thickness': 70.0, // 70 мм = 7 см
          'mixType': 1.0, // Пескобетон
          'peskobetonMarka': 1.0, // М300, расход 20 кг/м²/см
          'bagWeight': 50.0,
        };

        final result = calculator(inputs, []);

        // Ожидаемый вес: 15 × 7 × 20 = 2100 кг
        expect(result.values['mixWeightKg'], equals(2100.0));

        // Мешки: ceil(2100 / 50) = 42
        expect(result.values['mixBags'], equals(42.0));
      });

      test('volume formula: area × thickness(m)', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
          'thickness': 80.0, // 80 мм = 0.08 м
          'mixType': 0.0,
        };

        final result = calculator(inputs, []);

        // Объём: 25 × 0.08 = 2.0 м³
        expect(result.values['volume'], equals(2.0));
      });
    });
  });
}
